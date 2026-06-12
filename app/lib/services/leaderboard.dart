import 'dart:convert';
import 'package:http/http.dart' as http;
import '../engine/sudoku_engine.dart';

/// One leaderboard row.
class LeaderboardEntry {
  final String name;
  final int seconds;
  final String dateIso;
  LeaderboardEntry({
    required this.name,
    required this.seconds,
    required this.dateIso,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> m) => LeaderboardEntry(
        name: (m['name'] ?? 'Anon') as String,
        seconds: m['seconds'] as int,
        dateIso: (m['date'] ?? '') as String,
      );
}

/// Pluggable leaderboard. The app talks to this interface; today it's backed by
/// a no-op/local implementation, and [RemoteLeaderboard] is ready to point at a
/// real backend when one exists (see the backend spec in README / docs).
abstract class LeaderboardService {
  /// Submit a daily-puzzle time. Returns true if accepted.
  Future<bool> submitDaily({
    required String name,
    required int seconds,
    required Difficulty difficulty,
    required String dateIso,
  });

  /// Fetch the top entries for a given daily date.
  Future<List<LeaderboardEntry>> topForDate(String dateIso, {int limit = 20});
}

/// Default offline implementation: accepts submissions but stores nothing
/// remotely. Lets the rest of the app run with no backend configured.
class NullLeaderboard implements LeaderboardService {
  @override
  Future<bool> submitDaily({
    required String name,
    required int seconds,
    required Difficulty difficulty,
    required String dateIso,
  }) async =>
      false;

  @override
  Future<List<LeaderboardEntry>> topForDate(String dateIso, {int limit = 20}) async =>
      const [];
}

/// REST implementation against the optional thin backend.
///
/// Expected backend (documented in README):
///   POST {baseUrl}/daily   body: {name, seconds, difficulty, date}
///   GET  {baseUrl}/daily?date=YYYY-MM-DD&limit=20  -> [{name, seconds, date}]
///
/// Wire it up by constructing with your deployed base URL.
class RemoteLeaderboard implements LeaderboardService {
  final String baseUrl;
  final http.Client _client;

  RemoteLeaderboard(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<bool> submitDaily({
    required String name,
    required int seconds,
    required Difficulty difficulty,
    required String dateIso,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/daily'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'seconds': seconds,
              'difficulty': difficulty.index,
              'date': dateIso,
            }),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false; // offline / backend down → fail soft
    }
  }

  @override
  Future<List<LeaderboardEntry>> topForDate(String dateIso, {int limit = 20}) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/daily?date=$dateIso&limit=$limit'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
