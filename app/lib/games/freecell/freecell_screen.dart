import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku_app/games/cards/card_widgets.dart';
import 'package:sudoku_app/games/cards/game_clock.dart';
import 'package:sudoku_app/games/cards/win_flow.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/ui/leaderboard_screen.dart';
import 'package:sudoku_app/ui/send_to_friends.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/freecell/freecell_game.dart';
import 'package:sudoku_app/services/storage.dart';

const String kFreeCellSaveKey = 'freecell.save';

/// FreeCell: resumes the saved game if there is one, otherwise deals a new one.
class FreeCellScreen extends StatefulWidget {
  /// Skips persistence (used by widget tests).
  final bool persist;

  /// Start a specific deal (e.g. a friend's challenge). Replaces any saved game.
  final int? initialDeal;

  /// Test hook: start from an arbitrary position.
  final FreeCellGame? initialGame;
  const FreeCellScreen({
    super.key,
    this.persist = true,
    this.initialDeal,
    this.initialGame,
  });

  @override
  State<FreeCellScreen> createState() => _FreeCellScreenState();
}

class _Sel {
  final Pile pile;
  final int index;
  final int count;
  const _Sel(this.pile, this.index, this.count);
}

class _FreeCellScreenState extends State<FreeCellScreen> {
  late FreeCellGame _game;
  late final GameClock _clock;
  _Sel? _sel;

  GameRef get _ref => GameRef.freecell(_game.deal);

  @override
  void initState() {
    super.initState();
    var secs = 0;
    final saved = _loadSaved();
    if (widget.initialGame != null) {
      _game = widget.initialGame!;
    } else if (saved != null) {
      _game = saved.$1;
      secs = saved.$2;
    } else {
      _game = FreeCellGame.deal(widget.initialDeal ?? _randomDeal());
    }
    _clock = GameClock(seconds: secs, onTick: () {
      if (mounted) setState(() {});
    });
    if (!_game.won) _clock.start();
  }

  @override
  void dispose() {
    _save();
    _clock.dispose();
    super.dispose();
  }

  static int _randomDeal() => Random().nextInt(1000000) + 1;

  (FreeCellGame, int)? _loadSaved() {
    if (!widget.persist || widget.initialDeal != null) return null;
    try {
      final raw = Storage.getString(kFreeCellSaveKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (FreeCellGame.fromJson(m), (m['secs'] ?? 0) as int);
    } catch (_) {
      return null;
    }
  }

  void _save() {
    if (!widget.persist) return;
    if (_game.won) {
      Storage.remove(kFreeCellSaveKey);
    } else {
      Storage.setString(kFreeCellSaveKey,
          jsonEncode({..._game.toJson(), 'secs': _clock.seconds}));
    }
  }

  void _afterMove() {
    _sel = null;
    _save();
    setState(() {});
    if (_game.won) {
      _clock.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWin());
    }
  }

  void _newDeal(int deal) {
    setState(() {
      _game = FreeCellGame.deal(deal);
      _sel = null;
      _clock
        ..reset()
        ..start();
    });
    _save();
  }

  Future<void> _showWin() async {
    if (!mounted) return;
    final again = await showCardWinDialog(context,
        ref: _ref, seconds: _clock.seconds, moves: _game.moves);
    if (again && mounted) _newDeal(_randomDeal());
  }

  Future<void> _chooseDeal() async {
    final controller = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Play deal number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1 – 1,000,000'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(controller.text)),
              child: const Text('Play')),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= 1000000) _newDeal(n);
  }

  // ---- tap handling -------------------------------------------------------

  void _tryMove(Pile to, int toIndex) {
    final s = _sel!;
    if (_game.play(s.pile, s.index, s.count, to, toIndex)) {
      _afterMove();
    }
  }

  /// Tap: with nothing picked up, send the card (or stack) where it belongs —
  /// foundation, a matching column, a free cell. Otherwise it's a destination
  /// for the picked-up cards, or (if that fails) becomes the new pick-up.
  void _tapColumnCard(int c, int i) {
    final s = _sel;
    final count = _game.columns[c].length - i;
    if (s != null) {
      if (s.pile == Pile.column && s.index == c && s.count == count) {
        setState(() => _sel = null);
        return;
      }
      final before = _game.moves;
      _tryMove(Pile.column, c);
      if (_game.moves != before) return;
    } else if (_game.isSequence(c, i)) {
      final d = _game.bestDestination(Pile.column, c, count);
      if (d != null && _game.play(Pile.column, c, count, d.pile, d.index)) {
        _afterMove();
        return;
      }
    }
    _pickUpColumn(c, i);
  }

  /// Long-press: pick the card (or stack) up without auto-sending it, so you
  /// can choose the destination yourself (e.g. an empty column).
  void _pickUpColumn(int c, int i) {
    setState(() {
      _sel = _game.isSequence(c, i)
          ? _Sel(Pile.column, c, _game.columns[c].length - i)
          : null;
    });
  }

  void _tapEmptyColumn(int c) {
    if (_sel != null) _tryMove(Pile.column, c);
  }

  void _tapCell(int k) {
    final s = _sel;
    final card = _game.cells[k];
    if (s != null && s.pile == Pile.cell && s.index == k) {
      setState(() => _sel = null);
    } else if (s != null && card == null) {
      _tryMove(Pile.cell, k);
    } else if (card != null) {
      if (s == null) {
        final d = _game.bestDestination(Pile.cell, k, 1);
        if (d != null && _game.play(Pile.cell, k, 1, d.pile, d.index)) {
          _afterMove();
          return;
        }
      }
      _pickUpCell(k);
    }
  }

  void _pickUpCell(int k) {
    if (_game.cells[k] != null) setState(() => _sel = _Sel(Pile.cell, k, 1));
  }

  void _tapFoundation() {
    if (_sel != null) _tryMove(Pile.foundation, 0);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FreeCell #${_game.deal}'),
        actions: [
          IconButton(
            key: const Key('fc-undo'),
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _game.canUndo
                ? () {
                    _game.undo();
                    _afterMove();
                  }
                : null,
          ),
          IconButton(
            key: const Key('fc-auto'),
            tooltip: 'Send safe cards to foundations',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () {
              if (_game.autoFoundation() > 0) _afterMove();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'new':
                  _newDeal(_randomDeal());
                case 'choose':
                  _chooseDeal();
                case 'restart':
                  _newDeal(_game.deal);
                case 'board':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(gameId: _ref.id)));
                case 'send':
                  sendGameToFriends(context,
                      gameId: _ref.id, label: _ref.label);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New random deal')),
              PopupMenuItem(value: 'choose', child: Text('Play deal number…')),
              PopupMenuItem(value: 'restart', child: Text('Restart this deal')),
              PopupMenuItem(value: 'board', child: Text('Leaderboard')),
              PopupMenuItem(value: 'send', child: Text('Challenge a friend')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          const gap = 4.0;
          const pad = 8.0;
          final cw = min(86.0, (box.maxWidth - 2 * pad - 7 * gap) / 8);
          final ch = cw * kCardAspect;
          final overlap = ch * 0.3;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 8 * cw + 7 * gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      for (var k = 0; k < FreeCellGame.numCells; k++) ...[
                        if (k > 0) const SizedBox(width: gap),
                        _cell(k, cw),
                      ],
                      for (var s = 0; s < 4; s++) ...[
                        const SizedBox(width: gap),
                        _foundation(s, cw),
                      ],
                    ]),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < FreeCellGame.numColumns; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          _column(c, cw, ch, overlap),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Tap a card to send it · long-press to pick it up',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _game.won
                            ? 'Solved in ${GameClock.format(_clock.seconds)}'
                                ' · ${_game.moves} moves'
                            : _game.stuck
                                ? 'No moves left — undo or restart'
                                : 'Moves: ${_game.moves}'
                                    '  ·  ${GameClock.format(_clock.seconds)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _cell(int k, double cw) {
    final card = _game.cells[k];
    final selected = _sel?.pile == Pile.cell && _sel?.index == k;
    return GestureDetector(
      key: Key('fc-cell-$k'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapCell(k),
      onLongPress: () => _pickUpCell(k),
      child: card == null
          ? EmptySlot(width: cw)
          : PlayingCardView(card: card, width: cw, selected: selected),
    );
  }

  Widget _foundation(int s, double cw) {
    final n = _game.foundations[s];
    final suit = Suit.values[s];
    return GestureDetector(
      key: Key('fc-found-$s'),
      behavior: HitTestBehavior.opaque,
      onTap: _tapFoundation,
      child: n == 0
          ? EmptySlot(width: cw, hint: suit.symbol)
          : PlayingCardView(card: PlayingCard(n - 1, suit), width: cw),
    );
  }

  Widget _column(int c, double cw, double ch, double overlap) {
    final col = _game.columns[c];
    if (col.isEmpty) {
      return GestureDetector(
        key: Key('fc-col-$c'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapEmptyColumn(c),
        child: EmptySlot(width: cw),
      );
    }
    final s = _sel;
    final selStart = (s != null && s.pile == Pile.column && s.index == c)
        ? col.length - s.count
        : col.length;
    return SizedBox(
      width: cw,
      height: ch + (col.length - 1) * overlap,
      child: Stack(
        children: [
          for (var i = 0; i < col.length; i++)
            Positioned(
              top: i * overlap,
              child: GestureDetector(
                key: Key('fc-card-$c-$i'),
                onTap: () => _tapColumnCard(c, i),
                onLongPress: () => _pickUpColumn(c, i),
                child: PlayingCardView(
                  card: col[i],
                  width: cw,
                  selected: i >= selStart,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
