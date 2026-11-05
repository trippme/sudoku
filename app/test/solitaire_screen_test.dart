import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/solitaire/solitaire_screen.dart';

void main() {
  testWidgets('tapping the stock draws a card; undo puts it back',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: SolitaireScreen(persist: false, initialDeal: 1),
    ));
    expect(find.text('Solitaire #1'), findsOneWidget);
    expect(find.text('Moves: 0  ·  Draw 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sol-stock')));
    await tester.pump();
    expect(find.text('Moves: 1  ·  Draw 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sol-undo')));
    await tester.pump();
    expect(find.text('Moves: 0  ·  Draw 1'), findsOneWidget);
  });

  testWidgets('selecting a card then drawing from the stock is safe',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: SolitaireScreen(persist: false, initialDeal: 1),
    ));
    // Column 6 has 7 cards; only the last (index 6) is face up.
    await tester.tap(find.byKey(const Key('sol-card-6-6')));
    await tester.pump();
    // Tapping the draw pile while a card is selected doesn't crash and draws.
    await tester.tap(find.byKey(const Key('sol-stock')));
    await tester.pump();
    expect(find.text('Moves: 1  ·  Draw 1'), findsOneWidget);
  });
}
