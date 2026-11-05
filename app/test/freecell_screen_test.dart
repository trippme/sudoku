import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/freecell/freecell_game.dart';
import 'package:sudoku_app/games/freecell/freecell_screen.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';

class _RecordingBoard extends NullLeaderboard {
  final submitted = <int>[];
  final finished = <int>[];

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
    submitted.add(gameId);
    return SubmitOutcome(improved: true, rank: 1, total: 3);
  }

  @override
  Future<void> notifyFinish({
    required String email,
    required String name,
    required int gameId,
    required int seconds,
    required int hints,
  }) async {
    finished.add(gameId);
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('select a card, move it to a free cell, then undo',
      (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: FreeCellScreen(persist: false, initialDeal: 1),
    ));
    expect(find.text('FreeCell #1'), findsOneWidget);
    expect(find.textContaining('Moves: 0'), findsOneWidget);

    // Column 0 of deal #1 has 7 cards; tap the last (index 6), then a cell.
    await tester.tap(find.byKey(const Key('fc-card-0-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('fc-cell-0')));
    await tester.pump();
    expect(find.textContaining('Moves: 1'), findsOneWidget);
    expect(find.byKey(const Key('fc-card-0-6')), findsNothing);

    await tester.tap(find.byKey(const Key('fc-undo')));
    await tester.pump();
    expect(find.textContaining('Moves: 0'), findsOneWidget);
    expect(find.byKey(const Key('fc-card-0-6')), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // dispose the clock timer
  });

  testWidgets('winning submits the result under the FreeCell game id',
      (tester) async {
    _bigScreen(tester);
    final board = _RecordingBoard();
    final profile = Profile(name: 'Tripp', email: 'tripp@example.com');

    // One move from done: only the K♠ remains, with all other suits complete.
    final game = FreeCellGame(
      deal: 617,
      columns: [
        [const PlayingCard(12, Suit.spades)],
        ...List.generate(7, (_) => <PlayingCard>[]),
      ],
      cells: List<PlayingCard?>.filled(4, null),
      foundations: [13, 13, 13, 12],
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<Profile>.value(value: profile),
        Provider<LeaderboardService>.value(value: board),
      ],
      child: MaterialApp(
        home: FreeCellScreen(persist: false, initialGame: game),
      ),
    ));

    await tester.tap(find.byKey(const Key('fc-card-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('fc-found-3')));
    await tester.pump(); // move
    await tester.pump(); // post-frame win dialog
    await tester.pump();

    expect(find.text('You won! 🎉'), findsOneWidget);
    expect(board.submitted, [GameRef.freecell(617).id]);
    expect(board.finished, [GameRef.freecell(617).id]);
    expect(find.textContaining('Rank #1 of 3'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
