import 'sudoku_engine.dart';

/// One step of a progressively-revealed hint (issue #42), mirroring the old
/// app: first nudge ("examine the digit"), then the region, then the exact cell.
/// Each stage also says what the board should highlight while it's shown.
class HintStage {
  final String text;
  final int? focusDigit; // glow every cell holding this digit (yellow)
  final List<int> house; // shade these cells (green) — the relevant region
  final int? targetCell; // the answer cell, strongly highlighted

  const HintStage(
    this.text, {
    this.focusDigit,
    this.house = const [],
    this.targetCell,
  });
}

/// A single human-solving deduction, with an explanation the player can learn
/// from. Either places a digit, eliminates candidates, or both. [stages] drives
/// the progressive reveal UI; [title] is the short difficulty word shown above it.
class Hint {
  final String technique; // e.g. "Hidden Single"
  final String explanation; // human-readable "why"
  final List<({int cell, int digit})> placements; // digits to write
  final List<({int cell, int digit})> eliminations; // marks to remove
  final List<int> highlight; // cells to emphasise in the UI
  final String title; // difficulty word for the hint panel header
  final List<HintStage> stages; // progressive reveal, vague → exact
  final int? removeCell; // a wrong entry to clear first (issue #52)

  Hint({
    required this.technique,
    required this.explanation,
    this.placements = const [],
    this.eliminations = const [],
    this.highlight = const [],
    this.title = 'Hint',
    this.stages = const [],
    this.removeCell,
  });
}

/// Computes the next logical hint for a board, mirroring the techniques used by
/// the difficulty rater. Operates on the current filled values (it derives
/// candidates itself, so it is not fooled by the player's pencil marks).
class HintEngine {
  /// Returns the next hint — always a digit you can *place* when one is logically
  /// reachable (issue #54: never end a hint run on an elimination with no number
  /// to place). Easiest-to-spot first (issue #42): a hidden single (scan a box)
  /// before a naked single.
  ///
  /// If no single is immediately visible, it quietly applies candidate
  /// eliminations (pointing, claiming, naked pairs — the same techniques the
  /// rater uses) until a cell is forced, then hints that placement honestly
  /// rather than showing an elimination the player can't act on.
  static Hint? nextHint(List<int> grid) {
    final cands = _candidates(grid);

    final direct = _hiddenSingle(grid, cands) ?? _nakedSingle(grid, cands);
    if (direct != null) return direct;

    final work = [for (final s in cands) Set<int>.of(s)];
    for (var i = 0; i < 60; i++) {
      if (!_eliminateOnce(work)) break;
      final found = _anySingleCell(grid, work);
      if (found != null) return _deducedHint(found.cell, found.digit);
    }
    return null; // needs a technique beyond this app's set (very rare here)
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
        final peers = SudokuEngine.peers[i].toList();
        return Hint(
          technique: 'Naked Single',
          title: 'Easy',
          explanation:
              '${_cellName(i)} can only be $d — every other digit already '
              'appears in its row, column, or box.',
          placements: [(cell: i, digit: d)],
          highlight: [i],
          stages: [
            HintStage('Examine the digit $d.', focusDigit: d),
            HintStage(
              'One empty cell can only be $d — its row, column, and box already '
              'contain every other digit, so nothing else fits. (A "naked '
              'single".)',
              focusDigit: d,
              house: peers,
            ),
            HintStage('Only ${_cellName(i)} can be $d.',
                focusDigit: d, house: peers, targetCell: i),
          ],
        );
      }
    }
    return null;
  }

  static Hint? _hiddenSingle(List<int> grid, List<Set<int>> cands) {
    // Box first: cross-hatching a box is the most natural way to spot a move.
    for (final (label, units) in [
      ('box', _boxes),
      ('row', _rows),
      ('column', _cols),
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
              title: 'Easy',
              explanation:
                  '$d can go in only one cell of $houseName: ${_cellName(spot)}. '
                  'So that cell must be $d.',
              placements: [(cell: spot, digit: d)],
              highlight: [spot, ...unit],
              stages: [
                HintStage('Examine the digit $d.', focusDigit: d),
                HintStage(
                  'Hidden Single ($label): where in $houseName can you put a $d?',
                  focusDigit: d,
                  house: unit,
                ),
                HintStage('Only ${_cellName(spot)} can be $d.',
                    focusDigit: d, house: unit, targetCell: spot),
              ],
            );
          }
        }
      }
    }
    return null;
  }

  /// The cell + digit of any naked or hidden single in [cands], or null.
  static ({int cell, int digit})? _anySingleCell(
      List<int> grid, List<Set<int>> cands) {
    for (var i = 0; i < 81; i++) {
      if (grid[i] == 0 && cands[i].length == 1) {
        return (cell: i, digit: cands[i].first);
      }
    }
    for (final units in [_boxes, _rows, _cols]) {
      for (final unit in units) {
        for (var d = 1; d <= 9; d++) {
          var spot = -1, count = 0;
          for (final c in unit) {
            if (grid[c] == 0 && cands[c].contains(d)) {
              spot = c;
              count++;
            }
          }
          if (count == 1) return (cell: spot, digit: d);
        }
      }
    }
    return null;
  }

  /// A placement hint for a cell that is forced only after candidate
  /// elimination — worded honestly (it doesn't claim to be a visible single).
  static Hint _deducedHint(int i, int d) => Hint(
        technique: 'Deduction',
        title: 'Tricky',
        explanation:
            '${_cellName(i)} works out to $d once you eliminate candidates '
            '(see the Solving Techniques guide).',
        placements: [(cell: i, digit: d)],
        highlight: [i],
        stages: [
          HintStage('Examine the digit $d.', focusDigit: d),
          HintStage(
            'No quick single here — but after ruling out candidates with the '
            'pencil-mark techniques, $d is forced into one cell.',
            focusDigit: d,
          ),
          HintStage('${_cellName(i)} must be $d.', focusDigit: d, targetCell: i),
        ],
      );

  /// Apply one pass of candidate eliminations (pointing, claiming, naked pairs)
  /// to [cands], mutating it. Returns true if any candidate was removed.
  static bool _eliminateOnce(List<Set<int>> cands) {
    var changed = false;

    // Pointing: within a box, a digit confined to one row/column clears the
    // rest of that line.
    for (final box in _boxes) {
      for (var d = 1; d <= 9; d++) {
        final spots = box.where((c) => cands[c].contains(d)).toList();
        if (spots.length < 2) continue;
        if (spots.every((c) => SudokuEngine.rowOf(c) == SudokuEngine.rowOf(spots.first))) {
          for (final c in _rows[SudokuEngine.rowOf(spots.first)]) {
            if (SudokuEngine.boxOf(c) != SudokuEngine.boxOf(spots.first) &&
                cands[c].remove(d)) {
              changed = true;
            }
          }
        }
        if (spots.every((c) => SudokuEngine.colOf(c) == SudokuEngine.colOf(spots.first))) {
          for (final c in _cols[SudokuEngine.colOf(spots.first)]) {
            if (SudokuEngine.boxOf(c) != SudokuEngine.boxOf(spots.first) &&
                cands[c].remove(d)) {
              changed = true;
            }
          }
        }
      }
    }

    // Claiming: within a row/column, a digit confined to one box clears the
    // rest of that box.
    for (final units in [_rows, _cols]) {
      for (final unit in units) {
        for (var d = 1; d <= 9; d++) {
          final spots = unit.where((c) => cands[c].contains(d)).toList();
          if (spots.length < 2) continue;
          if (spots.every((c) => SudokuEngine.boxOf(c) == SudokuEngine.boxOf(spots.first))) {
            for (final c in _boxes[SudokuEngine.boxOf(spots.first)]) {
              if (!unit.contains(c) && cands[c].remove(d)) changed = true;
            }
          }
        }
      }
    }

    // Naked pairs: two cells in a unit holding the same two candidates clear
    // those digits from the unit's other cells.
    for (final units in [_rows, _cols, _boxes]) {
      for (final unit in units) {
        final twos = unit.where((c) => cands[c].length == 2).toList();
        for (var a = 0; a < twos.length; a++) {
          for (var b = a + 1; b < twos.length; b++) {
            if (_setEq(cands[twos[a]], cands[twos[b]])) {
              final pair = cands[twos[a]];
              for (final c in unit) {
                if (c == twos[a] || c == twos[b]) continue;
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
