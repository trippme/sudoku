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

/// A game a friend sent you (your inbox).
class ReceivedGame {
  final int id; // share id (for marking seen)
  final String fromName;
  final String fromEmail;
  final int gameId;
  final String message;
  final bool seen;
  final String createdAt;

  ReceivedGame({
    required this.id,
    required this.fromName,
    required this.fromEmail,
    required this.gameId,
    required this.message,
    required this.seen,
    required this.createdAt,
  });

  factory ReceivedGame.fromJson(Map<String, dynamic> m) => ReceivedGame(
        id: (m['id'] ?? 0) as int,
        fromName: (m['from_name'] ?? '') as String,
        fromEmail: (m['from_email'] ?? '') as String,
        gameId: (m['game_id'] ?? 0) as int,
        message: (m['message'] ?? '') as String,
        seen: ((m['seen'] ?? 0) as int) != 0,
        createdAt: (m['created_at'] ?? '') as String,
      );
}

/// A competitor finished a shared game — their result, sent to you.
class CompetitorResult {
  final int id;
  final String fromName;
  final String fromEmail;
  final int gameId;
  final int seconds;
  final int hints;
  final bool seen;
  final String createdAt;

  CompetitorResult({
    required this.id,
    required this.fromName,
    required this.fromEmail,
    required this.gameId,
    required this.seconds,
    required this.hints,
    required this.seen,
    required this.createdAt,
  });

  factory CompetitorResult.fromJson(Map<String, dynamic> m) => CompetitorResult(
        id: (m['id'] ?? 0) as int,
        fromName: (m['from_name'] ?? '') as String,
        fromEmail: (m['from_email'] ?? '') as String,
        gameId: (m['game_id'] ?? 0) as int,
        seconds: (m['seconds'] ?? 0) as int,
        hints: (m['hints'] ?? 0) as int,
        seen: ((m['seen'] ?? 0) as int) != 0,
        createdAt: (m['created_at'] ?? '') as String,
      );
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

  /// Send a game to a friend's inbox. Returns true on success.
  Future<bool> sendGame({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required int gameId,
    String message = '',
  });

  /// Games friends have sent you, newest first.
  Future<List<ReceivedGame>> inbox(String email, {int limit = 50});

  /// Mark a received game as seen.
  Future<void> markSeen(int shareId, String email);

  /// Notify the people you're competing with on [gameId] that you finished.
  Future<void> notifyFinish({
    required String email,
    required String name,
    required int gameId,
    required int seconds,
    required int hints,
  });

  /// Competitor results pushed to you (a friend finished a shared game).
  Future<List<CompetitorResult>> notifications(String email, {int limit = 50});

  /// Mark a competitor-result notification as seen.
  Future<void> markNotificationSeen(int id, String email);
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

  @override
  Future<bool> sendGame({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required int gameId,
    String message = '',
  }) async =>
      false;

  @override
  Future<List<ReceivedGame>> inbox(String email, {int limit = 50}) async => const [];

  @override
  Future<void> markSeen(int shareId, String email) async {}

  @override
  Future<void> notifyFinish({
    required String email,
    required String name,
    required int gameId,
    required int seconds,
    required int hints,
  }) async {}

  @override
  Future<List<CompetitorResult>> notifications(String email, {int limit = 50}) async =>
      const [];

  @override
  Future<void> markNotificationSeen(int id, String email) async {}
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

  Map<String, String> get _writeHeaders => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'X-Api-Key': apiKey!,
      };

  @override
  Future<bool> sendGame({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required int gameId,
    String message = '',
  }) async {
    try {
      final res = await _client
          .post(
            _uri('share'),
            headers: _writeHeaders,
            body: jsonEncode({
              'fromEmail': fromEmail,
              'fromName': fromName,
              'toEmail': toEmail,
              'gameId': gameId,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ReceivedGame>> inbox(String email, {int limit = 50}) async {
    try {
      final res = await _client
          .get(_uri('inbox', {'email': email, 'limit': '$limit'}))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (m['shares'] as List? ?? const []);
      return list
          .map((e) => ReceivedGame.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> markSeen(int shareId, String email) async {
    try {
      await _client
          .post(
            _uri('seen'),
            headers: _writeHeaders,
            body: jsonEncode({'id': shareId, 'email': email}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* best effort */}
  }

  @override
  Future<void> notifyFinish({
    required String email,
    required String name,
    required int gameId,
    required int seconds,
    required int hints,
  }) async {
    try {
      await _client
          .post(
            _uri('finish'),
            headers: _writeHeaders,
            body: jsonEncode({
              'email': email,
              'name': name,
              'gameId': gameId,
              'seconds': seconds,
              'hints': hints,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* best effort */}
  }

  @override
  Future<List<CompetitorResult>> notifications(String email, {int limit = 50}) async {
    try {
      final res = await _client
          .get(_uri('notifications', {'email': email, 'limit': '$limit'}))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (m['notifications'] as List? ?? const []);
      return list
          .map((e) => CompetitorResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> markNotificationSeen(int id, String email) async {
    try {
      await _client
          .post(
            _uri('notif_seen'),
            headers: _writeHeaders,
            body: jsonEncode({'id': id, 'email': email}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* best effort */}
  }
}
