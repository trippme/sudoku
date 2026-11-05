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

  test('bubble variants: own ids, original game keeps its ids', () {
    // Medium + collapsing is the original game: ids must not move.
    expect(GameRef.bubble(5).id, 1300000005);
    final ids = <int>{};
    for (var v = 0; v < GameRef.bubbleVariants; v++) {
      for (final deal in [1, 1000000]) {
        final ref = GameRef.bubble(deal, variant: v);
        ids.add(ref.id);
        final back = GameRef.decode(ref.id);
        expect((back.kind, back.deal, back.variant), (GameKind.bubble, deal, v));
        expect(ref.id, lessThan(2147483647));
      }
    }
    expect(GameRef.bubbleVariants, 24);
    expect(ids.length, GameRef.bubbleVariants * 2); // no collisions
    // No bubble id decodes as another game, and vice versa.
    expect(GameRef.decode(GameRef.freecell(1000000).id).kind, GameKind.freecell);
    expect(GameRef.decode(GameRef.solitaire(1000000, draw: 3).id).kind,
        GameKind.solitaire);
  });

  test('bubble variant labels', () {
    expect(GameRef.bubble(5).label, 'Bubble Breaker #5');
    expect(GameRef.bubble(5, variant: 1).label, 'Bubble Breaker #5 (fixed)');
    expect(GameRef.bubble(5, variant: 2).label, 'Bubble Breaker #5 (small)');
    expect(GameRef.bubble(5, variant: 3).label,
        'Bubble Breaker #5 (small, fixed)');
    expect(GameRef.bubble(5, variant: 4).label, 'Bubble Breaker #5 (large)');
    expect(GameRef.bubble(5, variant: 5).label,
        'Bubble Breaker #5 (large, fixed)');
    expect(GameRef.bubble(5, variant: 6).label, 'Bubble Breaker #5 (x-large)');
    expect(GameRef.bubble(5, variant: 7).label,
        'Bubble Breaker #5 (x-large, fixed)');
    // Levels come first in the label.
    expect(GameRef.bubble(5, variant: 8).label, 'Bubble Breaker #5 (easy)');
    expect(GameRef.bubble(5, variant: 9).label,
        'Bubble Breaker #5 (easy, fixed)');
    expect(GameRef.bubble(5, variant: 16).label, 'Bubble Breaker #5 (hard)');
    expect(GameRef.bubble(5, variant: 19).label,
        'Bubble Breaker #5 (hard, small, fixed)');
    expect(GameRef.bubble(5, variant: 23).label,
        'Bubble Breaker #5 (hard, x-large, fixed)');
  });
}
