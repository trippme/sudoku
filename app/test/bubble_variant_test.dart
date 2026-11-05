import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_variant.dart';
import 'package:sudoku_app/games/game_ref.dart';

void main() {
  test('every level x size x mode round-trips and none collide', () {
    final seen = <int>{};
    for (var level = 0; level < BubbleLevel.values.length; level++) {
      for (var size = 0; size < BubbleSize.values.length; size++) {
        for (final fixed in [false, true]) {
          final v = encodeBubbleVariant(level: level, size: size, fixed: fixed);
          expect(v, inInclusiveRange(0, kBubbleVariantCount - 1));
          expect(seen.add(v), isTrue, reason: 'duplicate variant $v');
          final d = decodeBubbleVariant(v);
          expect((d.level, d.size, d.fixed), (level, size, fixed));
        }
      }
    }
    expect(seen.length, kBubbleVariantCount);
    expect(kBubbleVariantCount, 54);
  });

  test('boards that shipped first keep their exact variant numbers', () {
    // medium/small/large/x-large at each level, collapsing or fixed.
    for (var level = 0; level < 3; level++) {
      for (var size = 0; size < 4; size++) {
        for (final f in [0, 1]) {
          expect(
              encodeBubbleVariant(level: level, size: size, fixed: f == 1),
              (level * 4 + size) * 2 + f);
        }
      }
    }
    expect(encodeBubbleVariant(level: 0, size: 0, fixed: false), 0);
    expect(encodeBubbleVariant(level: 2, size: 1, fixed: true), 19);
  });

  test('the five classic sizes sit after the originals', () {
    expect(encodeBubbleVariant(level: 0, size: 4, fixed: false), 24);
    expect(encodeBubbleVariant(level: 2, size: 8, fixed: true), 53);
    expect(bubbleVariantUsesBigScores(23), isFalse);
    expect(bubbleVariantUsesBigScores(24), isTrue);
  });

  test('the game agrees with the scheme', () {
    for (final size in BubbleSize.values) {
      for (final level in BubbleLevel.values) {
        for (final collapse in [true, false]) {
          final g = BubbleGame.deal(1,
              size: size, level: level, collapse: collapse);
          expect(BubbleGame.sizeOfVariant(g.variant), size);
          expect(BubbleGame.levelOfVariant(g.variant), level);
          expect(BubbleGame.collapseOfVariant(g.variant), collapse);
        }
      }
    }
  });

  test('every size is on the Options list exactly once', () {
    expect(BubbleSize.displayOrder.toSet(), BubbleSize.values.toSet());
    expect(BubbleSize.displayOrder.length, BubbleSize.values.length);
  });

  test('the five classic sizes have the classic dimensions', () {
    expect((BubbleSize.standard.width, BubbleSize.standard.height), (10, 15));
    expect((BubbleSize.dense.width, BubbleSize.dense.height), (15, 22));
    expect((BubbleSize.tiny.width, BubbleSize.tiny.height), (20, 30));
    expect((BubbleSize.unified.width, BubbleSize.unified.height), (9, 16));
    expect((BubbleSize.unifiedV2.width, BubbleSize.unifiedV2.height), (13, 24));
    for (final s in [
      BubbleSize.standard,
      BubbleSize.dense,
      BubbleSize.tiny,
      BubbleSize.unified,
      BubbleSize.unifiedV2,
    ]) {
      final g = BubbleGame.deal(5, size: s);
      expect(g.columns.length, s.width);
      expect(g.columns.every((c) => c.length == s.height), isTrue);
    }
  });

  group('score storage', () {
    test('original boards keep the 100,000 ceiling (existing scores stay valid)',
        () {
      expect(GameRef.hintsForScore(640), 100000 - 640);
      expect(GameRef.scoreFromHints(100000 - 640), 640);
      expect(GameRef.hintsForScore(640, variant: 23), 100000 - 640);
    });

    test('the big boards can store scores past 100,000', () {
      const v = 53;
      for (final score in [0, 5, 99999, 100000, 250000, 359400 + 1000]) {
        final stored = GameRef.hintsForScore(score, variant: v);
        expect(GameRef.scoreFromHints(stored, variant: v), score);
      }
      // A better score is always a smaller stored number.
      expect(GameRef.hintsForScore(200000, variant: v),
          lessThan(GameRef.hintsForScore(150000, variant: v)));
      expect(GameRef.hintsForScore(200000, variant: v), lessThan(2147483647));
    });

    test('results are worded with the right ceiling', () {
      final big = GameRef.bubble(5, variant: 30);
      final r = big.describeResult(
          seconds: 75, hints: GameRef.hintsForScore(123456, variant: 30));
      expect(r.headline, '123456 pts');
      final old = GameRef.bubble(5, variant: 3);
      expect(
          old
              .describeResult(
                  seconds: 75, hints: GameRef.hintsForScore(640, variant: 3))
              .headline,
          '640 pts');
    });
  });
}
