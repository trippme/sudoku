import 'package:sudoku_app/games/cards/playing_card.dart';

enum SolPile { waste, column, foundation }

class _Snapshot {
  final List<List<PlayingCard>> columns;
  final List<int> faceUp;
  final List<PlayingCard> stock;
  final List<PlayingCard> waste;
  final List<int> foundations;
  _Snapshot(this.columns, this.faceUp, this.stock, this.waste, this.foundations);
}

/// Klondike Solitaire rules + state. Pure Dart so it is easy to unit test.
class SolitaireGame {
  static const int numColumns = 7;

  final int deal;

  /// 1 or 3 cards turned from the stock at a time.
  final int drawCount;

  /// Tableau columns, bottom → top. The last [faceUp] cards of each are face up.
  final List<List<PlayingCard>> columns;
  final List<int> faceUp;

  /// Top of the stock / waste is the LAST element.
  final List<PlayingCard> stock;
  final List<PlayingCard> waste;

  /// Cards on each foundation, indexed by [Suit.index].
  final List<int> foundations;
  int moves;
  final List<_Snapshot> _history = [];

  SolitaireGame({
    required this.deal,
    required this.drawCount,
    required this.columns,
    required this.faceUp,
    required this.stock,
    required this.waste,
    required this.foundations,
    this.moves = 0,
  });

  /// Deterministic deal: the same [number] gives the same layout on every
  /// device (own LCG, so it doesn't depend on the platform's `Random`).
  factory SolitaireGame.deal(int number, {int drawCount = 1}) {
    final deck = List<int>.generate(52, (i) => i);
    var seed = number;
    final order = <PlayingCard>[];
    for (var left = 52; left > 0; left--) {
      seed = (seed * 214013 + 2531011) & 0xFFFFFFFF;
      final pos = ((seed >> 16) & 0x7FFF) % left;
      order.add(PlayingCard.fromCode(deck[pos]));
      deck[pos] = deck[left - 1];
    }
    final cols = List.generate(numColumns, (_) => <PlayingCard>[]);
    var k = 0;
    for (var c = 0; c < numColumns; c++) {
      for (var n = 0; n <= c; n++) {
        cols[c].add(order[k++]);
      }
    }
    return SolitaireGame(
      deal: number,
      drawCount: drawCount,
      columns: cols,
      faceUp: List<int>.filled(numColumns, 1),
      stock: order.sublist(k), // 24 cards
      waste: [],
      foundations: List<int>.filled(4, 0),
    );
  }

  bool get won => foundations.every((n) => n == 13);
  bool get canUndo => _history.isNotEmpty;

  static bool _links(PlayingCard upper, PlayingCard lower) =>
      upper.rank == lower.rank + 1 && upper.isRed != lower.isRed;

  /// Turns stock cards onto the waste; with an empty stock, recycles the waste.
  /// Returns false if there is nothing to do.
  bool draw() {
    if (stock.isEmpty && waste.isEmpty) return false;
    _history.add(_snapshot());
    if (stock.isEmpty) {
      // Flip the waste back over: its first-drawn card is on top again.
      stock.addAll(waste.reversed);
      waste.clear();
    } else {
      for (var i = 0; i < drawCount && stock.isNotEmpty; i++) {
        waste.add(stock.removeLast());
      }
    }
    moves++;
    return true;
  }

  List<PlayingCard>? _peek(SolPile from, int index, int count) {
    switch (from) {
      case SolPile.waste:
        return (waste.isEmpty || count != 1) ? null : [waste.last];
      case SolPile.column:
        final col = columns[index];
        if (count < 1 || count > faceUp[index]) return null;
        return col.sublist(col.length - count);
      case SolPile.foundation:
        final n = foundations[index];
        return (n == 0 || count != 1) ? null : [PlayingCard(n - 1, Suit.values[index])];
    }
  }

  bool canMove(SolPile from, int index, int count, SolPile to, int toIndex) {
    final cards = _peek(from, index, count);
    if (cards == null) return false;
    switch (to) {
      case SolPile.waste:
        return false;
      case SolPile.column:
        if (from == SolPile.column && index == toIndex) return false;
        final dest = columns[toIndex];
        if (dest.isEmpty) return cards.first.rank == 12;
        return _links(dest.last, cards.first);
      case SolPile.foundation:
        if (count != 1 || from == SolPile.foundation) return false;
        return foundations[cards.first.suit.index] == cards.first.rank;
    }
  }

  bool move(SolPile from, int index, int count, SolPile to, [int toIndex = 0]) {
    if (!canMove(from, index, count, to, toIndex)) return false;
    final cards = _peek(from, index, count)!;
    _history.add(_snapshot());
    switch (from) {
      case SolPile.waste:
        waste.removeLast();
      case SolPile.column:
        final col = columns[index];
        col.removeRange(col.length - count, col.length);
        faceUp[index] -= count;
        if (faceUp[index] == 0 && col.isNotEmpty) faceUp[index] = 1; // flip
      case SolPile.foundation:
        foundations[index]--;
    }
    switch (to) {
      case SolPile.waste:
        break;
      case SolPile.column:
        columns[toIndex].addAll(cards);
        faceUp[toIndex] += count;
      case SolPile.foundation:
        foundations[cards.first.suit.index]++;
    }
    moves++;
    return true;
  }

  /// Moves every card that can go up to a foundation (waste top and column
  /// tops), repeatedly. Returns how many cards moved.
  int autoFoundation() {
    var moved = 0;
    var progress = true;
    while (progress) {
      progress = false;
      if (move(SolPile.waste, 0, 1, SolPile.foundation)) {
        moved++;
        progress = true;
      }
      for (var c = 0; c < numColumns; c++) {
        if (columns[c].isNotEmpty && move(SolPile.column, c, 1, SolPile.foundation)) {
          moved++;
          progress = true;
        }
      }
    }
    return moved;
  }

  _Snapshot _snapshot() => _Snapshot(
        [for (final c in columns) List<PlayingCard>.of(c)],
        List<int>.of(faceUp),
        List<PlayingCard>.of(stock),
        List<PlayingCard>.of(waste),
        List<int>.of(foundations),
      );

  void undo() {
    if (_history.isEmpty) return;
    final s = _history.removeLast();
    for (var i = 0; i < numColumns; i++) {
      columns[i]
        ..clear()
        ..addAll(s.columns[i]);
      faceUp[i] = s.faceUp[i];
    }
    stock
      ..clear()
      ..addAll(s.stock);
    waste
      ..clear()
      ..addAll(s.waste);
    for (var i = 0; i < 4; i++) {
      foundations[i] = s.foundations[i];
    }
    if (moves > 0) moves--;
  }

  Map<String, dynamic> toJson() => {
        'deal': deal,
        'draw': drawCount,
        'moves': moves,
        'columns': [
          for (final c in columns) [for (final x in c) x.code]
        ],
        'faceUp': faceUp,
        'stock': [for (final x in stock) x.code],
        'waste': [for (final x in waste) x.code],
        'foundations': foundations,
      };

  factory SolitaireGame.fromJson(Map<String, dynamic> j) {
    List<PlayingCard> cards(Object? l) =>
        [for (final x in l as List) PlayingCard.fromCode(x as int)];
    return SolitaireGame(
      deal: j['deal'] as int,
      drawCount: j['draw'] as int,
      moves: j['moves'] as int,
      columns: [for (final c in j['columns'] as List) cards(c)],
      faceUp: List<int>.from(j['faceUp'] as List),
      stock: cards(j['stock']),
      waste: cards(j['waste']),
      foundations: List<int>.from(j['foundations'] as List),
    );
  }
}
