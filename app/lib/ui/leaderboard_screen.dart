import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/leaderboard.dart';

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

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<Profile>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Game #${widget.gameId}'),
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
              color: Colors.amber.shade50,
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
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Global'),
          _Results(
            future: _global,
            emptyText: 'No results yet — be the first to finish this game!',
            showEmail: false,
            highlightEmail: profile.email,
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

  const _Results({
    required this.future,
    required this.emptyText,
    required this.showEmail,
    required this.highlightEmail,
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
                style: const TextStyle(color: Colors.black54)),
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

  Widget _row(BuildContext context, int rank, ResultEntry e) {
    final isMe = showEmail && e.email != null && e.email == highlightEmail;
    return Container(
      color: isMe ? const Color(0xFFE7F0FB) : null,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('$rank', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(e.name.isEmpty ? '(anonymous)' : e.name),
        subtitle: Text(
          '${e.hints} hint${e.hints == 1 ? '' : 's'} · '
          '${e.mistakes} mistake${e.mistakes == 1 ? '' : 's'}'
          '${showEmail && e.email != null ? '\n${e.email}' : ''}',
        ),
        isThreeLine: showEmail,
        trailing: Text(
          _LeaderboardScreenState._fmt(e.seconds),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
