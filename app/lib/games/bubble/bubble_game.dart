/// One bubble. [id] is stable for its whole life so the UI can animate it
/// falling; [color] is 0..[BubbleGame.numColors]-1.
class Bubble {
  final int id;
  final int color;
  const Bubble(this.id, this.color);
}

/// Bubble Breaker (a.k.a. Jawbreaker / SameGame) rules + state. Pure Dart.
///
/// Pop a group of 2+ touching same-colour bubbles (up, down, left, right) for
/// n×(n−1) points. Bubbles fall to fill gaps and empty columns slide left.
/// Clearing the whole board is worth a bonus. The game ends when no group of
/// two remains.
class BubbleGame {
  static const int numColumns = 10;
  static const int numRows = 12;
  static const int numColors = 5;
  static const int clearBonus = 1000;

  final int deal;

  /// Columns left→right; each is bottom→top, so `columns[c][0]` is the bubble
  /// resting on the floor. Empty columns are always at the right-hand end.
  final List<List<Bubble>> columns;
  int score;
  int moves;

  BubbleGame({
    required this.deal,
    required this.columns,
    this.score = 0,
    this.moves = 0,
  });

  /// Deterministic board: same [number] → same board on every device.
  factory BubbleGame.deal(int number) {
    var seed = number;
    var id = 0;
    final cols = <List<Bubble>>[];
    for (var c = 0; c < numColumns; c++) {
      final col = <Bubble>[];
      for (var r = 0; r < numRows; r++) {
        seed = (seed * 214013 + 2531011) & 0xFFFFFFFF;
        col.add(Bubble(id++, ((seed >> 16) & 0x7FFF) % numColors));
      }
      cols.add(col);
    }
    return BubbleGame(deal: number, columns: cols);
  }

  int get remaining => columns.fold(0, (n, c) => n + c.length);
  bool get cleared => remaining == 0;

  /// True when at least one group of two or more can still be popped.
  bool get hasMoves {
    for (var c = 0; c < columns.length; c++) {
      for (var r = 0; r < columns[c].length; r++) {
        final color = columns[c][r].color;
        if (r + 1 < columns[c].length && columns[c][r + 1].color == color) {
          return true;
        }
        if (c + 1 < columns.length &&
            r < columns[c + 1].length &&
            columns[c + 1][r].color == color) {
          return true;
        }
      }
    }
    return false;
  }

  bool get over => cleared || !hasMoves;

  Bubble? at(int c, int r) {
    if (c < 0 || c >= columns.length) return null;
    if (r < 0 || r >= columns[c].length) return null;
    return columns[c][r];
  }

  /// The connected same-colour group containing (c, r) as (column, row) pairs,
  /// or an empty list if the bubble is alone (or the spot is empty).
  List<(int, int)> groupAt(int c, int r) {
    final start = at(c, r);
    if (start == null) return const [];
    final seen = <int>{c * 100 + r};
    final stack = <(int, int)>[(c, r)];
    final out = <(int, int)>[];
    while (stack.isNotEmpty) {
      final (cc, rr) = stack.removeLast();
      out.add((cc, rr));
      for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nc = cc + dc, nr = rr + dr;
        final b = at(nc, nr);
        if (b != null && b.color == start.color && seen.add(nc * 100 + nr)) {
          stack.add((nc, nr));
        }
      }
    }
    return out.length >= 2 ? out : const [];
  }

  /// Points for popping a group of [n].
  static int pointsFor(int n) => n * (n - 1);

  /// Pops the group at (c, r). Returns how many bubbles went (0 if it wasn't a
  /// legal group).
  int pop(int c, int r) {
    final group = groupAt(c, r);
    if (group.isEmpty) return 0;
    // Remove from the top down so row indices stay valid.
    final byColumn = <int, List<int>>{};
    for (final (cc, rr) in group) {
      byColumn.putIfAbsent(cc, () => []).add(rr);
    }
    for (final e in byColumn.entries) {
      for (final rr in (e.value..sort()).reversed) {
        columns[e.key].removeAt(rr);
      }
    }
    // Slide empty columns away to the right.
    final kept = columns.where((col) => col.isNotEmpty).toList();
    columns
      ..clear()
      ..addAll(kept)
      ..addAll(List.generate(numColumns - kept.length, (_) => <Bubble>[]));

    score += pointsFor(group.length);
    moves++;
    if (cleared) score += clearBonus;
    return group.length;
  }

  Map<String, dynamic> toJson() => {
        'deal': deal,
        'score': score,
        'moves': moves,
        // id * 8 + color, bottom→top.
        'columns': [
          for (final c in columns) [for (final b in c) b.id * 8 + b.color]
        ],
      };

  factory BubbleGame.fromJson(Map<String, dynamic> j) => BubbleGame(
        deal: j['deal'] as int,
        score: j['score'] as int,
        moves: j['moves'] as int,
        columns: [
          for (final c in j['columns'] as List)
            [
              for (final v in c as List) Bubble((v as int) ~/ 8, v % 8),
            ]
        ],
      );
}
