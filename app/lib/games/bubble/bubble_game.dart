import 'package:sudoku_app/games/bubble/bubble_variant.dart';

/// Board sizes. The enum ORDER is part of the leaderboard id scheme (see
/// `bubble_variant.dart`), so only ever append.
enum BubbleSize {
  medium(10, 12, 'Medium'),
  small(8, 10, 'Small'),
  large(12, 14, 'Large'),
  xlarge(14, 16, 'X-Large'),
  // The classic game's own size presets (portrait layout).
  standard(10, 15, 'Standard'),
  dense(15, 22, 'Dense'),
  tiny(20, 30, 'Tiny'),
  unified(9, 16, 'Unified'),
  unifiedV2(13, 24, 'Unified V2');

  /// The order sizes are listed in the Options screen: roughly smallest board
  /// to largest.
  static const List<BubbleSize> displayOrder = [
    small,
    medium,
    standard,
    unified,
    large,
    xlarge,
    unifiedV2,
    dense,
    tiny,
  ];

  final int width;
  final int height;
  final String label;
  const BubbleSize(this.width, this.height, this.label);
}

/// Difficulty = how many colours are in play (more colours, fewer matches).
/// Like [BubbleSize] the ORDER is part of the leaderboard id scheme: append only.
enum BubbleLevel {
  normal(5, 'Normal'),
  easy(4, 'Easy'),
  hard(6, 'Hard');

  final int colors;
  final String label;
  const BubbleLevel(this.colors, this.label);
}

/// One bubble. [id] is stable for its whole life so the UI can animate it
/// falling; [color] is 0..[BubbleGame.colors]-1.
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
  static const int clearBonus = 1000;

  final int deal;
  final BubbleSize size;
  final BubbleLevel level;

  /// When true (the classic rule) empty columns slide away so the remaining
  /// ones close ranks to the left; when false the board stays fixed and an
  /// emptied column leaves a permanent gap.
  final bool collapse;

  /// Columns left→right; each is bottom→top, so `columns[c][0]` is the bubble
  /// resting on the floor. With [collapse], empty columns are always at the
  /// right-hand end.
  final List<List<Bubble>> columns;
  int score;

  /// Pops made so far (the "tap count").
  int moves;

  /// Points from the single best pop so far.
  int bestPop;

  final List<_Snapshot> _history = [];

  BubbleGame({
    required this.deal,
    required this.columns,
    this.size = BubbleSize.medium,
    this.level = BubbleLevel.normal,
    this.collapse = true,
    this.score = 0,
    this.moves = 0,
    this.bestPop = 0,
  });

  /// Number of colours in this game.
  int get colors => level.colors;

  /// Level/size/mode variant used for leaderboard ids (see
  /// `bubble_variant.dart`).
  int get variant => encodeBubbleVariant(
      level: level.index, size: size.index, fixed: !collapse);

  static BubbleSize sizeOfVariant(int v) =>
      BubbleSize.values[decodeBubbleVariant(v).size];
  static BubbleLevel levelOfVariant(int v) =>
      BubbleLevel.values[decodeBubbleVariant(v).level];
  static bool collapseOfVariant(int v) => !decodeBubbleVariant(v).fixed;

  int get width => size.width;
  int get height => size.height;

  /// Deterministic board: same [number] + options → same board everywhere.
  factory BubbleGame.deal(
    int number, {
    BubbleSize size = BubbleSize.medium,
    BubbleLevel level = BubbleLevel.normal,
    bool collapse = true,
  }) {
    var seed = number;
    var id = 0;
    final cols = <List<Bubble>>[];
    for (var c = 0; c < size.width; c++) {
      final col = <Bubble>[];
      for (var r = 0; r < size.height; r++) {
        seed = (seed * 214013 + 2531011) & 0xFFFFFFFF;
        col.add(Bubble(id++, ((seed >> 16) & 0x7FFF) % level.colors));
      }
      cols.add(col);
    }
    return BubbleGame(
        deal: number,
        columns: cols,
        size: size,
        level: level,
        collapse: collapse);
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

  /// How many bubbles of each colour are left (index = colour).
  List<int> colorCounts() {
    final counts = List<int>.filled(colors, 0);
    for (final c in columns) {
      for (final b in c) {
        counts[b.color]++;
      }
    }
    return counts;
  }

  bool get canUndo => _history.isNotEmpty;

  /// Takes back the last pop (restoring score, taps and the bubbles).
  void undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    columns
      ..clear()
      ..addAll(snap.columns.map((c) => List<Bubble>.of(c)));
    score = snap.score;
    moves = snap.moves;
    bestPop = snap.bestPop;
  }

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
    _history.add(_Snapshot(
      [for (final col in columns) List<Bubble>.of(col)],
      score,
      moves,
      bestPop,
    ));
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
    if (collapse) {
      // Slide empty columns away to the right.
      final kept = columns.where((col) => col.isNotEmpty).toList();
      columns
        ..clear()
        ..addAll(kept)
        ..addAll(List.generate(width - kept.length, (_) => <Bubble>[]));
    }

    final points = pointsFor(group.length);
    if (points > bestPop) bestPop = points;
    score += points;
    moves++;
    if (cleared) score += clearBonus;
    return group.length;
  }

  Map<String, dynamic> toJson() => {
        'deal': deal,
        'size': size.index,
        'level': level.index,
        'collapse': collapse,
        'score': score,
        'moves': moves,
        'bestPop': bestPop,
        // id * 8 + color, bottom→top.
        'columns': [
          for (final c in columns) [for (final b in c) b.id * 8 + b.color]
        ],
      };

  factory BubbleGame.fromJson(Map<String, dynamic> j) => BubbleGame(
        deal: j['deal'] as int,
        size: BubbleSize.values[(j['size'] ?? 0) as int],
        level: BubbleLevel.values[(j['level'] ?? 0) as int],
        collapse: (j['collapse'] ?? true) as bool,
        score: j['score'] as int,
        moves: j['moves'] as int,
        bestPop: (j['bestPop'] ?? 0) as int,
        columns: [
          for (final c in j['columns'] as List)
            [
              for (final v in c as List) Bubble((v as int) ~/ 8, v % 8),
            ]
        ],
      );
}

class _Snapshot {
  final List<List<Bubble>> columns;
  final int score;
  final int moves;
  final int bestPop;
  _Snapshot(this.columns, this.score, this.moves, this.bestPop);
}
