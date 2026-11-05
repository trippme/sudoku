import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_screen.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';

class _RecordingBoard extends NullLeaderboard {
  final submitted = <({int gameId, int hints, int seconds})>[];

  @override
  Future<SubmitOutcome?> submitResult({
    required int gameId,
    required String email,
    required String name,
    required int seconds,
    required int hints,
    required int mistakes,
    required int difficulty,
  }) async {
    submitted.add((gameId: gameId, hints: hints, seconds: seconds));
    return SubmitOutcome(improved: true, rank: 2, total: 5);
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// A board with one poppable pair of colour-1 bubbles in column 0 plus a
/// lone bubble in column 1, so popping the pair ends the game (not cleared).
BubbleGame smallBoard({bool lone = true}) => BubbleGame(
      deal: 55,
      columns: [
        [const Bubble(0, 1), const Bubble(1, 1)],
        if (lone) [const Bubble(2, 3)] else <Bubble>[],
        ...List.generate(8, (_) => <Bubble>[]),
      ],
    );

Widget withProviders(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider<Profile>.value(value: Profile()),
        Provider<LeaderboardService>.value(value: NullLeaderboard()),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  testWidgets('first tap highlights a group, second tap pops it',
      (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(withProviders(
      BubbleScreen(persist: false, initialGame: smallBoard()),
    ));
    expect(find.textContaining('Score: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bb-0-0')));
    await tester.pump();
    expect(find.textContaining('2 bubbles = 2 points'), findsOneWidget);
    expect(find.textContaining('Score: 0'), findsOneWidget); // not popped yet

    await tester.tap(find.byKey(const Key('bb-0-0')));
    await tester.pump();
    expect(find.textContaining('Score: 2'), findsOneWidget);
    expect(find.byKey(const Key('bb-0-0')), findsOneWidget); // lone one slid over
    await tester.pump(const Duration(seconds: 1)); // bubbles settle
    expect(find.text('No more moves'), findsOneWidget); // only a lone bubble left
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a lone bubble does nothing', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(withProviders(
      BubbleScreen(persist: false, initialGame: smallBoard()),
    ));
    await tester.tap(find.byKey(const Key('bb-1-0')));
    await tester.pump();
    expect(find.textContaining('Score: 0'), findsOneWidget);
    expect(find.textContaining('bubbles ='), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('finishing submits the score under the Bubble Breaker id',
      (tester) async {
    _bigScreen(tester);
    final board = _RecordingBoard();
    final profile = Profile(name: 'Tripp', email: 'tripp@example.com');
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<Profile>.value(value: profile),
        Provider<LeaderboardService>.value(value: board),
      ],
      child: MaterialApp(
        home: BubbleScreen(persist: false, initialGame: smallBoard(lone: false)),
      ),
    ));
    await tester.tap(find.byKey(const Key('bb-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bb-0-0')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // bubbles settle, dialog opens
    await tester.pump();

    // 2 bubbles = 2 points + 1000 for clearing the board.
    expect(find.text('Board cleared! 🎉'), findsOneWidget);
    expect(board.submitted.length, 1);
    expect(board.submitted.single.gameId, GameRef.bubble(55).id);
    expect(GameRef.scoreFromHints(board.submitted.single.hints), 1002);
    expect(find.textContaining('Rank #2 of 5'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
