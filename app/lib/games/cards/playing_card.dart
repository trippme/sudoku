import 'package:flutter/material.dart';

/// Suits in the classic Microsoft FreeCell order (also the foundation order).
enum Suit { clubs, diamonds, hearts, spades }

extension SuitX on Suit {
  bool get isRed => this == Suit.diamonds || this == Suit.hearts;
  String get symbol => const ['♣', '♦', '♥', '♠'][index];
}

/// A standard playing card. [rank] is 0-based: 0 = Ace … 12 = King.
@immutable
class PlayingCard {
  final int rank;
  final Suit suit;
  const PlayingCard(this.rank, this.suit);

  /// Compact 0..51 code (rank * 4 + suit) used for persistence and dealing.
  int get code => rank * 4 + suit.index;
  factory PlayingCard.fromCode(int c) => PlayingCard(c ~/ 4, Suit.values[c % 4]);

  bool get isRed => suit.isRed;
  String get rankLabel => const [
        'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'
      ][rank];
  String get label => '$rankLabel${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;
  @override
  int get hashCode => code;
  @override
  String toString() => label;
}
