import 'package:sudoku_app/games/bubble/bubble_variant.dart';

/// Which game a backend `game_id` belongs to, plus its deal.
///
/// The backend only knows an integer `game_id` per result, challenge and
/// notification. Rather than changing the live schema, each game owns a
/// reserved numeric range (see the table below) so one id says which game and
/// which deal. Sudoku ids are unchanged (everything below 1,000,000,000).
///
/// | Game             | game_id                    |
/// |------------------|----------------------------|
/// | Sudoku           | as before (< 1,000,000,000)|
/// | FreeCell         | 1,000,000,000 + deal       |
/// | Solitaire draw-1 | 1,100,000,000 + deal       |
/// | Solitaire draw-3 | 1,200,000,000 + deal       |
/// | Bubble Breaker   | 1,300,000,000 + variant × 10,000,000 + deal |
///
/// A Bubble Breaker *variant* (0..53) is level × size × mode, so every
/// combination has its own leaderboard; see `bubble_variant.dart` for the
/// numbering. Variant 0 (medium, normal level, collapsing — the original game)
/// keeps its original ids.
///
/// Deals are 1..[maxDeal], so every id fits a signed 32-bit INT.
enum GameKind { sudoku, freecell, solitaire, bubble }

class GameRef {
  static const int maxDeal = 1000000;
  static const int _freecellBase = 1000000000;
  static const int _solitaire1Base = 1100000000;
  static const int _solitaire3Base = 1200000000;
  static const int _bubbleBase = 1300000000;
  static const int _bubbleStride = 10000000;
  static const int bubbleVariants = kBubbleVariantCount;
  static const _bubbleSizeNames = [
    'Medium',
    'Small',
    'Large',
    'X-Large',
    'Standard',
    'Dense',
    'Tiny',
    'Unified',
    'Unified V2',
  ];
  static const _bubbleLevelNames = ['normal', 'easy', 'hard'];

  /// Bubble Breaker ranks by HIGH score, but the backend ranks by fewest
  /// "hints" then fastest time. So a score is stored as `hints = ceiling -
  /// score` (a higher score is a lower number) with the play time as the
  /// tie-break. The original boards use a ceiling of 100,000; the later, bigger
  /// ones (variant 24+) use 10,000,000 because they can score past 100,000.
  static int _ceilingFor(int variant) =>
      bubbleVariantUsesBigScores(variant) ? 10000000 : 100000;

  static int hintsForScore(int score, {int variant = 0}) {
    final c = _ceilingFor(variant);
    return c - score.clamp(0, c - 1);
  }

  static int scoreFromHints(int hints, {int variant = 0}) {
    final c = _ceilingFor(variant);
    return (c - hints).clamp(0, c - 1);
  }

  final GameKind kind;

  /// Sudoku game number, or the card-game deal number.
  final int deal;

  /// Solitaire only: cards turned per draw (1 or 3). 0 for other games.
  final int draw;

  /// Bubble Breaker only: size/mode variant, 0..[bubbleVariants]-1.
  final int variant;

  const GameRef._(this.kind, this.deal, this.draw, [this.variant = 0]);

  static GameRef sudoku(int gameId) => GameRef._(GameKind.sudoku, gameId, 0);
  static GameRef freecell(int deal) => GameRef._(GameKind.freecell, deal, 0);
  static GameRef bubble(int deal, {int variant = 0}) =>
      GameRef._(GameKind.bubble, deal, 0, variant.clamp(0, bubbleVariants - 1));
  static GameRef solitaire(int deal, {int draw = 1}) =>
      GameRef._(GameKind.solitaire, deal, draw == 3 ? 3 : 1);

  /// Reads a backend game_id. Unknown / out-of-range values fall back to
  /// Sudoku so older data never breaks.
  factory GameRef.decode(int id) {
    int inRange(int base) => id - base;
    bool fits(int base) {
      final d = inRange(base);
      return d >= 1 && d <= maxDeal;
    }

    if (fits(_freecellBase)) return GameRef.freecell(inRange(_freecellBase));
    for (var v = 0; v < bubbleVariants; v++) {
      final base = _bubbleBase + v * _bubbleStride;
      if (fits(base)) return GameRef.bubble(inRange(base), variant: v);
    }
    if (fits(_solitaire1Base)) {
      return GameRef.solitaire(inRange(_solitaire1Base), draw: 1);
    }
    if (fits(_solitaire3Base)) {
      return GameRef.solitaire(inRange(_solitaire3Base), draw: 3);
    }
    return GameRef.sudoku(id);
  }

  int get id {
    switch (kind) {
      case GameKind.sudoku:
        return deal;
      case GameKind.freecell:
        return _freecellBase + deal;
      case GameKind.solitaire:
        return (draw == 3 ? _solitaire3Base : _solitaire1Base) + deal;
      case GameKind.bubble:
        return _bubbleBase + variant * _bubbleStride + deal;
    }
  }

  /// Sudoku results carry hints/mistakes; the card games are ranked on time.
  bool get usesHints => kind == GameKind.sudoku;

  /// Bubble Breaker results are scores (see [hintsForScore]).
  bool get usesScore => kind == GameKind.bubble;

  /// How to show a stored result: a headline plus an optional detail line.
  /// Sudoku: time / hints & mistakes. Card games: time. Bubble: score / time.
  ({String headline, String? detail}) describeResult({
    required int seconds,
    required int hints,
    int? mistakes,
  }) {
    final t = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    switch (kind) {
      case GameKind.sudoku:
        return (
          headline: t,
          detail: '$hints hint${hints == 1 ? '' : 's'}'
              '${mistakes == null ? '' : ' · $mistakes mistake${mistakes == 1 ? '' : 's'}'}',
        );
      case GameKind.bubble:
        return (
          headline: '${scoreFromHints(hints, variant: variant)} pts',
          detail: t
        );
      case GameKind.freecell:
      case GameKind.solitaire:
        return (headline: t, detail: null);
    }
  }

  String get gameName {
    switch (kind) {
      case GameKind.sudoku:
        return 'Sudoku';
      case GameKind.freecell:
        return 'FreeCell';
      case GameKind.solitaire:
        return 'Solitaire';
      case GameKind.bubble:
        return 'Bubble Breaker';
    }
  }

  /// e.g. "FreeCell #617", "Solitaire #42 (draw 3)", "Sudoku #8123".
  String get label {
    var extra = kind == GameKind.solitaire && draw == 3 ? ' (draw 3)' : '';
    if (kind == GameKind.bubble && variant != 0) {
      final v = decodeBubbleVariant(variant);
      final parts = [
        if (v.level != 0) _bubbleLevelNames[v.level],
        if (v.size != 0) _bubbleSizeNames[v.size].toLowerCase(),
        if (v.fixed) 'fixed',
      ];
      extra = ' (${parts.join(', ')})';
    }
    return '$gameName #$deal$extra';
  }
}
