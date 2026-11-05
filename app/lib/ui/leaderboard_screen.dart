import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';

/// Shows the global leaderboard and your friends' results for one game number.
class LeaderboardScreen extends StatefulWidget {
  final int gameId;
  const LeaderboardScreen({super.key, required this.gameId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<ResultEntry>> _global;
  late Future<List<ResultEntry>> _friends;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    _global = svc.leaderboard(widget.gameId);
    _friends = profile.friends.isEmpty
        ? Future.value(const [])
        : svc.friends(widget.gameId, [...profile.friends, profile.email]);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<Profile>();
    return Scaffold(
      appBar: AppBar(
        title: Text(GameRef.decode(widget.gameId).label),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_load),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
        children: [
          if (!profile.hasIdentity)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Set your name and email in Settings to appear on the '
                  'leaderboard and compete with friends.',
                ),
              ),
            ),
          const _SectionTitle('Friends'),
          _Results(
            future: _friends,
            emptyText: profile.friends.isEmpty
                ? 'Add friends in Settings to compare on this game.'
                : 'No friends have finished this game yet.',
            showEmail: true,
            highlightEmail: profile.email,
            game: GameRef.decode(widget.gameId),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Global'),
          _Results(
            future: _global,
            emptyText: 'No results yet — be the first to finish this game!',
            showEmail: false,
            highlightEmail: profile.email,
            game: GameRef.decode(widget.gameId),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      );
}

class _Results extends StatelessWidget {
  final Future<List<ResultEntry>> future;
  final String emptyText;
  final bool showEmail;
  final String highlightEmail;

  /// Decides how each result is worded (time, hints, score…).
  final GameRef game;

  const _Results({
    required this.future,
    required this.emptyText,
    required this.showEmail,
    required this.highlightEmail,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResultEntry>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entries = snap.data ?? const [];
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(emptyText,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++)
                _row(context, i + 1, entries[i]),
            ],
          ),
        );
      },
    );
  }

  Widget? _subtitle(ResultEntry e, String? detail) {
    final email = showEmail && e.email != null ? e.email! : '';
    final lines = [?detail, if (email.isNotEmpty) email];
    return lines.isEmpty ? null : Text(lines.join('\n'));
  }

  Widget _row(BuildContext context, int rank, ResultEntry e) {
    final res = game.describeResult(
        seconds: e.seconds, hints: e.hints, mistakes: e.mistakes);
    final isMe = showEmail && e.email != null && e.email == highlightEmail;
    return Container(
      color: isMe ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('$rank', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(e.name.isEmpty ? '(anonymous)' : e.name),
        subtitle: _subtitle(e, res.detail),
        isThreeLine: showEmail && res.detail != null,
        trailing: Text(
          res.headline,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
