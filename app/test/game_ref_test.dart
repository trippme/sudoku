import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/game_ref.dart';

void main() {
  test('sudoku ids pass through unchanged', () {
    for (final id in [0, 5, 1234, 80000003, 999999999]) {
      final r = GameRef.decode(id);
      expect(r.kind, GameKind.sudoku);
      expect(r.id, id);
      expect(r.usesHints, isTrue);
    }
  });

  test('freecell and solitaire round trip, including range edges', () {
    for (final deal in [1, 617, 1000000]) {
      final f = GameRef.decode(GameRef.freecell(deal).id);
      expect((f.kind, f.deal), (GameKind.freecell, deal));
      for (final draw in [1, 3]) {
        final s = GameRef.decode(GameRef.solitaire(deal, draw: draw).id);
        expect((s.kind, s.deal, s.draw), (GameKind.solitaire, deal, draw));
      }
    }
  });

  test('ids never collide across games and fit a 32-bit signed int', () {
    final ids = {
      GameRef.freecell(1000000).id,
      GameRef.solitaire(1000000, draw: 1).id,
      GameRef.solitaire(1000000, draw: 3).id,
      GameRef.freecell(1).id,
      GameRef.solitaire(1, draw: 1).id,
      GameRef.solitaire(1, draw: 3).id,
    };
    expect(ids.length, 6);
    expect(ids.every((i) => i < 2147483647), isTrue);
  });

  test('labels', () {
    expect(GameRef.freecell(617).label, 'FreeCell #617');
    expect(GameRef.solitaire(42, draw: 3).label, 'Solitaire #42 (draw 3)');
    expect(GameRef.sudoku(8123).label, 'Sudoku #8123');
    expect(GameRef.freecell(617).usesHints, isFalse);
  });
}
