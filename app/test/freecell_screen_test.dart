import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/freecell/freecell_screen.dart';

void main() {
  testWidgets('select a card, move it to a free cell, then undo',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: FreeCellScreen(persist: false, initialDeal: 1),
    ));
    expect(find.text('FreeCell #1'), findsOneWidget);
    expect(find.text('Moves: 0'), findsOneWidget);

    // Column 0 of deal #1 has 7 cards; tap the last (index 6), then a cell.
    await tester.tap(find.byKey(const Key('fc-card-0-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('fc-cell-0')));
    await tester.pump();
    expect(find.text('Moves: 1'), findsOneWidget);
    expect(find.byKey(const Key('fc-card-0-6')), findsNothing);

    await tester.tap(find.byKey(const Key('fc-undo')));
    await tester.pump();
    expect(find.text('Moves: 0'), findsOneWidget);
    expect(find.byKey(const Key('fc-card-0-6')), findsOneWidget);
  });
}
