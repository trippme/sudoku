import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../engine/sudoku_engine.dart';
import '../services/storage.dart';

/// One finished game.
class CompletionRecord {
  final Difficulty difficulty;
  final int seconds;
  final bool daily;
  final String dateIso; // yyyy-mm-dd

  CompletionRecord({
    required this.difficulty,
    required this.seconds,
    required this.daily,
    required this.dateIso,
  });

  Map<String, dynamic> toJson() => {
        'd': difficulty.index,
        's': seconds,
        'daily': daily,
        'date': dateIso,
      };

  factory CompletionRecord.fromJson(Map<String, dynamic> m) => CompletionRecord(
        difficulty: Difficulty.values[m['d'] as int],
        seconds: m['s'] as int,
        daily: (m['daily'] ?? false) as bool,
        dateIso: m['date'] as String,
      );
}

/// Aggregated per-difficulty performance.
class DifficultyStat {
  int played = 0;
  int completed = 0;
  int? bestSeconds;
  int totalSeconds = 0;

  int? get averageSeconds =>
      completed == 0 ? null : (totalSeconds / completed).round();

  Map<String, dynamic> toJson() => {
        'played': played,
        'completed': completed,
        'best': bestSeconds,
        'total': totalSeconds,
      };

  static DifficultyStat fromJson(Map<String, dynamic> m) => DifficultyStat()
    ..played = (m['played'] ?? 0) as int
    ..completed = (m['completed'] ?? 0) as int
    ..bestSeconds = m['best'] as int?
    ..totalSeconds = (m['total'] ?? 0) as int;
}

/// Local-first statistics + daily streak. Persisted after every change.
class Stats extends ChangeNotifier {
  static const _key = 'stats_v1';

  final Map<Difficulty, DifficultyStat> byDifficulty = {
    for (final d in Difficulty.values) d: DifficultyStat(),
  };

  int currentStreak = 0;
  int longestStreak = 0;
  String? lastDailyIso; // last daily date completed
  final List<CompletionRecord> recent = []; // newest first, capped

  factory Stats.load() {
    final s = Stats._();
    final raw = Storage.getString(_key);
    if (raw == null) return s;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final byDiff = m['byDifficulty'] as Map<String, dynamic>? ?? {};
      for (final d in Difficulty.values) {
        final ds = byDiff['${d.index}'];
        if (ds != null) {
          s.byDifficulty[d] = DifficultyStat.fromJson(ds as Map<String, dynamic>);
        }
      }
      s.currentStreak = (m['currentStreak'] ?? 0) as int;
      s.longestStreak = (m['longestStreak'] ?? 0) as int;
      s.lastDailyIso = m['lastDailyIso'] as String?;
      for (final r in (m['recent'] as List? ?? [])) {
        s.recent.add(CompletionRecord.fromJson(r as Map<String, dynamic>));
      }
    } catch (_) {/* corrupt → start fresh */}
    return s;
  }

  Stats._();

  void _save() {
    Storage.setString(
      _key,
      jsonEncode({
        'byDifficulty': {
          for (final e in byDifficulty.entries)
            '${e.key.index}': e.value.toJson(),
        },
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastDailyIso': lastDailyIso,
        'recent': recent.map((r) => r.toJson()).toList(),
      }),
    );
    notifyListeners();
  }

  /// Call when a new game starts (counts an attempt).
  void recordStart(Difficulty d) {
    byDifficulty[d]!.played++;
    _save();
  }

  /// Call when a game is solved. Updates bests, averages, and daily streak.
  void recordCompletion({
    required Difficulty difficulty,
    required int seconds,
    required bool daily,
    required DateTime now,
  }) {
    final stat = byDifficulty[difficulty]!;
    stat.completed++;
    stat.totalSeconds += seconds;
    if (stat.bestSeconds == null || seconds < stat.bestSeconds!) {
      stat.bestSeconds = seconds;
    }

    final todayIso = isoDate(now);
    if (daily) {
      final yIso = isoDate(now.subtract(const Duration(days: 1)));
      if (lastDailyIso == todayIso) {
        // already counted today; leave streak
      } else if (lastDailyIso == yIso) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      lastDailyIso = todayIso;
      if (currentStreak > longestStreak) longestStreak = currentStreak;
    }

    recent.insert(
      0,
      CompletionRecord(
        difficulty: difficulty,
        seconds: seconds,
        daily: daily,
        dateIso: todayIso,
      ),
    );
    if (recent.length > 50) recent.removeRange(50, recent.length);
    _save();
  }

  /// True if today's daily puzzle has already been completed.
  bool dailyDoneToday(DateTime now) => lastDailyIso == isoDate(now);

  /// Formats a date as yyyy-mm-dd (used as the daily-puzzle key).
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
