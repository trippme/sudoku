import 'sudoku_engine.dart';

/// A single human-solving deduction, with an explanation the player can learn
/// from. Either places a digit, eliminates candidates, or both.
class Hint {
  final String technique; // e.g. "Hidden Single"
  final String explanation; // human-readable "why"
  final List<({int cell, int digit})> placements; // digits to write
  final List<({int cell, int digit})> eliminations; // marks to remove
  final List<int> highlight; // cells to emphasise in the UI

  Hint({
    required this.technique,
    required this.explanation,
    this.placements = const [],
    this.eliminations = const [],
    this.highlight = const [],
  });
}

/// Computes the next logical hint for a board, mirroring the techniques used by
/// the difficulty rater. Operates on the current filled values (it derives
/// candidates itself, so it is not fooled by the player's pencil marks).
class HintEngine {
  /// Returns the next deduction, or null if no supported technique applies.
  static Hint? nextHint(List<int> grid) {
    final cands = _candidates(grid);

    return _nakedSingle(grid, cands) ??
        _hiddenSingle(grid, cands) ??
        _lockedCandidates(cands) ??
        _nakedPair(cands);
  }

  // ---- Human-friendly coordinate naming --------------------------------

  static String _cellName(int i) =>
      'R${SudokuEngine.rowOf(i) + 1}C${SudokuEngine.colOf(i) + 1}';
  static String _rowName(int i) => 'row ${SudokuEngine.rowOf(i) + 1}';
  static String _colName(int i) => 'column ${SudokuEngine.colOf(i) + 1}';
  static String _boxName(int i) => 'box ${SudokuEngine.boxOf(i) + 1}';

  // ---- Candidate computation -------------------------------------------

  static List<Set<int>> _candidates(List<int> grid) {
    final cands = List.generate(81, (_) => <int>{});
    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      final used = <int>{};
      for (final p in SudokuEngine.peers[i]) {
        if (grid[p] != 0) used.add(grid[p]);
      }
      for (var d = 1; d <= 9; d++) {
        if (!used.contains(d)) cands[i].add(d);
      }
    }
    return cands;
  }

  // ---- Techniques -------------------------------------------------------

  static Hint? _nakedSingle(List<int> grid, List<Set<int>> cands) {
    for (var i = 0; i < 81; i++) {
      if (grid[i] == 0 && cands[i].length == 1) {
        final d = cands[i].first;
        return Hint(
          technique: 'Naked Single',
          explanation:
              '${_cellName(i)} can only be $d — every other digit already '
              'appears in its row, column, or box.',
          placements: [(cell: i, digit: d)],
          highlight: [i],
        );
      }
    }
    return null;
  }

  static Hint? _hiddenSingle(List<int> grid, List<Set<int>> cands) {
    for (final (label, units) in [
      ('row', _rows),
      ('column', _cols),
      ('box', _boxes),
    ]) {
      for (final unit in units) {
        for (var d = 1; d <= 9; d++) {
          var spot = -1, count = 0;
          for (final c in unit) {
            if (grid[c] == 0 && cands[c].contains(d)) {
              spot = c;
              count++;
            }
          }
          if (count == 1) {
            final houseName = switch (label) {
              'row' => _rowName(spot),
              'column' => _colName(spot),
              _ => _boxName(spot),
            };
            return Hint(
              technique: 'Hidden Single',
              explanation:
                  '$d can go in only one cell of $houseName: ${_cellName(spot)}. '
                  'So that cell must be $d.',
              placements: [(cell: spot, digit: d)],
              highlight: [spot, ...unit],
            );
          }
        }
      }
    }
    return null;
  }

  static Hint? _lockedCandidates(List<Set<int>> cands) {
    for (final box in _boxes) {
      for (var d = 1; d <= 9; d++) {
        final spots = box.where((c) => cands[c].contains(d)).toList();
        if (spots.length < 2) continue;

        // Pointing: all candidates in the box share a row → clear that row.
        if (spots.every((c) => SudokuEngine.rowOf(c) == SudokuEngine.rowOf(spots.first))) {
          final elim = <({int cell, int digit})>[];
          for (final c in _rows[SudokuEngine.rowOf(spots.first)]) {
            if (SudokuEngine.boxOf(c) != SudokuEngine.boxOf(spots.first) &&
                cands[c].contains(d)) {
              elim.add((cell: c, digit: d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              technique: 'Locked Candidate (Pointing)',
              explanation:
                  'In ${_boxName(spots.first)}, $d only fits along ${_rowName(spots.first)}. '
                  'So $d can be removed from the rest of that row.',
              eliminations: elim,
              highlight: spots,
            );
          }
        }
        // Pointing along a column.
        if (spots.every((c) => SudokuEngine.colOf(c) == SudokuEngine.colOf(spots.first))) {
          final elim = <({int cell, int digit})>[];
          for (final c in _cols[SudokuEngine.colOf(spots.first)]) {
            if (SudokuEngine.boxOf(c) != SudokuEngine.boxOf(spots.first) &&
                cands[c].contains(d)) {
              elim.add((cell: c, digit: d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              technique: 'Locked Candidate (Pointing)',
              explanation:
                  'In ${_boxName(spots.first)}, $d only fits along ${_colName(spots.first)}. '
                  'So $d can be removed from the rest of that column.',
              eliminations: elim,
              highlight: spots,
            );
          }
        }
      }
    }
    return null;
  }

  static Hint? _nakedPair(List<Set<int>> cands) {
    for (final (label, units) in [
      ('row', _rows),
      ('column', _cols),
      ('box', _boxes),
    ]) {
      for (final unit in units) {
        final twos = unit.where((c) => cands[c].length == 2).toList();
        for (var a = 0; a < twos.length; a++) {
          for (var b = a + 1; b < twos.length; b++) {
            if (_setEq(cands[twos[a]], cands[twos[b]])) {
              final pair = cands[twos[a]].toList()..sort();
              final elim = <({int cell, int digit})>[];
              for (final c in unit) {
                if (c == twos[a] || c == twos[b]) continue;
                for (final d in pair) {
                  if (cands[c].contains(d)) elim.add((cell: c, digit: d));
                }
              }
              if (elim.isNotEmpty) {
                final houseName = switch (label) {
                  'row' => _rowName(twos[a]),
                  'column' => _colName(twos[a]),
                  _ => _boxName(twos[a]),
                };
                return Hint(
                  technique: 'Naked Pair',
                  explanation:
                      '${_cellName(twos[a])} and ${_cellName(twos[b])} in $houseName both '
                      'hold only ${pair[0]} and ${pair[1]}. Those two digits are locked to '
                      'those cells, so they can be removed from the rest of the $label.',
                  eliminations: elim,
                  highlight: [twos[a], twos[b]],
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  static bool _setEq(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  // ---- Units ------------------------------------------------------------

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
}
