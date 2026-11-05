import 'package:flutter/material.dart';
import 'package:sudoku_app/games/bubble/bubble_prefs.dart';

/// Fully saturated colours, spread around the colour wheel so no two are easy
/// to confuse. Order matters: Easy plays with the first four (blue, red, green,
/// yellow: the most distinct), Normal adds purple, Hard adds orange.
const List<Color> kBubbleColors = [
  Color(0xFF1E88FF), // blue
  Color(0xFFFF1F3D), // red
  Color(0xFF00E04E), // green
  Color(0xFFFFE000), // yellow
  Color(0xFFC21BFF), // purple
  Color(0xFFFF8A00), // orange
];

/// One shape per colour (Shapes theme), so colours never rely on hue alone.
const List<IconData> kBubbleGlyphs = [
  Icons.nightlight_round, // blue: crescent
  Icons.star_rounded, // red: star
  Icons.change_history_rounded, // green: triangle
  Icons.radio_button_unchecked, // gold: ring
  Icons.diamond_rounded, // purple: gem
  Icons.favorite_rounded, // orange: heart
];

/// The dark, high-contrast theme used by the Bubble Breaker screens.
ThemeData bubbleTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF16181B)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// A glossy bubble of [color] (index into [kBubbleColors]).
class BubbleView extends StatelessWidget {
  final int color;
  final double size;
  final BubbleTheme theme;
  const BubbleView({
    super.key,
    required this.color,
    required this.size,
    this.theme = BubbleTheme.shapes,
  });

  @override
  Widget build(BuildContext context) {
    final base = kBubbleColors[color % kBubbleColors.length];
    final glyph = kBubbleGlyphs[color % kBubbleGlyphs.length];
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.45),
                  radius: 0.95,
                  colors: [
                    Color.lerp(base, Colors.white, 0.6)!,
                    base,
                    Color.lerp(base, Colors.black, 0.16)!,
                  ],
                  stops: const [0, 0.55, 1],
                ),
                border: Border.all(
                  color: Color.lerp(base, Colors.black, 0.35)!,
                  width: size * 0.04,
                ),
                boxShadow: [
                  // A soft glow in the bubble's own colour makes it stand off
                  // the black board.
                  BoxShadow(
                    color: base.withValues(alpha: 0.45),
                    blurRadius: size * 0.16,
                  ),
                ],
              ),
              child: SizedBox.expand(),
            ),
            if (theme == BubbleTheme.shapes)
              Icon(glyph,
                  size: size * 0.52, color: Colors.white.withValues(alpha: 0.92)),
            // Gloss.
            Positioned(
              left: size * 0.2,
              top: size * 0.12,
              child: Container(
                width: size * 0.32,
                height: size * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  color: Colors.white.withValues(alpha: 0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a green outline around a group of cells (only its outer edges).
class GroupOutlinePainter extends CustomPainter {
  final List<(int, int)> cells; // (column, row-from-bottom)
  final int rows;
  final double cell;
  GroupOutlinePainter(this.cells, this.rows, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    final inGroup = {for (final (c, r) in cells) c * 1000 + r};
    final paint = Paint()
      ..color = const Color(0xFF39FF14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (c, r) in cells) {
      final left = c * cell;
      final top = (rows - 1 - r) * cell;
      final right = left + cell;
      final bottom = top + cell;
      const inset = 1.0;
      if (!inGroup.contains((c - 1) * 1000 + r)) {
        canvas.drawLine(
            Offset(left + inset, top), Offset(left + inset, bottom), paint);
      }
      if (!inGroup.contains((c + 1) * 1000 + r)) {
        canvas.drawLine(
            Offset(right - inset, top), Offset(right - inset, bottom), paint);
      }
      if (!inGroup.contains(c * 1000 + r + 1)) {
        canvas.drawLine(
            Offset(left, top + inset), Offset(right, top + inset), paint);
      }
      if (!inGroup.contains(c * 1000 + r - 1)) {
        canvas.drawLine(
            Offset(left, bottom - inset), Offset(right, bottom - inset), paint);
      }
    }
  }

  @override
  bool shouldRepaint(GroupOutlinePainter old) =>
      old.cells != cells || old.rows != rows || old.cell != cell;
}
