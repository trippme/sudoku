import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/game_definition.dart';
import 'package:sudoku_app/ui/game_picker.dart';

void main() {
  testWidgets('picker lists games and opens the tapped one', (tester) async {
    final games = [
      GameDefinition(
        id: 'a',
        name: 'Game A',
        tagline: 'tag a',
        icon: Icons.casino,
        color: Colors.red,
        buildHome: (_) => const Scaffold(body: Text('A home')),
      ),
      GameDefinition(
        id: 'b',
        name: 'Game B',
        tagline: 'tag b',
        icon: Icons.style,
        color: Colors.green,
        buildHome: (_) => const Scaffold(body: Text('B home')),
      ),
    ];
    await tester.pumpWidget(MaterialApp(home: GamePicker(games: games)));
    expect(find.text("Tripp's Games"), findsOneWidget);
    expect(find.text('Game A'), findsOneWidget);
    expect(find.text('Game B'), findsOneWidget);

    await tester.tap(find.byKey(const Key('game-b')));
    await tester.pumpAndSettle();
    expect(find.text('B home'), findsOneWidget);
  });
}
