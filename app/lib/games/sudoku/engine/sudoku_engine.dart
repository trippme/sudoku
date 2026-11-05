import 'dart:math';

/// Core Sudoku engine: solving, uniqueness checking, generation, and
/// human-technique difficulty rating. Runs entirely on-device (no server).
///
/// A grid is a `List<int>` of length 81, row-major. 0 means empty,
/// 1..9 are filled digits.

enum Difficulty { easy, medium, hard, expert }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
        Difficulty.expert => 'Expert',
      };
}

/// Result of generating a puzzle: the puzzle (with blanks) and its solution.
class Puzzle {
  final List<int> givens; // 81, 0 = blank
  final List<int> solution; // 81, fully solved
  final Difficulty difficulty;

  Puzzle(this.givens, this.solution, this.difficulty);
}

class SudokuEngine {
  final Random _rng;
  SudokuEngine([int? seed]) : _rng = seed == null ? Random() : Random(seed);

  // ---- Geometry helpers -------------------------------------------------

  static int rowOf(int i) => i ~/ 9;
  static int colOf(int i) => i % 9;
  static int boxOf(int i) => (i ~/ 9 ~/ 3) * 3 + (i % 9) ~/ 3;

  /// Precomputed peers (the 20 cells sharing a row, column, or box).
  static final List<List<int>> peers = _buildPeers();

  static List<List<int>> _buildPeers() {
    final result = List.generate(81, (_) => <int>[]);
    for (var i = 0; i < 81; i++) {
      final seen = <int>{};
      for (var j = 0; j < 81; j++) {
        if (j == i) continue;
        if (rowOf(j) == rowOf(i) ||
            colOf(j) == colOf(i) ||
            boxOf(j) == boxOf(i)) {
          if (seen.add(j)) result[i].add(j);
        }
      }
    }
    return result;
  }

  // ---- Solving (backtracking) ------------------------------------------

  /// Returns a full solution, or null if unsolvable. Does not mutate [grid].
  List<int>? solve(List<int> grid) {
    final work = List<int>.from(grid);
    return _backtrack(work) ? work : null;
  }

  bool _backtrack(List<int> g) {
    final cell = _findBestCell(g);
    if (cell == -1) return true; // solved
    if (cell == -2) return false; // a cell has no candidates
    for (final d in _candidates(g, cell)) {
      g[cell] = d;
      if (_backtrack(g)) return true;
      g[cell] = 0;
    }
    return false;
  }

  /// Picks the empty cell with the fewest candidates (MRV heuristic).
  /// Returns -1 if no empty cell, -2 if some empty cell has 0 candidates.
  int _findBestCell(List<int> g) {
    var best = -1;
    var bestCount = 10;
    for (var i = 0; i < 81; i++) {
      if (g[i] != 0) continue;
      final c = _candidates(g, i).length;
      if (c == 0) return -2;
      if (c < bestCount) {
        bestCount = c;
        best = i;
        if (c == 1) break;
      }
    }
    return best;
  }

  List<int> _candidates(List<int> g, int cell) {
    final used = <int>{};
    for (final p in peers[cell]) {
      if (g[p] != 0) used.add(g[p]);
    }
    final out = <int>[];
    for (var d = 1; d <= 9; d++) {
      if (!used.contains(d)) out.add(d);
    }
    return out;
  }

  /// Counts solutions up to [limit] (default 2 → just tests uniqueness).
  int countSolutions(List<int> grid, {int limit = 2}) {
    final work = List<int>.from(grid);
    var count = 0;
    void rec() {
      if (count >= limit) return;
      final cell = _findBestCell(work);
      if (cell == -1) {
        count++;
        return;
      }
      if (cell == -2) return;
      for (final d in _candidates(work, cell)) {
        work[cell] = d;
        rec();
        work[cell] = 0;
        if (count >= limit) return;
      }
    }

    rec();
    return count;
  }

  bool hasUniqueSolution(List<int> grid) => countSolutions(grid, limit: 2) == 1;

  // ---- Full-grid generation --------------------------------------------

  List<int> _generateFullGrid() {
    final g = List<int>.filled(81, 0);
    _fillRandom(g);
    return g;
  }

  bool _fillRandom(List<int> g) {
    final cell = _findBestCell(g);
    if (cell == -1) return true;
    if (cell == -2) return false;
    final cands = _candidates(g, cell)..shuffle(_rng);
    for (final d in cands) {
      g[cell] = d;
      if (_fillRandom(g)) return true;
      g[cell] = 0;
    }
    return false;
  }

  // ---- Puzzle generation ------------------------------------------------

  /// Generates a puzzle at (or near) the requested [difficulty].
  ///
  /// Strategy: build a full grid, then dig holes (symmetrically) while
  /// keeping the solution unique. Rate the result; retry a bounded number
  /// of times to hit the target band. Always returns a valid unique puzzle.
  Puzzle generate(Difficulty difficulty) {
    Puzzle? closest;
    var closestDist = 999;

    for (var attempt = 0; attempt < 14; attempt++) {
      final solution = _generateFullGrid();
      final givens = _dig(solution, difficulty);
      final rated = rate(givens);
      final dist = (rated.index - difficulty.index).abs();
      if (rated == difficulty) {
        return Puzzle(givens, solution, rated);
      }
      if (dist < closestDist) {
        closestDist = dist;
        closest = Puzzle(givens, solution, rated);
      }
    }
    return closest!;
  }

  /// Lower bound on givens we won't dig below, per difficulty band.
  int _minGivens(Difficulty d) => switch (d) {
        Difficulty.easy => 40,
        Difficulty.medium => 32,
        Difficulty.hard => 28,
        Difficulty.expert => 24,
      };

  List<int> _dig(List<int> solution, Difficulty target) {
    final puzzle = List<int>.from(solution);
    final positions = List<int>.generate(81, (i) => i)..shuffle(_rng);
    final minGivens = _minGivens(target);
    var given = 81;

    for (final pos in positions) {
      if (given <= minGivens) break;
      // Dig symmetrically (180°) for a classic look, when possible.
      final mirror = 80 - pos;
      final cells = (mirror == pos) ? [pos] : [pos, mirror];
      if (cells.any((c) => puzzle[c] == 0)) continue;

      final backup = {for (final c in cells) c: puzzle[c]};
      for (final c in cells) {
        puzzle[c] = 0;
      }
      if (hasUniqueSolution(puzzle)) {
        given -= cells.length;
      } else {
        backup.forEach((c, v) => puzzle[c] = v); // restore
      }
    }
    return puzzle;
  }

  // ---- Difficulty rating (human techniques) ----------------------------

  /// Rates a puzzle by the hardest technique a logical solver needs.
  /// Falls back to backtracking-implied difficulty if logic stalls.
  Difficulty rate(List<int> givens) {
    final cands = _initCandidates(givens);
    final grid = List<int>.from(givens);
    var hardest = 0; // 0 none, 1 naked/hidden single, 2 locked, 3 pairs, 4 guess

    while (grid.contains(0)) {
      if (_applyNakedSingle(grid, cands) ||
          _applyHiddenSingle(grid, cands)) {
        hardest = max(hardest, 1);
        continue;
      }
      if (_applyLockedCandidates(cands)) {
        hardest = max(hardest, 2);
        continue;
      }
      if (_applyNakedPair(cands)) {
        hardest = max(hardest, 3);
        continue;
      }
      hardest = 4; // needs guessing / advanced chains
      break;
    }

    return switch (hardest) {
      <= 1 => Difficulty.easy,
      2 => Difficulty.medium,
      3 => Difficulty.hard,
      _ => Difficulty.expert,
    };
  }

  List<Set<int>> _initCandidates(List<int> grid) {
    final cands = List.generate(81, (_) => <int>{});
    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      final used = <int>{};
      for (final p in peers[i]) {
        if (grid[p] != 0) used.add(grid[p]);
      }
      for (var d = 1; d <= 9; d++) {
        if (!used.contains(d)) cands[i].add(d);
      }
    }
    return cands;
  }

  bool _assign(List<int> grid, List<Set<int>> cands, int cell, int digit) {
    grid[cell] = digit;
    cands[cell].clear();
    for (final p in peers[cell]) {
      cands[p].remove(digit);
    }
    return true;
  }

  bool _applyNakedSingle(List<int> grid, List<Set<int>> cands) {
    for (var i = 0; i < 81; i++) {
      if (grid[i] == 0 && cands[i].length == 1) {
        return _assign(grid, cands, i, cands[i].first);
      }
    }
    return false;
  }

  bool _applyHiddenSingle(List<int> grid, List<Set<int>> cands) {
    for (final unit in _units) {
      for (var d = 1; d <= 9; d++) {
        var spot = -1;
        var count = 0;
        for (final c in unit) {
          if (grid[c] == 0 && cands[c].contains(d)) {
            spot = c;
            count++;
          }
        }
        if (count == 1) return _assign(grid, cands, spot, d);
      }
    }
    return false;
  }

  /// Locked candidates (pointing/claiming): if a digit in a box is confined
  /// to one line, eliminate it from the rest of that line, and vice versa.
  bool _applyLockedCandidates(List<Set<int>> cands) {
    var changed = false;
    for (final box in _boxes) {
      for (var d = 1; d <= 9; d++) {
        final spots = box.where((c) => cands[c].contains(d)).toList();
        if (spots.isEmpty) continue;
        if (spots.every((c) => rowOf(c) == rowOf(spots.first))) {
          for (final c in _rows[rowOf(spots.first)]) {
            if (boxOf(c) != boxOf(spots.first) && cands[c].remove(d)) {
              changed = true;
            }
          }
        }
        if (spots.every((c) => colOf(c) == colOf(spots.first))) {
          for (final c in _cols[colOf(spots.first)]) {
            if (boxOf(c) != boxOf(spots.first) && cands[c].remove(d)) {
              changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// Naked pair: two cells in a unit sharing the same two candidates remove
  /// those candidates from the rest of the unit.
  bool _applyNakedPair(List<Set<int>> cands) {
    var changed = false;
    for (final unit in _units) {
      final pairs = unit.where((c) => cands[c].length == 2).toList();
      for (var a = 0; a < pairs.length; a++) {
        for (var b = a + 1; b < pairs.length; b++) {
          if (_setEq(cands[pairs[a]], cands[pairs[b]])) {
            final pair = cands[pairs[a]];
            for (final c in unit) {
              if (c != pairs[a] && c != pairs[b]) {
                for (final d in pair) {
                  if (cands[c].remove(d)) changed = true;
                }
              }
            }
          }
        }
      }
    }
    return changed;
  }

  static bool _setEq(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  // ---- Units (rows, cols, boxes) ---------------------------------------

  static final List<List<int>> _rows =
      List.generate(9, (r) => List.generate(9, (c) => r * 9 + c));
  static final List<List<int>> _cols =
      List.generate(9, (c) => List.generate(9, (r) => r * 9 + c));
  static final List<List<int>> _boxes = List.generate(9, (b) {
    final br = (b ~/ 3) * 3, bc = (b % 3) * 3;
    return [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) (br + r) * 9 + (bc + c)
    ];
  });
  static final List<List<int>> _units = [..._rows, ..._cols, ..._boxes];
}
