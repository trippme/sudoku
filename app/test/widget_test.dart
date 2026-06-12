import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku_app/engine/sudoku_engine.dart';

void main() {
  test('generated puzzles are unique and solvable for every difficulty', () {
    // Fixed seed → deterministic test.
    final engine = SudokuEngine(42);
    for (final d in Difficulty.values) {
      final puzzle = engine.generate(d);
      // Solution must be a valid full grid that matches the givens.
      for (var i = 0; i < 81; i++) {
        expect(puzzle.solution[i], inInclusiveRange(1, 9));
        if (puzzle.givens[i] != 0) {
          expect(puzzle.givens[i], puzzle.solution[i]);
        }
      }
      // Puzzle must have exactly one solution.
      expect(engine.hasUniqueSolution(puzzle.givens), isTrue);
    }
  });

  test('solver solves a known puzzle', () {
    final engine = SudokuEngine(1);
    // A well-known easy puzzle.
    const p =
        '530070000600195000098000060800060003400803001700020006060000280000419005000080079';
    final grid = p.split('').map(int.parse).toList();
    final solved = engine.solve(grid);
    expect(solved, isNotNull);
    // Check rows contain 1..9.
    for (var r = 0; r < 9; r++) {
      final row = {for (var c = 0; c < 9; c++) solved![r * 9 + c]};
      expect(row, {1, 2, 3, 4, 5, 6, 7, 8, 9});
    }
  });
}
