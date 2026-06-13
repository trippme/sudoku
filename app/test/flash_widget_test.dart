import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/models/stats.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/models/game_state.dart';
import 'package:sudoku_app/engine/sudoku_engine.dart';
import 'package:sudoku_app/ui/sudoku_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  Color? cellColor(WidgetTester tester, int index) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(ValueKey('cell-$index')),
        matching: find.byType(Container),
      ),
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  // True when the cell's colour is green-dominant (the flash tint), which the
  // static yellow highlight never is.
  bool greenDominant(Color? c) {
    if (c == null) return false;
    final argb = c.toARGB32();
    final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
    return g > r && g > b;
  }

  testWidgets('completing a digit flashes its cells green', (tester) async {
    final settings = Settings(inputMode: InputMode.hybrid);
    final stats = Stats.load();
    final game = GameState(
      settings: settings,
      stats: stats,
      profile: Profile(),
      leaderboard: NullLeaderboard(),
    )..newGame(Difficulty.easy);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: game),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 400, height: 400, child: SudokuGrid())),
        ),
      ),
    );

    // Pick the digit that needs the fewest placements and one of its cells.
    const target = 1;
    final cells = [
      for (var i = 0; i < 81; i++)
        if (game.solution[i] == target && !game.cells[i].given) i
    ];
    final sampleCell = cells.first;

    // Before completion, the cell is not green.
    expect(greenDominant(cellColor(tester, sampleCell)), isFalse);

    // Arm the digit once, fill all of it.
    game.pressDigit(target);
    for (final i in cells) {
      game.pressCell(i);
    }

    // Model side fired the digit-completion event.
    expect(game.flashSerial, greaterThan(0), reason: 'completion event fired');
    expect(game.flashKind, FlashKind.digit);
    expect(game.flashCells.contains(sampleCell), isTrue);

    await tester.pump(); // rebuild → schedules the flash on the next frame

    // Scan the animation: at some frame the cell becomes green-dominant.
    var sawGreen = false;
    for (var t = 0; t < 30; t++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (greenDominant(cellColor(tester, sampleCell))) sawGreen = true;
    }
    expect(sawGreen, isTrue, reason: 'completed digit should flash green');

    // After the animation completes, the flash clears (back to non-green).
    await tester.pump(const Duration(milliseconds: 800));
    expect(greenDominant(cellColor(tester, sampleCell)), isFalse);

    game.dispose(); // stop the periodic play-clock timer before the test ends
  });
}
