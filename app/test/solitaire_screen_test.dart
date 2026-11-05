import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/games/solitaire/solitaire_game.dart';
import 'package:sudoku_app/games/solitaire/solitaire_screen.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';

class _RecordingBoard extends NullLeaderboard {
  final submitted = <int>[];

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
    return SubmitOutcome(improved: false, rank: 2, total: 4);
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('tapping the stock draws a card; undo puts it back',
      (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: SolitaireScreen(persist: false, initialDeal: 1),
    ));
    expect(find.text('Solitaire #1'), findsOneWidget);
    expect(find.textContaining('Moves: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sol-stock')));
    await tester.pump();
    expect(find.textContaining('Moves: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sol-undo')));
    await tester.pump();
    expect(find.textContaining('Moves: 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the clock timer
  });

  testWidgets('selecting a card then drawing from the stock is safe',
      (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: SolitaireScreen(persist: false, initialDeal: 1),
    ));
    // Column 6 has 7 cards; only the last (index 6) is face up.
    await tester.tap(find.byKey(const Key('sol-card-6-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sol-stock')));
    await tester.pump();
    expect(find.textContaining('Moves: 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('winning submits under the draw-3 Solitaire game id',
      (tester) async {
    _bigScreen(tester);
    final board = _RecordingBoard();
    final profile = Profile(name: 'Tripp', email: 'tripp@example.com');

    // One move from done: only K♠ is left, in column 0.
    final game = SolitaireGame(
      deal: 42,
      drawCount: 3,
      columns: [
        [const PlayingCard(12, Suit.spades)],
        ...List.generate(6, (_) => <PlayingCard>[]),
      ],
      faceUp: [1, 0, 0, 0, 0, 0, 0],
      stock: [],
      waste: [],
      foundations: [13, 13, 13, 12],
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<Profile>.value(value: profile),
        Provider<LeaderboardService>.value(value: board),
      ],
      child: MaterialApp(
        home: SolitaireScreen(persist: false, initialGame: game),
      ),
    ));

    await tester.tap(find.byKey(const Key('sol-card-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sol-found-3')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('You won! 🎉'), findsOneWidget);
    expect(board.submitted, [GameRef.solitaire(42, draw: 3).id]);
    expect(find.textContaining('Not your best'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
