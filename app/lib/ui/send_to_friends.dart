import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/ui/settings_screen.dart';

/// Lets the player pick friends and sends them [gameId] (it lands in their
/// in-app inbox). Walks them through setting up a profile/friends if needed.
Future<void> sendGameToFriends(
BuildContext context, {
required int gameId,
required String label,
}) async {
  final profile = context.read<Profile>();
  final svc = context.read<LeaderboardService>();
  final messenger = ScaffoldMessenger.of(context);

  if (!profile.hasIdentity || profile.friends.isEmpty) {
    final goSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set up friends first'),
        content: Text(profile.hasIdentity
            ? 'Add a friend by email in Settings to send them games.'
            : 'Set your name and email, then add friends, in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (goSettings == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
    return;
  }

  final selected = <String>{};
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setInner) => AlertDialog(
        title: Text('Send $label to…'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final f in profile.friends)
                CheckboxListTile(
                  dense: true,
                  value: selected.contains(f),
                  title: Text(f),
                  onChanged: (v) => setInner(() =>
                      v == true ? selected.add(f) : selected.remove(f)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                selected.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    ),
  );
  if (send != true || selected.isEmpty) return;

  var ok = 0;
  for (final f in selected) {
    if (await svc.sendGame(
      fromEmail: profile.email,
      fromName: profile.name,
      toEmail: f,
      gameId: gameId,
    )) {
      ok++;
    }
  }
  messenger.showSnackBar(SnackBar(
    content: Text(ok > 0
        ? 'Sent $label to $ok friend${ok == 1 ? '' : 's'}'
        : 'Could not send — check your connection'),
  ));
}
