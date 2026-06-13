import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sudoku_app/services/leaderboard.dart';

/// Verifies the client parses the *exact* JSON the live PHP backend returns
/// (captured from real curl round-trips against the949dude.com), and builds the
/// right request URLs — without needing network/DNS.
void main() {
  const base = 'https://the949dude.com/sudoku';

  test('leaderboard parses live JSON, in rank order, with emails hidden', () async {
    Uri? seen;
    final mock = MockClient((req) async {
      seen = req.url;
      return http.Response(
        jsonEncode({
          'ok': true,
          'gameId': 1234,
          'entries': [
            {'name': 'Alice', 'seconds': 180, 'hints': 0, 'mistakes': 0, 'difficulty': 2, 'finished_at': '2026-06-13 03:01:01'},
            {'name': 'Bob', 'seconds': 150, 'hints': 1, 'mistakes': 2, 'difficulty': 2, 'finished_at': '2026-06-13 03:00:40'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final lb = RemoteLeaderboard(base, client: mock);
    final entries = await lb.leaderboard(1234);

    // Right endpoint + params.
    expect(seen!.path, '/sudoku/index.php');
    expect(seen!.queryParameters['r'], 'leaderboard');
    expect(seen!.queryParameters['game'], '1234');

    // Parsed correctly and in server order (fewest hints first).
    expect(entries.length, 2);
    expect(entries[0].name, 'Alice');
    expect(entries[0].hints, 0);
    expect(entries[0].seconds, 180);
    expect(entries[0].email, isNull); // global board hides email
    expect(entries[1].name, 'Bob');
    expect(entries[1].hints, 1);
  });

  test('friends parses emails and sends the email list', () async {
    Uri? seen;
    final mock = MockClient((req) async {
      seen = req.url;
      return http.Response(
        jsonEncode({
          'ok': true,
          'gameId': 1234,
          'entries': [
            {'email': 'alice@example.com', 'name': 'Alice', 'seconds': 180, 'hints': 0, 'mistakes': 0, 'difficulty': 2, 'finished_at': 'x'},
          ],
        }),
        200,
      );
    });
    final lb = RemoteLeaderboard(base, client: mock);
    final entries = await lb.friends(1234, ['alice@example.com', 'bob@example.com']);

    expect(seen!.queryParameters['emails'], 'alice@example.com,bob@example.com');
    expect(entries.single.email, 'alice@example.com');
  });

  test('submitResult parses the outcome and posts JSON body', () async {
    Map<String, dynamic>? body;
    final mock = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'ok': true, 'improved': true, 'rank': 2, 'total': 5}),
        200,
      );
    });
    final lb = RemoteLeaderboard(base, client: mock);
    final outcome = await lb.submitResult(
      gameId: 1234,
      email: 'me@example.com',
      name: 'Me',
      seconds: 312,
      hints: 0,
      mistakes: 1,
      difficulty: 2,
    );

    expect(body!['gameId'], 1234);
    expect(body!['email'], 'me@example.com');
    expect(body!['hints'], 0);
    expect(outcome, isNotNull);
    expect(outcome!.improved, isTrue);
    expect(outcome.rank, 2);
    expect(outcome.total, 5);
  });

  test('failures fail soft (null / empty), never throw', () async {
    final lb = RemoteLeaderboard(base,
        client: MockClient((req) async => http.Response('nope', 500)));
    expect(await lb.leaderboard(1), isEmpty);
    expect(
      await lb.submitResult(
        gameId: 1, email: 'a@b.co', name: 'A', seconds: 1,
        hints: 0, mistakes: 0, difficulty: 0,
      ),
      isNull,
    );
  });
}
