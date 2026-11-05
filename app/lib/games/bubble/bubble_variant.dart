/// Which leaderboard a Bubble Breaker board belongs to: level × size × mode.
///
/// Pure ints (no Flutter / game imports) so both the game and `GameRef` can
/// use it. Level and size are indexes into `BubbleLevel` / `BubbleSize`.
///
/// Sizes 0..3 (the original Small…X-Large) and the three levels use the first
/// 24 variants, exactly as they were first shipped:
///   `((level × 4) + size) × 2 + (fixed ? 1 : 0)`
/// Sizes 4..8 were added later and live after them, so no existing board's id
/// ever moves:
///   `24 + ((level × 5) + (size − 4)) × 2 + (fixed ? 1 : 0)`
library;

const int kBubbleOriginalSizes = 4;
const int kBubbleExtraSizes = 5;
const int kBubbleOriginalVariants = 3 * kBubbleOriginalSizes * 2; // 24
const int kBubbleVariantCount = kBubbleOriginalVariants + 3 * kBubbleExtraSizes * 2; // 54

int encodeBubbleVariant({
  required int level,
  required int size,
  required bool fixed,
}) {
  final f = fixed ? 1 : 0;
  if (size < kBubbleOriginalSizes) {
    return (level * kBubbleOriginalSizes + size) * 2 + f;
  }
  return kBubbleOriginalVariants +
      (level * kBubbleExtraSizes + (size - kBubbleOriginalSizes)) * 2 +
      f;
}

({int level, int size, bool fixed}) decodeBubbleVariant(int v) {
  final fixed = v.isOdd;
  if (v < kBubbleOriginalVariants) {
    final k = v ~/ 2;
    return (
      level: k ~/ kBubbleOriginalSizes,
      size: k % kBubbleOriginalSizes,
      fixed: fixed
    );
  }
  final k = (v - kBubbleOriginalVariants) ~/ 2;
  return (
    level: k ~/ kBubbleExtraSizes,
    size: kBubbleOriginalSizes + k % kBubbleExtraSizes,
    fixed: fixed
  );
}

/// Variants from here on store scores with the larger ceiling (see `GameRef`),
/// because their bigger boards can score past 100,000.
bool bubbleVariantUsesBigScores(int v) => v >= kBubbleOriginalVariants;
