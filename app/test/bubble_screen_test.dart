import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_prefs.dart';
import 'package:sudoku_app/games/bubble/bubble_screen.dart';
import 'package:sudoku_app/games/bubble/bubble_widgets.dart';
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
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget withProviders(Widget home,
        {LeaderboardService? board, Profile? profile}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Profile>.value(value: profile ?? Profile()),
        Provider<LeaderboardService>.value(value: board ?? NullLeaderboard()),
      ],
      child: MaterialApp(home: home),
    );

int scoreOf(WidgetTester tester) =>
    int.parse(tester.widget<Text>(find.byKey(const Key('bb-score'))).data!);

String countOf(WidgetTester tester, int i) => tester
    .widget<Text>(find.descendant(
        of: find.byKey(Key('bb-count-$i')), matching: find.byType(Text)))
    .data!;

/// A pair of colour-1 bubbles in column 0 plus (optionally) a lone bubble in
/// column 1, so popping the pair leaves a lone bubble (game over, not cleared)
/// or nothing at all (cleared).
BubbleGame smallBoard({bool lone = true}) => BubbleGame(
      deal: 55,
      columns: [
        [const Bubble(0, 1), const Bubble(1, 1)],
        if (lone) [const Bubble(2, 3)] else <Bubble>[],
        ...List.generate(8, (_) => <Bubble>[]),
      ],
    );

/// Two separate pairs so a pop leaves the game running.
BubbleGame twoPairs() => BubbleGame(
      deal: 56,
      columns: [
        [const Bubble(0, 1), const Bubble(1, 1)],
        [const Bubble(2, 3), const Bubble(3, 3)],
        ...List.generate(8, (_) => <Bubble>[]),
      ],
    );

Future<void> openOptions(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bb-options')));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> popPair(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bb-0-0')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('bb-0-0')));
  await tester.pump();
}

void main() {
  group('look', () {
    testWidgets('first tap outlines the group and shows its score, second pops',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: twoPairs()),
      ));
      expect(scoreOf(tester), 0);
      expect(find.byKey(const Key('bb-badge')), findsNothing);

      await tester.tap(find.byKey(const Key('bb-0-0')));
      await tester.pump();
      expect(find.byKey(const Key('bb-badge')), findsOneWidget);
      expect(find.textContaining('2 bubbles = 2 points'), findsOneWidget);
      expect(scoreOf(tester), 0); // not popped yet

      await tester.tap(find.byKey(const Key('bb-0-0')));
      await tester.pump();
      expect(scoreOf(tester), 2);
      expect(find.byKey(const Key('bb-badge')), findsNothing);
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
      expect(scoreOf(tester), 0);
      expect(find.byKey(const Key('bb-badge')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('colour counts sit under the board and follow the game',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: twoPairs()),
      ));
      expect(countOf(tester, 1), '2');
      expect(countOf(tester, 3), '2');
      expect(countOf(tester, 0), '0');
      final style = tester
          .widget<Text>(find.descendant(
              of: find.byKey(const Key('bb-count-1')),
              matching: find.byType(Text)))
          .style!;
      expect(style.color, kBubbleColors[1]);

      await popPair(tester);
      expect(countOf(tester, 1), '0');
      expect(countOf(tester, 3), '2');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the Shapes theme draws a glyph per colour, Round does not',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(
            persist: false,
            initialGame: twoPairs(),
            prefs: BubblePrefs(theme: BubbleTheme.shapes)),
      ));
      expect(find.byIcon(kBubbleGlyphs[1]), findsWidgets);
      await tester.pumpWidget(withProviders(
        BubbleScreen(
            key: UniqueKey(),
            persist: false,
            initialGame: twoPairs(),
            prefs: BubblePrefs(theme: BubbleTheme.round)),
      ));
      expect(find.byIcon(kBubbleGlyphs[1]), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('popped bubbles burst away unless the animation is off',
        (tester) async {
      _bigScreen(tester);
      for (final disappear in [true, false]) {
        await tester.pumpWidget(withProviders(
          BubbleScreen(
              key: UniqueKey(),
              persist: false,
              initialGame: twoPairs(),
              prefs: BubblePrefs(disappear: disappear, motion: true)),
        ));
        await popPair(tester);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const ValueKey('ghost-0')),
            disappear ? findsOneWidget : findsNothing);
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('bubble motion off means bubbles snap into place',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(
            persist: false,
            initialGame: twoPairs(),
            prefs: BubblePrefs(motion: false)),
      ));
      final durations = tester
          .widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned))
          .map((p) => p.duration)
          .toSet();
      expect(durations, {Duration.zero});
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('play', () {
    testWidgets('Auto Eliminate pops on the first tap', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(
            persist: false,
            initialGame: twoPairs(),
            prefs: BubblePrefs(autoEliminate: true)),
      ));
      await tester.tap(find.byKey(const Key('bb-0-0')));
      await tester.pump();
      expect(scoreOf(tester), 2);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undo takes back the last pop', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: twoPairs()),
      ));
      IconButton undo() =>
          tester.widget<IconButton>(find.byKey(const Key('bb-undo')));
      expect(undo().onPressed, isNull); // nothing to undo yet

      await popPair(tester);
      expect(scoreOf(tester), 2);
      expect(undo().onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('bb-undo')));
      await tester.pump();
      expect(scoreOf(tester), 0);
      expect(undo().onPressed, isNull);
      expect(find.byKey(const Key('bb-0-1')), findsOneWidget); // bubbles are back
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('game over', () {
    testWidgets('no moves left shows the statistics sheet', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: smallBoard()),
      ));
      await popPair(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // sheet finishes sliding in

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.text('Game Statistic'), findsOneWidget);
      expect(find.text('rows*cols*types: 12*10*5'), findsOneWidget);
      expect(find.text('Mode: Standard'), findsOneWidget);
      expect(find.text('Final score: 2'), findsOneWidget);
      expect(find.text('Tap count: 1'), findsOneWidget);
      expect(find.text('Largest single score: 2'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Restart deals a fresh board', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: smallBoard()),
      ));
      await popPair(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // sheet finishes sliding in
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(scoreOf(tester), 0);
      expect(find.byKey(const Key('bb-9-11')), findsOneWidget); // full 10x12
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('finishing submits the score under the Bubble Breaker id',
        (tester) async {
      _bigScreen(tester);
      final board = _RecordingBoard();
      final profile = Profile(name: 'Tripp', email: 'tripp@example.com');
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: smallBoard(lone: false)),
        board: board,
        profile: profile,
      ));
      await popPair(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // sheet finishes sliding in

      // 2 bubbles = 2 points + 1000 for clearing the board.
      expect(find.text('Board cleared! 🎉'), findsOneWidget);
      expect(board.submitted.length, 1);
      expect(board.submitted.single.gameId, GameRef.bubble(55).id);
      expect(GameRef.scoreFromHints(board.submitted.single.hints), 1002);
      expect(find.textContaining('Rank #2 of 5'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the score goes to the leaderboard of its level/size/mode',
        (tester) async {
      _bigScreen(tester);
      final board = _RecordingBoard();
      final profile = Profile(name: 'Tripp', email: 'tripp@example.com');
      final game = BubbleGame(
        deal: 55,
        size: BubbleSize.small,
        level: BubbleLevel.hard,
        collapse: false,
        columns: [
          [const Bubble(0, 1), const Bubble(1, 1)],
          ...List.generate(7, (_) => <Bubble>[]),
        ],
      );
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: game),
        board: board,
        profile: profile,
      ));
      await popPair(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // sheet finishes sliding in
      // hard (2) × 4 + small (1) = 9, ×2 + fixed = 19
      expect(game.variant, 19);
      expect(board.submitted.single.gameId, GameRef.bubble(55, variant: 19).id);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('options', () {
    testWidgets('size, level and mode apply to the next board', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        const BubbleScreen(persist: false, initialDeal: 12),
      ));
      expect(find.byKey(const Key('bb-9-0')), findsOneWidget); // medium: 10 wide
      expect(find.byKey(const Key('bb-10-0')), findsNothing);

      await openOptions(tester);
      expect(find.text('Game Sound Settings'), findsOneWidget);
      expect(find.text('Game UI Effect Settings'), findsOneWidget);
      expect(find.text('Bubble Appearance'), findsOneWidget);
      expect(find.text('Bubble Size Setting'), findsOneWidget);
      expect(find.text('Game Settings'), findsOneWidget);

      await tapVisible(tester, const Key('opt-size-small'));
      await tapVisible(tester, const Key('opt-level'));
      await tester.tap(find.text('Easy (4 colours)'));
      await tester.pumpAndSettle();
      await tapVisible(tester, const Key('opt-mode'));
      await tester.tap(find.text('Fixed').last);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Start a new board?'), findsOneWidget);
      await tester.tap(find.text('New board'));
      await tester.pumpAndSettle();

      // Small 8×10, Easy = 4 colours, Fixed.
      expect(find.byKey(const Key('bb-7-9')), findsOneWidget);
      expect(find.byKey(const Key('bb-8-0')), findsNothing);
      expect(find.byKey(const Key('bb-count-3')), findsOneWidget);
      expect(find.byKey(const Key('bb-count-4')), findsNothing);
      expect(find.textContaining('Fixed'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('X-Large and Hard are offered (14×16, six colours)',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        const BubbleScreen(persist: false, initialDeal: 12),
      ));
      await openOptions(tester);
      await tapVisible(tester, const Key('opt-size-xlarge'));
      await tapVisible(tester, const Key('opt-level'));
      await tester.tap(find.text('Hard (6 colours)'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('New board'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bb-13-15')), findsOneWidget);
      expect(find.byKey(const Key('bb-14-0')), findsNothing);
      expect(find.byKey(const Key('bb-count-5')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('look and behaviour options apply at once, no new board',
        (tester) async {
      _bigScreen(tester);
      final prefs = BubblePrefs();
      await tester.pumpWidget(withProviders(
        BubbleScreen(persist: false, initialGame: twoPairs(), prefs: prefs),
      ));
      expect(find.byIcon(kBubbleGlyphs[1]), findsWidgets);

      await openOptions(tester);
      await tapVisible(tester, const Key('opt-theme-round'));
      await tapVisible(tester, const Key('opt-auto'));
      await tapVisible(tester, const Key('opt-motion'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Start a new board?'), findsNothing);
      expect(prefs.theme, BubbleTheme.round);
      expect(prefs.autoEliminate, isTrue);
      expect(prefs.motion, isFalse);
      // The board in play is untouched, and now drawn without glyphs.
      expect(find.byKey(const Key('bb-0-0')), findsOneWidget);
      expect(find.byIcon(kBubbleGlyphs[1]), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a challenge opens with its own size, level and mode',
        (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(withProviders(
        const BubbleScreen(persist: false, initialDeal: 5, initialVariant: 4),
      ));
      // Variant 4 = normal level, large (12 × 14), collapsing.
      expect(find.byKey(const Key('bb-11-13')), findsOneWidget);
      expect(find.byKey(const Key('bb-12-0')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
