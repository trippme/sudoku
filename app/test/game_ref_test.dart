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

  test('bubble breaker ids, labels and score encoding', () {
    for (final deal in [1, 99, 1000000]) {
      final b = GameRef.decode(GameRef.bubble(deal).id);
      expect((b.kind, b.deal), (GameKind.bubble, deal));
    }
    expect(GameRef.bubble(5).label, 'Bubble Breaker #5');
    expect(GameRef.bubble(1000000).id, lessThan(2147483647));
    expect(GameRef.bubble(5).usesScore, isTrue);
    // A higher score must become a LOWER hints number (backend sorts hints asc).
    expect(GameRef.hintsForScore(900), lessThan(GameRef.hintsForScore(500)));
    expect(GameRef.scoreFromHints(GameRef.hintsForScore(1234)), 1234);
    expect(GameRef.hintsForScore(-5), GameRef.hintsForScore(0));
    final r = GameRef.bubble(5)
        .describeResult(seconds: 75, hints: GameRef.hintsForScore(640));
    expect((r.headline, r.detail), ('640 pts', '1:15'));
    final s = GameRef.sudoku(7).describeResult(seconds: 61, hints: 1, mistakes: 2);
    expect((s.headline, s.detail), ('1:01', '1 hint · 2 mistakes'));
  });
}
