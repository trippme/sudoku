import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  testWidgets('landing page shows version/build and an About dialog',
      (tester) async {
    final info = Future.value(PackageInfo(
      appName: "Tripp's Games",
      packageName: 'net.whimsicle.sudoku_app',
      version: '1.2.3',
      buildNumber: '87',
    ));
    await tester.pumpWidget(MaterialApp(
      home: GamePicker(
        games: [
          GameDefinition(
            id: 'a',
            name: 'Game A',
            tagline: 'tag a',
            icon: Icons.casino,
            color: Colors.red,
            buildHome: (_) => const Scaffold(),
          ),
        ],
        packageInfo: info,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('v1.2.3 (build 87)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('about-button')));
    await tester.pumpAndSettle();
    expect(find.text("Tripp's Games"), findsWidgets);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('87'), findsOneWidget);
    expect(find.text('Commit'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);
  });
}
