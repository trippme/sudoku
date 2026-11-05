import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';

/// Builds a game from rows given top-to-bottom as strings of colour digits,
/// e.g. ['01', '11'] is two columns: col0 bottom→top = 1,0 ; col1 = 1,1.
BubbleGame board(List<String> rowsTopFirst, {int width = 10}) {
  final h = rowsTopFirst.length;
  final cols = List.generate(width, (_) => <Bubble>[]);
  var id = 0;
  for (var r = h - 1; r >= 0; r--) {
    final row = rowsTopFirst[r];
    for (var c = 0; c < row.length; c++) {
      if (row[c] != '.') cols[c].add(Bubble(id++, int.parse(row[c])));
    }
  }
  return BubbleGame(deal: 1, columns: cols);
}

void main() {
  group('deal', () {
    test('is deterministic and full', () {
      final a = BubbleGame.deal(42);
      final b = BubbleGame.deal(42);
      expect(a.toJson().toString(), b.toJson().toString());
      expect(a.columns.length, 10);
      expect(a.columns.every((c) => c.length == 12), isTrue);
      expect(a.remaining, 120);
      final colors = a.columns.expand((c) => c).map((x) => x.color).toSet();
      expect(colors.length, 5);
      expect(BubbleGame.deal(43).toJson().toString(),
          isNot(a.toJson().toString()));
    });
  });

  group('groups and popping', () {
    test('a lone bubble is not poppable', () {
      final g = board(['01']);
      expect(g.groupAt(0, 0), isEmpty);
      expect(g.pop(0, 0), 0);
      expect(g.score, 0);
    });

    test('connects only orthogonally', () {
      // col0 = [1], col1 = [0, 1]: the 1s at (0,0) and (1,1) only touch
      // diagonally.
      final g = board(['.1', '10']);
      expect(g.groupAt(0, 0), isEmpty);
      expect(g.hasMoves, isFalse);
      expect(g.over, isTrue);
    });

    test('pop scores n*(n-1), drops bubbles and removes the group', () {
      final g = board([
        '2.',
        '11',
        '02',
      ]);
      // col0 bottom→top: 0,1,2   col1: 2,1
      expect(g.groupAt(0, 1).length, 2); // the two 1s
      expect(g.pop(0, 1), 2);
      expect(g.score, 2);
      expect(g.moves, 1);
      expect(g.columns[0].map((b) => b.color), [0, 2]); // 2 fell onto the 0
      expect(g.columns[1].map((b) => b.color), [2]);
    });

    test('empty columns slide left', () {
      final g = board(['1.1', '1.1'], width: 5);
      // col0 = [1,1]; col1 empty; col2 = [1,1]
      g.pop(0, 0);
      expect(g.columns[0].map((b) => b.color), [1, 1]); // old col2 moved over
      expect(g.columns[1], isEmpty);
      expect(g.columns.length, g.width); // padded with empties
    });

    test('bigger groups score more and the order of popping is by id', () {
      final g = board(['111', '111']);
      expect(g.groupAt(0, 0).length, 6);
      expect(BubbleGame.pointsFor(6), 30);
      g.pop(0, 0);
      expect(g.score, 30 + BubbleGame.clearBonus);
      expect(g.cleared, isTrue);
      expect(g.over, isTrue);
    });

    test('game continues while a group remains and ends when none do', () {
      final g = board(['0121', '0343'], width: 4);
      expect(g.hasMoves, isTrue);
      g.pop(0, 0); // the two 0s
      expect(g.over, isTrue);
      expect(g.cleared, isFalse);
    });

    test('json round trip keeps ids and colours', () {
      final g = BubbleGame.deal(9);
      g.pop(0, 0);
      final r = BubbleGame.fromJson(g.toJson());
      expect(r.toJson().toString(), g.toJson().toString());
    });
  });

  group('sizes and fixed mode', () {
    test('each size deals the right dimensions', () {
      for (final size in BubbleSize.values) {
        final g = BubbleGame.deal(7, size: size);
        expect(g.columns.length, size.width);
        expect(g.columns.every((c) => c.length == size.height), isTrue);
        expect(g.remaining, size.width * size.height);
      }
      expect(BubbleSize.small.width * BubbleSize.small.height,
          lessThan(BubbleSize.medium.width * BubbleSize.medium.height));
      expect(BubbleSize.large.width * BubbleSize.large.height,
          greaterThan(BubbleSize.medium.width * BubbleSize.medium.height));
      expect(BubbleSize.xlarge.width * BubbleSize.xlarge.height,
          greaterThan(BubbleSize.large.width * BubbleSize.large.height));
      // The enum order is baked into leaderboard ids: never reorder it.
      expect(BubbleSize.values.map((s) => s.name),
          ['medium', 'small', 'large', 'xlarge']);
    });

    test('the same number gives different boards at different sizes', () {
      expect(BubbleGame.deal(7, size: BubbleSize.small).toJson().toString(),
          isNot(BubbleGame.deal(7).toJson().toString()));
    });

    test('collapse mode closes the gap; fixed mode leaves it', () {
      BubbleGame make(bool collapse) {
        final g = BubbleGame(
          deal: 1,
          collapse: collapse,
          columns: [
            [const Bubble(0, 1), const Bubble(1, 1)], // col 0: a pair
            [const Bubble(2, 2)], // col 1 (will be left of the gap)
            [const Bubble(3, 3), const Bubble(4, 3)], // col 2: a pair
            ...List.generate(7, (_) => <Bubble>[]),
          ],
        );
        return g;
      }

      final c = make(true)..pop(2, 0);
      expect(c.columns[0].length, 2);
      expect(c.columns[1].length, 1);
      expect(c.columns[2], isEmpty); // closed up: nothing in the middle

      final f = make(false)..pop(0, 0); // empty the FIRST column
      expect(f.columns[0], isEmpty);
      expect(f.columns[1].length, 1); // column 1 did NOT slide into slot 0
      expect(f.columns[2].length, 2);
      expect(f.columns.length, 10);
    });

    test('in fixed mode bubbles still fall within their column', () {
      final g = BubbleGame(
        deal: 1,
        collapse: false,
        columns: [
          [const Bubble(0, 0), const Bubble(1, 1), const Bubble(2, 1),
           const Bubble(3, 2)],
          ...List.generate(9, (_) => <Bubble>[]),
        ],
      );
      g.pop(0, 1); // the two 1s
      expect(g.columns[0].map((b) => b.color), [0, 2]);
    });

    test('empty columns do not join groups across the gap (fixed)', () {
      final g = BubbleGame(
        deal: 1,
        collapse: false,
        columns: [
          [const Bubble(0, 4)],
          <Bubble>[],
          [const Bubble(1, 4)],
          ...List.generate(7, (_) => <Bubble>[]),
        ],
      );
      expect(g.groupAt(0, 0), isEmpty);
      expect(g.hasMoves, isFalse);
    });

    test('options survive a save, and old saves default to medium/collapse', () {
      final g = BubbleGame.deal(3, size: BubbleSize.large, collapse: false);
      final r = BubbleGame.fromJson(g.toJson());
      expect((r.size, r.collapse, r.variant), (BubbleSize.large, false, 5));

      final old = g.toJson()
        ..remove('size')
        ..remove('collapse');
      final d = BubbleGame.fromJson(
          BubbleGame.deal(3).toJson()..remove('size')..remove('collapse'));
      expect((d.size, d.collapse, d.variant), (BubbleSize.medium, true, 0));
      expect(old.containsKey('size'), isFalse);
    });

    test('variant mapping round trips', () {
      for (var v = 0; v < 24; v++) {
        final g = BubbleGame.deal(1,
            size: BubbleGame.sizeOfVariant(v),
            level: BubbleGame.levelOfVariant(v),
            collapse: BubbleGame.collapseOfVariant(v));
        expect(g.variant, v);
      }
      // Normal level keeps the original 0..7 variants.
      expect(BubbleGame.deal(1).variant, 0);
      expect(BubbleGame.deal(1, size: BubbleSize.xlarge, collapse: false).variant,
          7);
    });
  });

  group('levels, undo and stats', () {
    test('level sets how many colours are in play', () {
      for (final level in BubbleLevel.values) {
        final g = BubbleGame.deal(11, level: level);
        final used = g.columns.expand((c) => c).map((b) => b.color).toSet();
        expect(used.length, level.colors);
        expect(used.every((c) => c < level.colors), isTrue);
        expect(g.colors, level.colors);
        expect(g.colorCounts().length, level.colors);
        expect(g.colorCounts().fold(0, (a, b) => a + b), g.remaining);
      }
      expect(BubbleLevel.easy.colors, lessThan(BubbleLevel.normal.colors));
      expect(BubbleLevel.hard.colors, greaterThan(BubbleLevel.normal.colors));
      // Enum order is baked into leaderboard ids: never reorder it.
      expect(BubbleLevel.values.map((l) => l.name), ['normal', 'easy', 'hard']);
    });

    test('the same board number differs between levels', () {
      expect(BubbleGame.deal(7, level: BubbleLevel.hard).toJson().toString(),
          isNot(BubbleGame.deal(7).toJson().toString()));
    });

    test('colour counts follow pops', () {
      final g = board(['11', '22'], width: 10);
      expect(g.colorCounts().sublist(0, 3), [0, 2, 2]);
      g.pop(0, 0);
      expect(g.colorCounts().sublist(0, 3), [0, 2, 0]);
    });

    test('undo restores bubbles, score, taps and best pop', () {
      final g = BubbleGame.deal(21);
      final before = g.toJson().toString();
      expect(g.canUndo, isFalse);
      g.undo(); // harmless when empty
      expect(g.toJson().toString(), before);

      final spot = _firstGroup(g);
      g.pop(spot.$1, spot.$2);
      expect(g.canUndo, isTrue);
      expect(g.score, greaterThan(0));
      expect(g.bestPop, g.score);
      g.undo();
      expect(g.toJson().toString(), before);
      expect((g.score, g.moves, g.bestPop), (0, 0, 0));
      expect(g.canUndo, isFalse);
    });

    test('undo steps back through several pops', () {
      final g = BubbleGame.deal(33);
      final start = g.toJson().toString();
      var pops = 0;
      while (pops < 3 && g.hasMoves) {
        final s = _firstGroup(g);
        g.pop(s.$1, s.$2);
        pops++;
      }
      expect(g.moves, pops);
      for (var i = 0; i < pops; i++) {
        g.undo();
      }
      expect(g.toJson().toString(), start);
    });

    test('bestPop tracks the largest single pop', () {
      final g = board(['111', '122'], width: 10);
      g.pop(2, 0); // the pair of 2s: 2 points
      expect(g.bestPop, 2);
      g.pop(0, 0); // now the 1s that remain
      expect(g.bestPop, greaterThanOrEqualTo(2));
      expect(g.score, greaterThanOrEqualTo(g.bestPop));
    });

    test('level and bestPop survive a save', () {
      final g = BubbleGame.deal(3, level: BubbleLevel.hard);
      final s = _firstGroup(g);
      g.pop(s.$1, s.$2);
      final r = BubbleGame.fromJson(g.toJson());
      expect((r.level, r.bestPop, r.moves), (BubbleLevel.hard, g.bestPop, 1));
      // Older saves have neither field.
      final old = g.toJson()
        ..remove('level')
        ..remove('bestPop');
      final o = BubbleGame.fromJson(old);
      expect((o.level, o.bestPop), (BubbleLevel.normal, 0));
    });
  });
}

/// Any (column, row) that belongs to a poppable group.
(int, int) _firstGroup(BubbleGame g) {
  for (var c = 0; c < g.columns.length; c++) {
    for (var r = 0; r < g.columns[c].length; r++) {
      if (g.groupAt(c, r).isNotEmpty) return (c, r);
    }
  }
  throw StateError('no group');
}
