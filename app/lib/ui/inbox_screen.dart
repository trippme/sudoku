import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/profile.dart';
import '../services/leaderboard.dart';
import 'game_screen.dart';

/// Games friends have sent you. Tap one to play it.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<ReceivedGame>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    _future = profile.hasIdentity
        ? svc.inbox(profile.email)
        : Future.value(const []);
  }

  Future<void> _play(ReceivedGame g) async {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    if (!g.seen) svc.markSeen(g.id, profile.email);
    context.read<GameState>().playGame(g.gameId);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GameScreen()));
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<Profile>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_load),
          ),
        ],
      ),
      body: !profile.hasIdentity
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Set your name and email in Settings to receive games '
                  'from friends.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : FutureBuilder<List<ReceivedGame>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final games = snap.data ?? const [];
                if (games.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No games yet. When a friend sends you one, it shows '
                        'up here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: games.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final g = games[i];
                    return ListTile(
                      leading: Icon(
                        g.seen ? Icons.mail_outline : Icons.mark_email_unread,
                        color: g.seen ? Colors.grey : const Color(0xFF2E6FB7),
                      ),
                      title: Text(
                        'Game #${g.gameId}',
                        style: TextStyle(
                          fontWeight:
                              g.seen ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'from ${g.fromName.isEmpty ? g.fromEmail : g.fromName}'
                        '${g.message.isEmpty ? '' : '\n“${g.message}”'}',
                      ),
                      isThreeLine: g.message.isNotEmpty,
                      trailing: const Icon(Icons.play_arrow),
                      onTap: () => _play(g),
                    );
                  },
                );
              },
            ),
    );
  }
}
