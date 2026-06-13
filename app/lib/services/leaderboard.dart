import 'dart:convert';
import 'package:http/http.dart' as http;

/// One leaderboard / friend row returned by the backend.
class ResultEntry {
  final String name;
  final String? email; // present only for friend lookups
  final int seconds;
  final int hints;
  final int mistakes;
  final int difficulty;
  final String finishedAt;

  ResultEntry({
    required this.name,
    this.email,
    required this.seconds,
    required this.hints,
    required this.mistakes,
    required this.difficulty,
    required this.finishedAt,
  });

  factory ResultEntry.fromJson(Map<String, dynamic> m) => ResultEntry(
        name: (m['name'] ?? '') as String,
        email: m['email'] as String?,
        seconds: (m['seconds'] ?? 0) as int,
        hints: (m['hints'] ?? 0) as int,
        mistakes: (m['mistakes'] ?? 0) as int,
        difficulty: (m['difficulty'] ?? 0) as int,
        finishedAt: (m['finished_at'] ?? '') as String,
      );
}

/// Outcome of submitting a result.
class SubmitOutcome {
  final bool improved; // was this your new best?
  final int rank; // 1-based rank on that game
  final int total; // total players on that game
  SubmitOutcome({required this.improved, required this.rank, required this.total});
}

/// The app talks to this interface. Today it can be the offline [NullLeaderboard]
/// or the [RemoteLeaderboard] pointed at the PHP backend (see /server).
abstract class LeaderboardService {
  /// Submit a finished game. Returns null on network/back-end failure.
  Future<SubmitOutcome?> submitResult({
    required int gameId,
    required String email,
    required String name,
    required int seconds,
    required int hints,
    required int mistakes,
    required int difficulty,
  });

  /// Global top results for a game (names only — no emails).
  Future<List<ResultEntry>> leaderboard(int gameId, {int limit = 20});

  /// Results for specific friends (by email) on a game.
  Future<List<ResultEntry>> friends(int gameId, List<String> emails);

  /// One player's recent history across games (for cloud sync).
  Future<List<ResultEntry>> playerHistory(String email, {int limit = 100});
}

/// Offline no-op implementation: lets the app run with no backend configured.
class NullLeaderboard implements LeaderboardService {
  @override
  Future<SubmitOutcome?> submitResult({
    required int gameId,
    required String email,
    required String name,
    required int seconds,
    required int hints,
    required int mistakes,
    required int difficulty,
  }) async =>
      null;

  @override
  Future<List<ResultEntry>> leaderboard(int gameId, {int limit = 20}) async => const [];

  @override
  Future<List<ResultEntry>> friends(int gameId, List<String> emails) async => const [];

  @override
  Future<List<ResultEntry>> playerHistory(String email, {int limit = 100}) async => const [];
}

/// REST client for the PHP backend in `/server`.
///
/// [baseUrl] is the folder the API lives in, e.g.
/// `https://yourhost/sudoku`. Optionally pass [apiKey] if the server has one.
class RemoteLeaderboard implements LeaderboardService {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;

  RemoteLeaderboard(String baseUrl, {this.apiKey, http.Client? client})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  Uri _uri(String route, [Map<String, String> params = const {}]) =>
      Uri.parse('$baseUrl/index.php')
          .replace(queryParameters: {'r': route, ...params});

  @override
  Future<SubmitOutcome?> submitResult({
    required int gameId,
    required String email,
    required String name,
    required int seconds,
    required int hints,
    required int mistakes,
    required int difficulty,
  }) async {
    try {
      final res = await _client
          .post(
            _uri('result'),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey != null && apiKey!.isNotEmpty) 'X-Api-Key': apiKey!,
            },
            body: jsonEncode({
              'gameId': gameId,
              'email': email,
              'name': name,
              'seconds': seconds,
              'hints': hints,
              'mistakes': mistakes,
              'difficulty': difficulty,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      if (m['ok'] != true) return null;
      return SubmitOutcome(
        improved: (m['improved'] ?? false) as bool,
        rank: (m['rank'] ?? 0) as int,
        total: (m['total'] ?? 0) as int,
      );
    } catch (_) {
      return null; // offline / backend down → fail soft
    }
  }

  Future<List<ResultEntry>> _getEntries(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (m['entries'] as List? ?? m['results'] as List? ?? const []);
      return list
          .map((e) => ResultEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ResultEntry>> leaderboard(int gameId, {int limit = 20}) =>
      _getEntries(_uri('leaderboard', {'game': '$gameId', 'limit': '$limit'}));

  @override
  Future<List<ResultEntry>> friends(int gameId, List<String> emails) =>
      _getEntries(_uri('friends', {'game': '$gameId', 'emails': emails.join(',')}));

  @override
  Future<List<ResultEntry>> playerHistory(String email, {int limit = 100}) =>
      _getEntries(_uri('player', {'email': email, 'limit': '$limit'}));
}
