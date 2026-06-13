import 'dart:math';
import '../engine/sudoku_engine.dart';

/// Maps a **game number** to a puzzle, deterministically. Because the puzzle is
/// a pure function of its number, "game #1234" is the same for everyone with no
/// server — which is what makes leaderboards, friend competition, and sharing
/// work offline.
///
/// The game number both seeds the generator and selects the difficulty
/// (`gameId % 4`), so a single integer fully reproduces a puzzle.
class GameCatalog {
  static const int _n = 4; // Difficulty.values.length

  /// The puzzle for a given game number. Same number → same puzzle, anywhere.
  static Puzzle puzzleForGame(int gameId) {
    final difficulty = Difficulty.values[gameId % _n];
    return SudokuEngine(gameId).generate(difficulty);
  }

  /// A fresh random game number whose difficulty is [d]. Kept below 10,000,000
  /// so it never collides with daily numbers (which are ~8-digit, see below).
  static int randomGameId(Difficulty d, [Random? rng]) {
    final r = rng ?? Random();
    final base = r.nextInt(10000000);
    return base - (base % _n) + d.index; // base % _n == d.index
  }

  /// Difficulty for the daily puzzle on [date] (Mon/Tue easy → weekend expert).
  static Difficulty dailyDifficultyFor(DateTime date) {
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

  /// The game number for [date]'s daily puzzle. Encodes both the date and the
  /// chosen daily difficulty into one shareable number (and stays well above
  /// the random-game range so the two never collide).
  static int dailyGameId(DateTime date) {
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    return ymd * _n + dailyDifficultyFor(date).index;
  }
}
