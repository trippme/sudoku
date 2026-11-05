import 'package:sudoku_app/games/cards/playing_card.dart';

enum Pile { column, cell, foundation }

class _Snapshot {
  final List<List<PlayingCard>> columns;
  final List<PlayingCard?> cells;
  final List<int> foundations;
  _Snapshot(this.columns, this.cells, this.foundations);
}

/// FreeCell rules + state. Pure Dart (no Flutter) so it is trivially testable.
class FreeCellGame {
  static const int numColumns = 8;
  static const int numCells = 4;

  final int deal;
  final List<List<PlayingCard>> columns;
  final List<PlayingCard?> cells;

  /// Cards placed on each foundation, indexed by [Suit.index]
  /// (n cards means Ace..n-th rank are up).
  final List<int> foundations;
  int moves;
  final List<_Snapshot> _history = [];

  FreeCellGame({
    required this.deal,
    required this.columns,
    required this.cells,
    required this.foundations,
    this.moves = 0,
  });

  /// The classic Microsoft FreeCell deal for [number] (so #1, #617, … match the
  /// numbered deals players know). Same number → same deal on every device.
  factory FreeCellGame.deal(int number) {
    final deck = List<int>.generate(52, (i) => i);
    var seed = number;
    final cols = List.generate(numColumns, (_) => <PlayingCard>[]);
    for (var left = 52, k = 0; left > 0; left--, k++) {
      seed = (seed * 214013 + 2531011) & 0xFFFFFFFF;
      final pos = ((seed >> 16) & 0x7FFF) % left;
      cols[k % numColumns].add(PlayingCard.fromCode(deck[pos]));
      deck[pos] = deck[left - 1];
    }
    return FreeCellGame(
      deal: number,
      columns: cols,
      cells: List<PlayingCard?>.filled(numCells, null),
      foundations: List<int>.filled(4, 0),
    );
  }

  bool get won => foundations.every((n) => n == 13);
  bool get canUndo => _history.isNotEmpty;
  int get emptyCells => cells.where((c) => c == null).length;
  int get emptyColumns => columns.where((c) => c.isEmpty).length;

  /// How many cards can move as one stack (the "supermove" limit).
  int maxMovable({bool toEmptyColumn = false}) =>
      (emptyCells + 1) * (1 << (emptyColumns - (toEmptyColumn ? 1 : 0)));

  static bool _links(PlayingCard upper, PlayingCard lower) =>
      upper.rank == lower.rank + 1 && upper.isRed != lower.isRed;

  /// True when the tail of column [c] starting at [from] is a legal sequence.
  bool isSequence(int c, int from) {
    final col = columns[c];
    if (from < 0 || from >= col.length) return false;
    for (var i = from; i < col.length - 1; i++) {
      if (!_links(col[i], col[i + 1])) return false;
    }
    return true;
  }

  List<PlayingCard>? _peek(Pile from, int index, int count) {
    switch (from) {
      case Pile.column:
        final col = columns[index];
        if (count < 1 || count > col.length) return null;
        if (!isSequence(index, col.length - count)) return null;
        return col.sublist(col.length - count);
      case Pile.cell:
        final c = cells[index];
        return (c == null || count != 1) ? null : [c];
      case Pile.foundation:
        return null;
    }
  }

  bool canMove(Pile from, int index, int count, Pile to, int toIndex) {
    final cards = _peek(from, index, count);
    if (cards == null) return false;
    switch (to) {
      case Pile.column:
        if (from == Pile.column && index == toIndex) return false;
        final dest = columns[toIndex];
        if (count > maxMovable(toEmptyColumn: dest.isEmpty)) return false;
        return dest.isEmpty || _links(dest.last, cards.first);
      case Pile.cell:
        if (count != 1 || cells[toIndex] != null) return false;
        return !(from == Pile.cell && index == toIndex);
      case Pile.foundation:
        return count == 1 &&
            foundations[cards.first.suit.index] == cards.first.rank;
    }
  }

  /// Performs the move if legal; returns whether it happened.
  bool move(Pile from, int index, int count, Pile to, [int toIndex = 0]) {
    if (!canMove(from, index, count, to, toIndex)) return false;
    final cards = _peek(from, index, count)!;
    _history.add(_snapshot());
    switch (from) {
      case Pile.column:
        final col = columns[index];
        col.removeRange(col.length - count, col.length);
      case Pile.cell:
        cells[index] = null;
      case Pile.foundation:
        break;
    }
    switch (to) {
      case Pile.column:
        columns[toIndex].addAll(cards);
      case Pile.cell:
        cells[toIndex] = cards.first;
      case Pile.foundation:
        foundations[cards.first.suit.index]++;
    }
    moves++;
    return true;
  }

  /// Sends the single card at the given spot to its foundation if it fits.
  bool toFoundation(Pile from, int index) =>
      move(from, index, 1, Pile.foundation);

  /// Moves every "safe" card (one that can never be needed on the tableau) up
  /// to the foundations. Returns how many cards moved.
  int autoFoundation() {
    var moved = 0;
    var progress = true;
    while (progress) {
      progress = false;
      for (var c = 0; c < numColumns; c++) {
        if (columns[c].isNotEmpty &&
            _safe(columns[c].last) &&
            toFoundation(Pile.column, c)) {
          moved++;
          progress = true;
        }
      }
      for (var k = 0; k < numCells; k++) {
        final card = cells[k];
        if (card != null && _safe(card) && toFoundation(Pile.cell, k)) {
          moved++;
          progress = true;
        }
      }
    }
    return moved;
  }

  bool _safe(PlayingCard c) {
    if (foundations[c.suit.index] != c.rank) return false; // not playable yet
    if (c.rank == 0) return true;
    final opp = c.isRed
        ? [Suit.clubs.index, Suit.spades.index]
        : [Suit.diamonds.index, Suit.hearts.index];
    return opp.every((s) => foundations[s] >= c.rank);
  }

  /// True when the game isn't won and no legal move remains.
  bool get stuck {
    if (won) return false;
    for (var c = 0; c < numColumns; c++) {
      for (var n = 1; n <= columns[c].length; n++) {
        if (_hasDestination(Pile.column, c, n)) return false;
      }
    }
    for (var k = 0; k < numCells; k++) {
      if (_hasDestination(Pile.cell, k, 1)) return false;
    }
    return true;
  }

  bool _hasDestination(Pile p, int i, int n) {
    if (_peek(p, i, n) == null) return false;
    for (var d = 0; d < numColumns; d++) {
      if (canMove(p, i, n, Pile.column, d)) return true;
    }
    for (var d = 0; d < numCells; d++) {
      if (canMove(p, i, n, Pile.cell, d)) return true;
    }
    return canMove(p, i, n, Pile.foundation, 0);
  }

  _Snapshot _snapshot() => _Snapshot(
        [for (final c in columns) List<PlayingCard>.of(c)],
        List<PlayingCard?>.of(cells),
        List<int>.of(foundations),
      );

  void undo() {
    if (_history.isEmpty) return;
    final s = _history.removeLast();
    for (var i = 0; i < numColumns; i++) {
      columns[i]
        ..clear()
        ..addAll(s.columns[i]);
    }
    for (var i = 0; i < numCells; i++) {
      cells[i] = s.cells[i];
    }
    for (var i = 0; i < 4; i++) {
      foundations[i] = s.foundations[i];
    }
    if (moves > 0) moves--;
  }

  Map<String, dynamic> toJson() => {
        'deal': deal,
        'moves': moves,
        'columns': [
          for (final c in columns) [for (final x in c) x.code]
        ],
        'cells': [for (final c in cells) c?.code],
        'foundations': foundations,
      };

  factory FreeCellGame.fromJson(Map<String, dynamic> j) => FreeCellGame(
        deal: j['deal'] as int,
        moves: j['moves'] as int,
        columns: [
          for (final c in j['columns'] as List)
            [for (final x in c as List) PlayingCard.fromCode(x as int)]
        ],
        cells: [
          for (final c in j['cells'] as List)
            c == null ? null : PlayingCard.fromCode(c as int)
        ],
        foundations: List<int>.from(j['foundations'] as List),
      );
}
