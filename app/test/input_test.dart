import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/models/stats.dart';
import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/engine/sudoku_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  GameState makeGame(InputMode mode) {
    final game = GameState(settings: Settings(inputMode: mode), stats: Stats.load());
    game.newGame(Difficulty.easy);
    return game;
  }

  int firstEmpty(GameState g) => g.cells.indexWhere((c) => !c.given);

  group('hybrid input', () {
    test('digit-then-cell places, and re-tapping the digit removes it', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);

      g.pressDigit(5);
      expect(g.isDigitActive(5), isTrue);
      expect(g.selectionMode, 1);

      g.pressCell(cell);
      expect(g.cells[cell].value, 5); // placed
      expect(g.isDigitActive(5), isTrue); // digit stays armed

      g.pressCell(cell); // same digit on same cell → toggle off
      expect(g.cells[cell].value, 0);
    });

    test('re-tapping the armed digit deselects it', () {
      final g = makeGame(InputMode.hybrid);
      g.pressDigit(3);
      expect(g.selectionMode, 1);
      g.pressDigit(3);
      expect(g.selectionMode, 0); // neutral again
    });

    test('cell-then-digit also works in hybrid', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);
      g.pressCell(cell);
      expect(g.selectionMode, 2);
      expect(g.selectedCell, cell);
      g.pressDigit(7);
      expect(g.cells[cell].value, 7);
    });

    test('tapping the same selected cell deselects it', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);
      g.pressCell(cell);
      g.pressCell(cell);
      expect(g.selectionMode, 0);
      expect(g.selectedCell, isNull);
    });
  });

  group('erase mode', () {
    test('erase clears a placed digit', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);
      g.pressDigit(4);
      g.pressCell(cell);
      expect(g.cells[cell].value, 4);

      g.pressDigit(10); // Erase
      expect(g.isDigitActive(10), isTrue);
      g.pressCell(cell);
      expect(g.cells[cell].value, 0);
    });
  });

  group('pencil mode', () {
    test('toggles pencil marks instead of values', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);
      g.togglePencil();
      g.pressDigit(2);
      g.pressCell(cell);
      expect(g.cells[cell].value, 0);
      expect(g.cells[cell].marks.contains(2), isTrue);
      g.pressCell(cell); // toggle the mark back off
      expect(g.cells[cell].marks.contains(2), isFalse);
    });
  });

  group('cell-then-digit mode', () {
    test('starts armed for a cell and never auto-deselects', () {
      final g = makeGame(InputMode.cellThenDigit);
      expect(g.selectionMode, 2);
      final cell = firstEmpty(g);
      g.pressCell(cell);
      g.pressDigit(9);
      expect(g.cells[cell].value, 9);
      // Re-tapping a cell stays in cell mode (no hybrid toggle-off).
      g.pressCell(cell);
      expect(g.selectionMode, 2);
    });
  });

  group('armed-digit placement', () {
    test('does not select the cell (so no row/box shading)', () {
      final g = makeGame(InputMode.hybrid);
      final cell = firstEmpty(g);
      g.pressDigit(5);
      g.pressCell(cell);
      expect(g.selectedCell, isNull);
      expect(g.cells[cell].value, 5);
    });
  });

  group('group-completion flash', () {
    test('flashSerial increments when a house is completed', () {
      final g = makeGame(InputMode.hybrid);
      final before = g.flashSerial;
      // Fill row 0 with the correct solution digits, one armed digit at a time.
      for (var c = 0; c < 9; c++) {
        if (g.cells[c].given) continue;
        g.pressDigit(g.solution[c]);
        g.pressCell(c);
      }
      // Row 0 is now complete → at least one flash event fired.
      expect(g.flashSerial, greaterThan(before));
      expect(g.flashCells, isNotEmpty);
    });
  });

  group('digit-completion flash', () {
    test('flashes green (kind=digit) when all nine of a number are placed', () {
      final g = makeGame(InputMode.hybrid);
      // Arm digit 1 once, then fill every non-given cell that holds a 1.
      const target = 1;
      final before = g.flashSerial;
      g.pressDigit(target);
      for (var i = 0; i < 81; i++) {
        if (g.solution[i] == target && !g.cells[i].given) {
          g.pressCell(i);
        }
      }
      // All nine 1s now placed correctly → a digit-completion flash fired.
      expect(g.cells.where((c) => c.value == target).length, 9);
      expect(g.flashSerial, greaterThan(before));
      expect(g.flashKind, FlashKind.digit);
    });
  });

  group('highlightDigit', () {
    test('follows the armed digit', () {
      final g = makeGame(InputMode.hybrid);
      g.pressDigit(6);
      expect(g.highlightDigit, 6);
      g.pressDigit(6); // deselect
      expect(g.highlightDigit, isNull);
    });
  });

  test('given cells are never editable', () {
    final g = makeGame(InputMode.hybrid);
    final given = g.cells.indexWhere((c) => c.given);
    final original = g.cells[given].value;
    g.pressDigit(((original % 9) + 1)); // some other digit
    g.pressCell(given);
    expect(g.cells[given].value, original);
  });
}
