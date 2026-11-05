import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';
import 'package:sudoku_app/games/solitaire/solitaire_game.dart';

PlayingCard c(int rank, Suit s) => PlayingCard(rank, s);

SolitaireGame empty({int draw = 1}) => SolitaireGame(
      deal: 0,
      drawCount: draw,
      columns: List.generate(7, (_) => <PlayingCard>[]),
      faceUp: List<int>.filled(7, 0),
      stock: [],
      waste: [],
      foundations: List<int>.filled(4, 0),
    );

void main() {
  group('deal', () {
    test('is deterministic, complete and shaped correctly', () {
      final a = SolitaireGame.deal(42);
      final b = SolitaireGame.deal(42);
      expect(a.toJson().toString(), b.toJson().toString());
      expect(a.columns.map((x) => x.length).toList(), [1, 2, 3, 4, 5, 6, 7]);
      expect(a.faceUp, [1, 1, 1, 1, 1, 1, 1]);
      expect(a.stock.length, 24);
      final all = [...a.columns.expand((x) => x), ...a.stock].map((x) => x.code);
      expect(all.toSet().length, 52);
      expect(SolitaireGame.deal(43).toJson().toString(),
          isNot(a.toJson().toString()));
    });
  });

  group('stock', () {
    test('draw 1 and 3, then recycle', () {
      final g = SolitaireGame.deal(7, drawCount: 3);
      expect(g.draw(), isTrue);
      expect(g.waste.length, 3);
      expect(g.stock.length, 21);
      for (var i = 0; i < 7; i++) {
        g.draw();
      }
      expect(g.stock, isEmpty);
      expect(g.waste.length, 24);
      final firstDrawn = g.waste.first;
      g.draw(); // recycle
      expect(g.waste, isEmpty);
      expect(g.stock.last, firstDrawn);
    });

    test('draw with nothing anywhere does nothing', () {
      expect(empty().draw(), isFalse);
    });
  });

  group('moves', () {
    test('tableau needs descending alternating colors; moving flips the card under',
        () {
      final g = empty();
      g.columns[0].addAll([c(3, Suit.clubs), c(5, Suit.spades)]); // 4♣ hidden, 6♠
      g.faceUp[0] = 1;
      g.columns[1].addAll([c(4, Suit.hearts)]); // 5♥
      g.faceUp[1] = 1;
      g.columns[2].addAll([c(4, Suit.clubs)]); // 5♣
      g.faceUp[2] = 1;
      expect(g.move(SolPile.column, 2, 1, SolPile.column, 0), isFalse);
      expect(g.move(SolPile.column, 1, 1, SolPile.column, 0), isTrue);
      expect(g.columns[0].last, c(4, Suit.hearts));
      expect(g.faceUp[0], 2);
      expect(g.columns[1], isEmpty);
    });

    test('face-down cards cannot be picked up; revealed after the card above leaves',
        () {
      final g = empty();
      g.columns[0].addAll([c(9, Suit.clubs), c(5, Suit.hearts)]);
      g.faceUp[0] = 1;
      g.columns[1].add(c(5, Suit.spades)); // 6♠
      g.faceUp[1] = 1;
      expect(g.canMove(SolPile.column, 0, 2, SolPile.column, 1), isFalse);
      expect(g.move(SolPile.column, 0, 1, SolPile.column, 1), isFalse); // 6♥ on 6♠
      g.columns[2].add(c(6, Suit.spades)); // 7♠
      g.faceUp[2] = 1;
      expect(g.move(SolPile.column, 0, 1, SolPile.column, 2), isTrue); // 6♥ on 7♠
      expect(g.faceUp[0], 1); // J♣ flipped up
    });

    test('only kings go into an empty column', () {
      final g = empty();
      g.columns[0].add(c(11, Suit.hearts)); // Q♥
      g.faceUp[0] = 1;
      g.columns[1].add(c(12, Suit.spades)); // K♠
      g.faceUp[1] = 1;
      expect(g.canMove(SolPile.column, 0, 1, SolPile.column, 2), isFalse);
      expect(g.canMove(SolPile.column, 1, 1, SolPile.column, 2), isTrue);
    });

    test('foundation builds up by suit; waste and foundation sources work', () {
      final g = empty();
      g.waste.add(c(0, Suit.hearts)); // A♥
      expect(g.move(SolPile.waste, 0, 1, SolPile.foundation), isTrue);
      g.columns[0].add(c(1, Suit.hearts)); // 2♥
      g.faceUp[0] = 1;
      expect(g.move(SolPile.column, 0, 1, SolPile.foundation), isTrue);
      expect(g.foundations[Suit.hearts.index], 2);
      // pull 2♥ back down onto a black 3
      g.columns[1].add(c(2, Suit.spades));
      g.faceUp[1] = 1;
      expect(g.move(SolPile.foundation, Suit.hearts.index, 1, SolPile.column, 1),
          isTrue);
      expect(g.foundations[Suit.hearts.index], 1);
    });

    test('undo restores everything', () {
      final g = SolitaireGame.deal(5);
      final before = g.toJson().toString();
      g.draw();
      g.undo();
      expect(g.toJson().toString(), before);
      expect(g.canUndo, isFalse);
    });

    test('autoFoundation sweeps playable cards; win detection', () {
      final g = empty();
      g.waste.add(c(0, Suit.clubs));
      g.columns[0].add(c(1, Suit.clubs));
      g.faceUp[0] = 1;
      expect(g.autoFoundation(), 2);
      expect(g.foundations[Suit.clubs.index], 2);
      for (var s = 0; s < 4; s++) {
        g.foundations[s] = 13;
      }
      expect(g.won, isTrue);
    });

    test('json round trip', () {
      final g = SolitaireGame.deal(99, drawCount: 3);
      g.draw();
      final r = SolitaireGame.fromJson(g.toJson());
      expect(r.toJson().toString(), g.toJson().toString());
    });
  });
}
