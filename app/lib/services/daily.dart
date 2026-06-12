import '../engine/sudoku_engine.dart';

/// Deterministic "puzzle of the day": every device generates the *same* puzzle
/// for a given calendar date with no server required. Difficulty rotates by
/// weekday so dailies vary through the week.
class DailyPuzzle {
  /// Stable integer seed for a date (e.g. 2026-06-11 → 20260611).
  static int seedFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  /// Difficulty assigned to a given date (Mon easiest → weekend hardest).
  static Difficulty difficultyFor(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
      case DateTime.tuesday:
        return Difficulty.easy;
      case DateTime.wednesday:
      case DateTime.thursday:
        return Difficulty.medium;
      case DateTime.friday:
        return Difficulty.hard;
      default:
        return Difficulty.expert;
    }
  }

  /// Generates today's (or [date]'s) puzzle deterministically.
  static Puzzle generate(DateTime date) {
    final engine = SudokuEngine(seedFor(date));
    return engine.generate(difficultyFor(date));
  }
}
