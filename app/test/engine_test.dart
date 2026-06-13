import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/engine/sudoku_engine.dart';
import 'package:sudoku_app/engine/hint_engine.dart';
import 'package:sudoku_app/services/game_catalog.dart';

void main() {
  group('generator', () {
    test('produces unique, solvable puzzles for every difficulty', () {
      final engine = SudokuEngine(42);
      for (final d in Difficulty.values) {
        final puzzle = engine.generate(d);
        for (var i = 0; i < 81; i++) {
          expect(puzzle.solution[i], inInclusiveRange(1, 9));
          if (puzzle.givens[i] != 0) {
            expect(puzzle.givens[i], puzzle.solution[i]);
          }
        }
        expect(engine.hasUniqueSolution(puzzle.givens), isTrue);
      }
    });
  });

  group('solver', () {
    test('solves a known puzzle with valid rows', () {
      final engine = SudokuEngine(1);
      const p =
          '530070000600195000098000060800060003400803001700020006060000280000419005000080079';
      final grid = p.split('').map(int.parse).toList();
      final solved = engine.solve(grid)!;
      for (var r = 0; r < 9; r++) {
        final row = {for (var c = 0; c < 9; c++) solved[r * 9 + c]};
        expect(row, {1, 2, 3, 4, 5, 6, 7, 8, 9});
      }
    });
  });

  group('hint engine', () {
    test('finds a naked single', () {
      // Take a full solution and blank one cell → it's a naked single.
      final engine = SudokuEngine(7);
      final puzzle = engine.generate(Difficulty.easy);
      // Take the solution, blank exactly one cell → that cell is a naked single.
      final g = List<int>.from(puzzle.solution);
      g[40] = 0;
      final hint = HintEngine.nextHint(g);
      expect(hint, isNotNull);
      expect(hint!.placements.first.cell, 40);
      expect(hint.placements.first.digit, puzzle.solution[40]);
    });

    test('returns null on a full grid', () {
      final engine = SudokuEngine(3);
      final full = engine.solve(List<int>.filled(81, 0))!;
      expect(HintEngine.nextHint(full), isNull);
    });

    test('every generated easy puzzle is progressable by hints alone', () {
      // Solve an easy puzzle purely by repeatedly applying hints.
      final engine = SudokuEngine(11);
      final puzzle = engine.generate(Difficulty.easy);
      final grid = List<int>.from(puzzle.givens);
      var guard = 0;
      while (grid.contains(0) && guard++ < 200) {
        final hint = HintEngine.nextHint(grid);
        if (hint == null) break;
        for (final pl in hint.placements) {
          grid[pl.cell] = pl.digit;
        }
        // Elimination-only hints don't change values; break if no placement
        // and we'd loop. For easy puzzles singles should always appear.
        if (hint.placements.isEmpty) break;
      }
      // Easy puzzles are defined as solvable with singles, so this should be
      // fully solved.
      expect(grid.contains(0), isFalse);
      expect(grid, puzzle.solution);
    });
  });

  group('game catalog', () {
    Puzzle daily(DateTime d) =>
        GameCatalog.puzzleForGame(GameCatalog.dailyGameId(d));

    test('a game number is deterministic', () {
      final a = GameCatalog.puzzleForGame(1234);
      final b = GameCatalog.puzzleForGame(1234);
      expect(a.givens, b.givens);
      expect(a.solution, b.solution);
    });

    test('different numbers give different puzzles', () {
      expect(GameCatalog.puzzleForGame(1234).givens,
          isNot(GameCatalog.puzzleForGame(1235).givens));
    });

    test('a random game id matches its requested difficulty band', () {
      for (final d in Difficulty.values) {
        final id = GameCatalog.randomGameId(d);
        expect(id % Difficulty.values.length, d.index);
      }
    });

    test('daily is deterministic per date and varies across dates', () {
      final a = daily(DateTime(2026, 6, 11));
      final b = daily(DateTime(2026, 6, 11));
      expect(a.givens, b.givens);
      expect(daily(DateTime(2026, 6, 12)).givens, isNot(a.givens));
    });
  });
}
