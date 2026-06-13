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
import 'package:sudoku_app/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('finishing a game shows the completion popup with stats',
      (tester) async {
    final settings = Settings(inputMode: InputMode.cellThenDigit);
    final stats = Stats.load();
    final profile = Profile();
    final game = GameState(
      settings: settings,
      stats: stats,
      profile: profile,
      leaderboard: NullLeaderboard(),
    )..newGame(Difficulty.easy);
    addTearDown(game.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: stats),
          ChangeNotifierProvider.value(value: profile),
          Provider<LeaderboardService>.value(value: NullLeaderboard()),
          ChangeNotifierProvider.value(value: game),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );

    expect(game.isSolved, isFalse);

    // Fill every empty cell with the correct digit (cell-then-digit mode).
    for (var i = 0; i < 81; i++) {
      if (!game.cells[i].given) {
        game.pressCell(i);
        game.pressDigit(game.solution[i]);
      }
    }
    expect(game.isSolved, isTrue);

    await tester.pump(); // solved → schedules the popup
    await tester.pump(); // popup route appears

    // "🎉 Solved!" appears both in the popup and the control-pad banner.
    expect(find.text('🎉 Solved!'), findsWidgets);
    // These are unique to the completion popup.
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Mistakes'), findsOneWidget);
    expect(find.text('Back to menu'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
