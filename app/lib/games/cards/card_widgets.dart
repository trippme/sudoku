import 'package:flutter/material.dart';
import 'package:sudoku_app/games/cards/playing_card.dart';

/// Card height as a multiple of its width.
const double kCardAspect = 1.4;

/// A face-up playing card of the given [width].
class PlayingCardView extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final bool selected;
  const PlayingCardView({
    super.key,
    required this.card,
    required this.width,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? Colors.red.shade700 : Colors.black87;
    return Container(
      width: width,
      height: width * kCardAspect,
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        color: selected ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(
          color: selected ? Colors.amber.shade800 : Colors.black45,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            card.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// A face-down card of the given [width].
class CardBackView extends StatelessWidget {
  final double width;
  const CardBackView({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * kCardAspect,
      decoration: BoxDecoration(
        color: Colors.indigo.shade400,
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(color: Colors.indigo.shade900, width: 1),
      ),
      child: Center(
        child: Icon(Icons.grid_4x4,
            size: width * 0.5, color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }
}

/// An empty pile outline, optionally with a faint [hint] (e.g. a suit symbol).
class EmptySlot extends StatelessWidget {
  final double width;
  final String? hint;
  const EmptySlot({super.key, required this.width, this.hint});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline;
    return Container(
      width: width,
      height: width * kCardAspect,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(color: c, width: 1.5),
      ),
      child: hint == null
          ? null
          : Text(hint!,
              style: TextStyle(
                  fontSize: width * 0.5, color: c.withValues(alpha: 0.6))),
    );
  }
}
