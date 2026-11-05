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
      expect(g.columns.length, BubbleGame.numColumns); // padded with empties
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
}
