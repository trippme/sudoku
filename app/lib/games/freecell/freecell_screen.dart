import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku_app/games/cards/card_widgets.dart';
import 'package:sudoku_app/games/cards/game_clock.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/cards/win_flow.dart';
import 'package:sudoku_app/games/freecell/freecell_game.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/ui/leaderboard_screen.dart';
import 'package:sudoku_app/ui/send_to_friends.dart';

const String kFreeCellSaveKey = 'freecell.save';
const String kFreeCellAutoCollectKey = 'freecell.autocollect';

/// How long a card takes to glide to its new spot.
const Duration kCardMoveDuration = Duration(milliseconds: 450);

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

/// One card's resting place in the layout.
class _Placed {
  final PlayingCard card;
  final Pile pile;
  final int index; // column / cell / foundation index
  final int slot; // position within a column (0 elsewhere)
  final double left;
  final double top;
  final double z;
  const _Placed(this.card, this.pile, this.index, this.slot, this.left,
      this.top, this.z);
}

class _FreeCellScreenState extends State<FreeCellScreen> {
  late FreeCellGame _game;
  late final GameClock _clock;
  _Sel? _sel;
  bool _autoCollect = false;

  /// Cards that just moved: drawn on top of the others while they glide.
  Set<int> _flying = {};
  Timer? _flyTimer;
  Map<int, int> _lastSpots = {};

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
    _autoCollect = widget.persist &&
        Storage.getString(kFreeCellAutoCollectKey) == 'true';
    _lastSpots = _spots();
    _clock = GameClock(seconds: secs, onTick: () {
      if (mounted) setState(() {});
    });
    if (!_game.won) _clock.start();
  }

  @override
  void dispose() {
    _save();
    _flyTimer?.cancel();
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

  /// code -> encoded spot, to work out which cards moved.
  Map<int, int> _spots() {
    final m = <int, int>{};
    for (var c = 0; c < FreeCellGame.numColumns; c++) {
      for (var i = 0; i < _game.columns[c].length; i++) {
        m[_game.columns[c][i].code] = 1000 + c * 100 + i;
      }
    }
    for (var k = 0; k < FreeCellGame.numCells; k++) {
      final card = _game.cells[k];
      if (card != null) m[card.code] = 5000 + k;
    }
    for (var s = 0; s < 4; s++) {
      for (var r = 0; r < _game.foundations[s]; r++) {
        m[PlayingCard(r, Suit.values[s]).code] = 6000 + s;
      }
    }
    return m;
  }

  void _afterMove() {
    final now = _spots();
    _flying = {
      for (final e in now.entries)
        if (_lastSpots[e.key] != e.value) e.key
    };
    _lastSpots = now;
    _flyTimer?.cancel();
    _flyTimer = Timer(kCardMoveDuration, () {
      if (mounted) setState(() => _flying = {});
    });
    _sel = null;
    _save();
    setState(() {});
    if (_game.won) {
      _clock.stop();
      // Let the last card land before the dialog covers the board.
      Future.delayed(kCardMoveDuration + const Duration(milliseconds: 150), () {
        if (mounted) _showWin();
      });
    }
  }

  void _newDeal(int deal) {
    setState(() {
      _game = FreeCellGame.deal(deal);
      _sel = null;
      _flying = {};
      _lastSpots = _spots();
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

  void _toggleAutoCollect() {
    setState(() => _autoCollect = !_autoCollect);
    if (widget.persist) {
      Storage.setString(kFreeCellAutoCollectKey, _autoCollect ? 'true' : 'false');
    }
  }

  // ---- tap handling -------------------------------------------------------
  //
  // Tap a card to pick it up, then tap where it should go (legal spots glow
  // green). Tapping the picked-up card again sends it to the best spot.

  bool _play(_Sel s, Pile to, int toIndex) {
    if (_game.play(s.pile, s.index, s.count, to, toIndex, sweep: _autoCollect)) {
      _afterMove();
      return true;
    }
    return false;
  }

  void _autoSend(_Sel s) {
    final d = _game.bestDestination(s.pile, s.index, s.count);
    if (d != null) _play(s, d.pile, d.index);
  }

  void _tapColumnCard(int c, int i) {
    final s = _sel;
    final count = _game.columns[c].length - i;
    if (s != null) {
      if (s.pile == Pile.column && s.index == c && s.count == count) {
        _autoSend(s);
        return;
      }
      if (_play(s, Pile.column, c)) return;
    }
    setState(() {
      _sel = _game.isSequence(c, i) ? _Sel(Pile.column, c, count) : null;
    });
  }

  void _tapEmptyColumn(int c) {
    final s = _sel;
    if (s != null) _play(s, Pile.column, c);
  }

  void _tapCell(int k) {
    final s = _sel;
    final card = _game.cells[k];
    if (s != null && s.pile == Pile.cell && s.index == k) {
      _autoSend(s);
    } else if (s != null && card == null) {
      _play(s, Pile.cell, k);
    } else if (card != null) {
      setState(() => _sel = _Sel(Pile.cell, k, 1));
    }
  }

  void _tapFoundation() {
    final s = _sel;
    if (s != null) _play(s, Pile.foundation, 0);
  }

  // ---- layout -------------------------------------------------------------

  List<_Placed> _layout(double cw, double ch, double gap, double overlap) {
    double x(int i) => i * (cw + gap);
    final tableauTop = ch + 14;
    final out = <_Placed>[];
    for (var c = 0; c < FreeCellGame.numColumns; c++) {
      for (var i = 0; i < _game.columns[c].length; i++) {
        out.add(_Placed(_game.columns[c][i], Pile.column, c, i, x(c),
            tableauTop + i * overlap, 100.0 + i));
      }
    }
    for (var k = 0; k < FreeCellGame.numCells; k++) {
      final card = _game.cells[k];
      if (card != null) {
        out.add(_Placed(card, Pile.cell, k, 0, x(k), 0, 50));
      }
    }
    for (var s = 0; s < 4; s++) {
      for (var r = 0; r < _game.foundations[s]; r++) {
        out.add(_Placed(
            PlayingCard(r, Suit.values[s]), Pile.foundation, s, 0, x(4 + s), 0,
            r.toDouble()));
      }
    }
    return out;
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
                case 'autocollect':
                  _toggleAutoCollect();
                case 'board':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(gameId: _ref.id)));
                case 'send':
                  sendGameToFriends(context,
                      gameId: _ref.id, label: _ref.label);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'new', child: Text('New random deal')),
              const PopupMenuItem(
                  value: 'choose', child: Text('Play deal number…')),
              const PopupMenuItem(
                  value: 'restart', child: Text('Restart this deal')),
              PopupMenuItem(
                value: 'autocollect',
                child: Text(
                    'Auto-collect safe cards: ${_autoCollect ? 'on' : 'off'}'),
              ),
              const PopupMenuItem(value: 'board', child: Text('Leaderboard')),
              const PopupMenuItem(
                  value: 'send', child: Text('Challenge a friend')),
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
          final boardW = 8 * cw + 7 * gap;
          final longest = _game.columns.fold<int>(7, (m, c) => max(m, c.length));
          final boardH = ch + 14 + ch + (longest - 1) * overlap + 8;

          final placed = _layout(cw, ch, gap, overlap)
            ..sort((a, b) {
              final za = a.z + (_flying.contains(a.card.code) ? 1000 : 0);
              final zb = b.z + (_flying.contains(b.card.code) ? 1000 : 0);
              return za.compareTo(zb);
            });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Center(
              child: SizedBox(
                width: boardW,
                child: Column(
                  children: [
                    SizedBox(
                      width: boardW,
                      height: boardH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Tapping bare table puts the card back down.
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _sel = null),
                            ),
                          ),
                          ..._slots(cw, ch, gap),
                          for (final p in placed) _cardAt(p, cw),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _game.won
                          ? 'Solved in ${GameClock.format(_clock.seconds)}'
                              ' · ${_game.moves} moves'
                          : _game.stuck
                              ? 'No moves left — undo or restart'
                              : 'Moves: ${_game.moves}'
                                  '  ·  ${GameClock.format(_clock.seconds)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a card, then tap where it goes · '
                      'tap it again to send it automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
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

  bool _legal(Pile to, int toIndex) {
    final s = _sel;
    return s != null && _game.canMove(s.pile, s.index, s.count, to, toIndex);
  }

  /// The empty outlines (free cells, foundations, empty columns) that take taps.
  List<Widget> _slots(double cw, double ch, double gap) {
    double x(int i) => i * (cw + gap);
    return [
      for (var k = 0; k < FreeCellGame.numCells; k++)
        Positioned(
          left: x(k),
          top: 0,
          child: GestureDetector(
            key: Key('fc-cell-$k'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapCell(k),
            child: EmptySlot(
              width: cw,
              highlight: _game.cells[k] == null && _legal(Pile.cell, k),
            ),
          ),
        ),
      for (var s = 0; s < 4; s++)
        Positioned(
          left: x(4 + s),
          top: 0,
          child: GestureDetector(
            key: Key('fc-found-$s'),
            behavior: HitTestBehavior.opaque,
            onTap: _tapFoundation,
            child: EmptySlot(
              width: cw,
              hint: Suit.values[s].symbol,
              highlight: _legal(Pile.foundation, 0) &&
                  _sel != null &&
                  _selectedSuit() == s,
            ),
          ),
        ),
      for (var c = 0; c < FreeCellGame.numColumns; c++)
        if (_game.columns[c].isEmpty)
          Positioned(
            left: x(c),
            top: ch + 14,
            child: GestureDetector(
              key: Key('fc-col-$c'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tapEmptyColumn(c),
              child: EmptySlot(width: cw, highlight: _legal(Pile.column, c)),
            ),
          ),
    ];
  }

  int? _selectedSuit() {
    final s = _sel;
    if (s == null) return null;
    if (s.pile == Pile.column) return _game.columns[s.index].last.suit.index;
    if (s.pile == Pile.cell) return _game.cells[s.index]?.suit.index;
    return null;
  }

  /// A card that glides (AnimatedPositioned) whenever its spot changes.
  Widget _cardAt(_Placed p, double cw) {
    final sel = _sel;
    var selected = false;
    var highlight = false;
    if (p.pile == Pile.column) {
      final col = _game.columns[p.index];
      if (sel != null && sel.pile == Pile.column && sel.index == p.index) {
        selected = p.slot >= col.length - sel.count;
      }
      highlight = p.slot == col.length - 1 && _legal(Pile.column, p.index);
    } else if (p.pile == Pile.cell) {
      selected = sel != null && sel.pile == Pile.cell && sel.index == p.index;
    }

    Widget card = PlayingCardView(
      card: p.card,
      width: cw,
      selected: selected,
      highlight: highlight,
    );
    if (p.pile == Pile.column) {
      card = GestureDetector(
        key: Key('fc-card-${p.index}-${p.slot}'),
        onTap: () => _tapColumnCard(p.index, p.slot),
        child: card,
      );
    } else {
      // Cells and foundations take their taps on the slot underneath.
      card = IgnorePointer(child: card);
    }
    return AnimatedPositioned(
      key: ValueKey('${_game.deal}-${p.card.code}'),
      duration: kCardMoveDuration,
      curve: Curves.easeInOutCubic,
      left: p.left,
      top: p.top,
      child: card,
    );
  }
}
