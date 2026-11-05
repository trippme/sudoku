import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/bubble/bubble_screen.dart';
import 'package:sudoku_app/games/freecell/freecell_screen.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/games/solitaire/solitaire_screen.dart';
import 'package:sudoku_app/games/sudoku/models/game_state.dart';
import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/games/sudoku/ui/game_screen.dart';
import 'package:sudoku_app/ui/leaderboard_screen.dart';

/// Your inbox: competitor results friends pushed to you, and games they sent
/// you to play.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<ReceivedGame>> _games;
  late Future<List<CompetitorResult>> _results;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    if (profile.hasIdentity) {
      _games = svc.inbox(profile.email);
      _results = svc.notifications(profile.email);
    } else {
      _games = Future.value(const []);
      _results = Future.value(const []);
    }
  }

  /// "3:21 · 1 hint" (Sudoku), "4:02" (cards), "640 pts · 1:15" (Bubble).
  static String _resultText(CompetitorResult r) {
    final d = GameRef.decode(r.gameId)
        .describeResult(seconds: r.seconds, hints: r.hints);
    return d.detail == null ? d.headline : '${d.headline} · ${d.detail}';
  }

  Future<void> _play(ReceivedGame g) async {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    final ref = GameRef.decode(g.gameId);
    if (ref.kind == GameKind.sudoku) {
      if (!g.seen) svc.markSeen(g.id, profile.email);
      context.read<GameState>().playGame(g.gameId);
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GameScreen()));
    } else {
      // Card games keep a single saved game; a challenge replaces it.
      final saveKey = switch (ref.kind) {
        GameKind.freecell => kFreeCellSaveKey,
        GameKind.bubble => kBubbleSaveKey,
        _ => kSolitaireSaveKey,
      };
      if (Storage.getString(saveKey) != null) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Replace your ${ref.gameName} game?'),
            content: Text(
                'Only one ${ref.gameName} game is kept. Playing ${ref.label} '
                'will discard the one in progress.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep playing')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard & play')),
            ],
          ),
        );
        if (ok != true || !mounted) return;
      }
      if (!g.seen) svc.markSeen(g.id, profile.email);
      final Widget screen = switch (ref.kind) {
        GameKind.freecell => FreeCellScreen(initialDeal: ref.deal),
        GameKind.bubble =>
          BubbleScreen(initialDeal: ref.deal, initialVariant: ref.variant),
        _ => SolitaireScreen(initialDeal: ref.deal, initialDraw: ref.draw),
      };
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen));
    }
    if (mounted) setState(_load);
  }

  void _openResult(CompetitorResult r) {
    final svc = context.read<LeaderboardService>();
    final profile = context.read<Profile>();
    if (!r.seen) svc.markNotificationSeen(r.id, profile.email);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeaderboardScreen(gameId: r.gameId)),
    );
    setState(_load);
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
                  'Set your name and email in Settings to receive games and '
                  'results from friends.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              children: [
                _Section<CompetitorResult>(
                  title: "Friends' results",
                  future: _results,
                  empty: 'No competitor results yet.',
                  tile: (r) => ListTile(
                    leading: Icon(
                      r.seen ? Icons.emoji_events_outlined : Icons.emoji_events,
                      color: r.seen
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : const Color(0xFFF9A91C),
                    ),
                    title: Text(
                      '${r.fromName.isEmpty ? r.fromEmail : r.fromName} '
                      'finished ${GameRef.decode(r.gameId).label}',
                      style: TextStyle(
                        fontWeight:
                            r.seen ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(_resultText(r)),
                    trailing: const Icon(Icons.leaderboard),
                    onTap: () => _openResult(r),
                  ),
                ),
                _Section<ReceivedGame>(
                  title: 'Games to play',
                  future: _games,
                  empty: 'No games sent to you yet.',
                  tile: (g) => ListTile(
                    leading: Icon(
                      g.seen ? Icons.mail_outline : Icons.mark_email_unread,
                      color: g.seen
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      GameRef.decode(g.gameId).label,
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
                  ),
                ),
              ],
            ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  final String title;
  final Future<List<T>> future;
  final String empty;
  final Widget Function(T) tile;

  const _Section({
    required this.title,
    required this.future,
    required this.empty,
    required this.tile,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if ((snap.data ?? const []).isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(empty,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )
            else
              for (final item in snap.data!) tile(item),
          ],
        );
      },
    );
  }
}
