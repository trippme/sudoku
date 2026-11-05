import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku_app/games/cards/card_widgets.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/solitaire/solitaire_game.dart';
import 'package:sudoku_app/services/storage.dart';

const String kSolitaireSaveKey = 'solitaire.save';

/// Klondike Solitaire: resumes the saved game, otherwise deals a new one.
class SolitaireScreen extends StatefulWidget {
  /// Skips persistence (used by widget tests).
  final bool persist;
  final int? initialDeal;
  const SolitaireScreen({super.key, this.persist = true, this.initialDeal});

  @override
  State<SolitaireScreen> createState() => _SolitaireScreenState();
}

class _Sel {
  final SolPile pile;
  final int index;
  final int count;
  const _Sel(this.pile, this.index, this.count);
}

class _SolitaireScreenState extends State<SolitaireScreen> {
  late SolitaireGame _game;
  _Sel? _sel;

  @override
  void initState() {
    super.initState();
    _game = _loadSaved() ??
        SolitaireGame.deal(widget.initialDeal ?? _randomDeal());
  }

  static int _randomDeal() => Random().nextInt(1000000) + 1;

  SolitaireGame? _loadSaved() {
    if (!widget.persist || widget.initialDeal != null) return null;
    try {
      final raw = Storage.getString(kSolitaireSaveKey);
      if (raw == null) return null;
      return SolitaireGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _save() {
    if (!widget.persist) return;
    if (_game.won) {
      Storage.remove(kSolitaireSaveKey);
    } else {
      Storage.setString(kSolitaireSaveKey, jsonEncode(_game.toJson()));
    }
  }

  void _afterMove() {
    _sel = null;
    _save();
    setState(() {});
    if (_game.won) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWin());
    }
  }

  void _newDeal(int deal, {int? draw}) {
    setState(() {
      _game = SolitaireGame.deal(deal, drawCount: draw ?? _game.drawCount);
      _sel = null;
    });
    _save();
  }

  Future<void> _showWin() async {
    if (!mounted) return;
    final again = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You won! 🎉'),
        content: Text('Deal #${_game.deal} solved in ${_game.moves} moves.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Close')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('New deal')),
        ],
      ),
    );
    if (again == true) _newDeal(_randomDeal());
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

  bool _tryMove(SolPile to, int toIndex) {
    final s = _sel!;
    if (_game.move(s.pile, s.index, s.count, to, toIndex)) {
      _afterMove();
      return true;
    }
    return false;
  }

  void _tapStock() {
    if (_game.draw()) _afterMove();
  }

  void _tapWaste() {
    if (_game.waste.isEmpty) return;
    final s = _sel;
    setState(() => _sel =
        (s != null && s.pile == SolPile.waste) ? null : const _Sel(SolPile.waste, 0, 1));
  }

  void _tapFoundation(int s) {
    if (_sel != null && _tryMove(SolPile.foundation, s)) return;
    if (_game.foundations[s] > 0) {
      setState(() => _sel = const _Sel(SolPile.foundation, 0, 1).copyWith(s));
    }
  }

  void _tapColumnCard(int c, int i) {
    final col = _game.columns[c];
    final faceUpStart = col.length - _game.faceUp[c];
    final s = _sel;
    if (s != null) {
      if (s.pile == SolPile.column &&
          s.index == c &&
          s.count == col.length - i) {
        setState(() => _sel = null);
        return;
      }
      if (_tryMove(SolPile.column, c)) return;
    }
    // Face-down cards can't be selected.
    setState(() => _sel =
        i >= faceUpStart ? _Sel(SolPile.column, c, col.length - i) : null);
  }

  void _tapEmptyColumn(int c) {
    if (_sel != null) _tryMove(SolPile.column, c);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solitaire #${_game.deal}'),
        actions: [
          IconButton(
            key: const Key('sol-undo'),
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
            key: const Key('sol-auto'),
            tooltip: 'Send playable cards to foundations',
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
                case 'draw':
                  _newDeal(_randomDeal(), draw: _game.drawCount == 1 ? 3 : 1);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'new', child: Text('New random deal')),
              const PopupMenuItem(
                  value: 'choose', child: Text('Play deal number…')),
              const PopupMenuItem(
                  value: 'restart', child: Text('Restart this deal')),
              PopupMenuItem(
                value: 'draw',
                child: Text(_game.drawCount == 1
                    ? 'Switch to draw 3 (new deal)'
                    : 'Switch to draw 1 (new deal)'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          const gap = 4.0;
          const pad = 8.0;
          final cw = min(96.0, (box.maxWidth - 2 * pad - 6 * gap) / 7);
          final ch = cw * kCardAspect;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 7 * cw + 6 * gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _stock(cw),
                      const SizedBox(width: gap),
                      _waste(cw),
                      SizedBox(width: gap + cw),
                      for (var s = 0; s < 4; s++) ...[
                        const SizedBox(width: gap),
                        _foundation(s, cw),
                      ],
                    ]),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < SolitaireGame.numColumns; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          _column(c, cw, ch),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Moves: ${_game.moves}  ·  Draw ${_game.drawCount}',
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

  Widget _stock(double cw) {
    return GestureDetector(
      key: const Key('sol-stock'),
      behavior: HitTestBehavior.opaque,
      onTap: _tapStock,
      child: _game.stock.isEmpty
          ? EmptySlot(width: cw, hint: _game.waste.isEmpty ? null : '↻')
          : CardBackView(width: cw),
    );
  }

  Widget _waste(double cw) {
    final selected = _sel?.pile == SolPile.waste;
    return GestureDetector(
      key: const Key('sol-waste'),
      behavior: HitTestBehavior.opaque,
      onTap: _tapWaste,
      child: _game.waste.isEmpty
          ? EmptySlot(width: cw)
          : PlayingCardView(
              card: _game.waste.last, width: cw, selected: selected),
    );
  }

  Widget _foundation(int s, double cw) {
    final n = _game.foundations[s];
    final suit = Suit.values[s];
    final selected = _sel?.pile == SolPile.foundation && _sel?.index == s;
    return GestureDetector(
      key: Key('sol-found-$s'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapFoundation(s),
      child: n == 0
          ? EmptySlot(width: cw, hint: suit.symbol)
          : PlayingCardView(
              card: PlayingCard(n - 1, suit), width: cw, selected: selected),
    );
  }

  Widget _column(int c, double cw, double ch) {
    final col = _game.columns[c];
    if (col.isEmpty) {
      return GestureDetector(
        key: Key('sol-col-$c'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapEmptyColumn(c),
        child: EmptySlot(width: cw),
      );
    }
    final faceUpStart = col.length - _game.faceUp[c];
    final s = _sel;
    final selStart = (s != null && s.pile == SolPile.column && s.index == c)
        ? col.length - s.count
        : col.length;
    final downStep = ch * 0.14, upStep = ch * 0.3;
    final tops = <double>[];
    var y = 0.0;
    for (var i = 0; i < col.length; i++) {
      tops.add(y);
      y += i < faceUpStart ? downStep : upStep;
    }
    return SizedBox(
      width: cw,
      height: tops.last + ch,
      child: Stack(
        children: [
          for (var i = 0; i < col.length; i++)
            Positioned(
              top: tops[i],
              child: GestureDetector(
                key: Key('sol-card-$c-$i'),
                onTap: () => _tapColumnCard(c, i),
                child: i < faceUpStart
                    ? CardBackView(width: cw)
                    : PlayingCardView(
                        card: col[i], width: cw, selected: i >= selStart),
              ),
            ),
        ],
      ),
    );
  }
}

extension on _Sel {
  _Sel copyWith(int index) => _Sel(pile, index, count);
}
