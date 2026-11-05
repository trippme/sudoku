import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/freecell/freecell_game.dart';

PlayingCard c(int rank, Suit s) => PlayingCard(rank, s);

FreeCellGame empty() => FreeCellGame(
      deal: 0,
      columns: List.generate(8, (_) => <PlayingCard>[]),
      cells: List<PlayingCard?>.filled(4, null),
      foundations: List<int>.filled(4, 0),
    );

void main() {
  group('deal', () {
    test('is deterministic and uses all 52 cards once', () {
      final a = FreeCellGame.deal(1234);
      final b = FreeCellGame.deal(1234);
      expect(a.toJson().toString(), b.toJson().toString());
      final all = a.columns.expand((x) => x).map((x) => x.code).toSet();
      expect(all.length, 52);
      expect(a.columns.map((x) => x.length).toList(),
          [7, 7, 7, 7, 6, 6, 6, 6]);
      expect(FreeCellGame.deal(1235).toJson().toString(),
          isNot(a.toJson().toString()));
    });

    test('matches the classic Microsoft deal #1', () {
      // Top row of deal #1 across the eight columns.
      final row = FreeCellGame.deal(1).columns.map((x) => x[0].label).toList();
      expect(row, ['J♦', '2♦', '9♥', 'J♣', '5♦', '7♥', '7♣', '5♥']);
    });
  });

  group('moves', () {
    test('tableau needs descending alternating colors', () {
      final g = empty();
      g.columns[0].add(c(6, Suit.spades)); // 7♠
      g.columns[1].add(c(5, Suit.hearts)); // 6♥
      g.columns[2].add(c(5, Suit.clubs)); // 6♣
      expect(g.move(Pile.column, 2, 1, Pile.column, 0), isFalse);
      expect(g.move(Pile.column, 1, 1, Pile.column, 0), isTrue);
      expect(g.columns[0].map((x) => x.label), ['7♠', '6♥']);
    });

    test('free cells hold one card and fill up', () {
      final g = empty();
      for (var i = 0; i < 5; i++) {
        g.columns[i].add(c(i + 3, Suit.clubs));
      }
      for (var i = 0; i < 4; i++) {
        expect(g.move(Pile.column, i, 1, Pile.cell, i), isTrue);
      }
      expect(g.emptyCells, 0);
      expect(g.move(Pile.column, 4, 1, Pile.cell, 0), isFalse);
    });

    test('foundation takes Ace first, then in order', () {
      final g = empty();
      g.columns[0]..add(c(1, Suit.hearts))..add(c(0, Suit.hearts));
      expect(g.toFoundation(Pile.column, 0), isTrue); // A♥
      expect(g.toFoundation(Pile.column, 0), isTrue); // 2♥
      expect(g.foundations[Suit.hearts.index], 2);
      g.columns[1].add(c(3, Suit.hearts));
      expect(g.toFoundation(Pile.column, 1), isFalse); // 4♥ before 3♥
    });

    test('supermove limit is enforced', () {
      final g = empty();
      // Column 0: 9♠ 8♥ 7♣ (valid 3-card run); cells all full, no empty cols.
      g.columns[0].addAll([c(8, Suit.spades), c(7, Suit.hearts), c(6, Suit.clubs)]);
      g.columns[1].add(c(9, Suit.hearts)); // 10♥
      for (var i = 2; i < 8; i++) {
        g.columns[i].add(c(12, Suit.clubs));
      }
      for (var i = 0; i < 4; i++) {
        g.cells[i] = c(12, Suit.diamonds);
      }
      expect(g.maxMovable(), 1);
      expect(g.canMove(Pile.column, 0, 3, Pile.column, 1), isFalse);
      g.cells[0] = null;
      g.cells[1] = null; // 3 free cells -> 4 cards
      expect(g.canMove(Pile.column, 0, 3, Pile.column, 1), isTrue);
    });

    test('undo restores the previous position', () {
      final g = FreeCellGame.deal(1);
      final before = g.toJson().toString();
      final moved = g.move(Pile.column, 0, 1, Pile.cell, 0);
      expect(moved, isTrue);
      expect(g.canUndo, isTrue);
      g.undo();
      expect(g.toJson().toString(), before);
      expect(g.canUndo, isFalse);
    });

    test('autoFoundation moves safe cards only', () {
      final g = empty();
      g.columns[0]..add(c(2, Suit.spades))..add(c(1, Suit.clubs))..add(c(0, Suit.hearts));
      g.columns[1].add(c(0, Suit.spades));
      final n = g.autoFoundation();
      expect(n, greaterThanOrEqualTo(2)); // both aces
      expect(g.foundations[Suit.hearts.index], 1);
      expect(g.foundations[Suit.spades.index], 1);
    });

    test('win detection and stuck detection', () {
      final g = empty();
      for (var s = 0; s < 4; s++) {
        g.foundations[s] = 13;
      }
      expect(g.won, isTrue);
      expect(g.stuck, isFalse);

      final s = empty();
      // Fill cells and columns with unrelated cards so nothing can move.
      for (var i = 0; i < 4; i++) {
        s.cells[i] = c(12, Suit.values[i]);
      }
      for (var i = 0; i < 8; i++) {
        s.columns[i].add(c(11 - (i % 2), i.isEven ? Suit.clubs : Suit.spades));
      }
      expect(s.stuck, isTrue);
    });

    test('json round trip', () {
      final g = FreeCellGame.deal(99);
      g.move(Pile.column, 0, 1, Pile.cell, 2);
      final r = FreeCellGame.fromJson(g.toJson());
      expect(r.toJson().toString(), g.toJson().toString());
    });
  });

  group('tap-to-play', () {
    test('prefers foundation, then a matching column, then a free cell', () {
      final g = empty();
      g.columns[0].addAll([c(5, Suit.hearts), c(0, Suit.spades)]); // 6♥, A♠
      g.columns[1].add(c(6, Suit.clubs)); // 7♣
      g.columns[2].add(c(9, Suit.clubs));
      expect(g.bestDestination(Pile.column, 0, 1)!.pile, Pile.foundation);
      g.toFoundation(Pile.column, 0);
      final d = g.bestDestination(Pile.column, 0, 1)!; // 6♥ onto 7♣
      expect((d.pile, d.index), (Pile.column, 1));
      final cell = g.bestDestination(Pile.column, 2, 1)!; // 10♣ has no home
      expect((cell.pile, cell.index), (Pile.cell, 0));
    });

    test('a lone base card does not bounce to an empty column', () {
      final g = empty();
      g.columns[0].add(c(9, Suit.clubs));
      for (var i = 0; i < 4; i++) {
        g.cells[i] = c(12, Suit.diamonds);
      }
      expect(g.bestDestination(Pile.column, 0, 1), isNull);
      g.columns[1].addAll([c(8, Suit.clubs), c(3, Suit.hearts)]);
      final d = g.bestDestination(Pile.column, 1, 1)!; // cells full -> empty col
      expect(d.pile, Pile.column);
      expect(g.columns[d.index], isEmpty);
    });

    test('stacks only go onto a matching column', () {
      final g = empty();
      g.columns[0].addAll([c(6, Suit.spades), c(5, Suit.hearts)]); // 7♠ 6♥
      g.columns[1].add(c(7, Suit.hearts)); // 8♥
      g.columns[2].add(c(0, Suit.clubs));
      expect(g.bestDestination(Pile.column, 0, 2)!.index, 1);
      expect(g.bestDestination(Pile.column, 2, 2), isNull);
    });

    test('play sweeps safe cards and undoes as a single step', () {
      final g = empty();
      g.columns[0].addAll([c(0, Suit.hearts), c(5, Suit.clubs)]); // A♥ under 6♣
      g.columns[1].addAll([c(0, Suit.spades), c(9, Suit.diamonds)]); // A♠ under 10♦
      final before = g.toJson().toString();
      expect(g.play(Pile.column, 0, 1, Pile.cell, 0), isTrue); // 6♣ -> cell
      expect(g.foundations[Suit.hearts.index], 1); // A♥ swept up
      expect(g.foundations[Suit.spades.index], 0); // A♠ still buried
      expect(g.moves, 2);
      g.undo();
      expect(g.toJson().toString(), before);
    });
  });
}
