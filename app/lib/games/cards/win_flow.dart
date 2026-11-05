import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/cards/game_clock.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/ui/leaderboard_screen.dart';
import 'package:sudoku_app/ui/send_to_friends.dart';

/// Submits a finished card game (ranked on time) and tells the friends you
/// compete with. Returns null if there's no profile, no backend, or no network.
Future<SubmitOutcome?> submitCardResult(
  BuildContext context,
  GameRef ref,
  int seconds,
) async {
  final profile = context.read<Profile>();
  if (!profile.hasIdentity) return null;
  final svc = context.read<LeaderboardService>();
  final outcome = await svc.submitResult(
    gameId: ref.id,
    email: profile.email,
    name: profile.name,
    seconds: seconds < 1 ? 1 : seconds,
    hints: 0,
    mistakes: 0,
    difficulty: 0,
  );
  svc.notifyFinish(
    email: profile.email,
    name: profile.name,
    gameId: ref.id,
    seconds: seconds < 1 ? 1 : seconds,
    hints: 0,
  );
  return outcome;
}

/// The post-win dialog: submits the result, shows your rank, and offers the
/// leaderboard and a friend challenge. Returns true if "New deal" was chosen.
Future<bool> showCardWinDialog(
  BuildContext context, {
  required GameRef ref,
  required int seconds,
  required int moves,
}) async {
  final hasProfile = context.read<Profile>().hasIdentity;
  final outcome = submitCardResult(context, ref, seconds);
  final again = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('You won! 🎉'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${ref.label} solved in ${GameClock.format(seconds)} '
              '($moves moves).'),
          const SizedBox(height: 10),
          if (!hasProfile)
            const Text('Set your name and email in Settings to join the '
                'leaderboard and compete with friends.')
          else
            FutureBuilder<SubmitOutcome?>(
              future: outcome,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Text('Submitting your time…');
                }
                final o = snap.data;
                if (o == null) return const Text('Couldn’t reach the leaderboard.');
                return Text(o.improved
                    ? 'Rank #${o.rank} of ${o.total} on this deal.'
                    : 'Not your best — you’re #${o.rank} of ${o.total}.');
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => LeaderboardScreen(gameId: ref.id))),
          child: const Text('Leaderboard'),
        ),
        TextButton(
          onPressed: () =>
              sendGameToFriends(ctx, gameId: ref.id, label: ref.label),
          child: const Text('Challenge'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('New deal')),
      ],
    ),
  );
  return again == true;
}
