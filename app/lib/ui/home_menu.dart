import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';
import '../models/stats.dart';
import '../models/profile.dart';
import '../services/game_catalog.dart';
import '../services/leaderboard.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'inbox_screen.dart';

/// The main menu: resume any in-progress game, start a new one, daily, stats,
/// settings. Multiple games can be in progress at once (issue #1, "ideal").
class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int _unseen = 0;

  @override
  void initState() {
    super.initState();
    _refreshInbox();
  }

  Future<void> _refreshInbox() async {
    final profile = context.read<Profile>();
    if (!profile.hasIdentity) return;
    final games = await context.read<LeaderboardService>().inbox(profile.email);
    if (mounted) {
      setState(() => _unseen = games.where((g) => !g.seen).length);
    }
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Push a screen, then refresh the in-progress list (and inbox) on return.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      setState(() {});
      _refreshInbox();
    }
  }

  void _startNew(void Function() start) {
    start();
    _open(const GameScreen());
  }

  Future<void> _playByNumber() async {
    final controller = TextEditingController();
    final number = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Play by number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Game number',
            hintText: 'e.g. 1234',
          ),
          onSubmitted: (_) =>
              Navigator.pop(ctx, int.tryParse(controller.text.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Play'),
          ),
        ],
      ),
    );
    if (number == null || !mounted) return;
    _startNew(() => context.read<GameState>().playGame(number));
  }

  void _delete(int id) {
    GameState.deleteSavedGame(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<Stats>();
    final today = DateTime.now();
    final dailyDone = stats.dailyDoneToday(today);
    final saved = GameState.listSavedGames();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Sudoku',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E6FB7),
                  ),
                ),
                const SizedBox(height: 6),
                if (stats.currentStreak > 0)
                  Text(
                    '🔥 Daily streak: ${stats.currentStreak}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 24),

                // In-progress games (resume any of them).
                if (saved.isNotEmpty) ...[
                  const _SectionLabel('In Progress'),
                  for (final g in saved)
                    _InProgressTile(
                      summary: g,
                      timeText: _fmt(g.elapsedSeconds),
                      onResume: () => _startNew(
                        () => context.read<GameState>().resumeGame(g.gameId),
                      ),
                      onDelete: () => _delete(g.gameId),
                    ),
                  const SizedBox(height: 12),
                ],

                _MenuButton(
                  icon: Icons.today,
                  label: dailyDone
                      ? 'Daily Puzzle ✓ (${GameCatalog.dailyDifficultyFor(today).label})'
                      : 'Daily Puzzle (${GameCatalog.dailyDifficultyFor(today).label})',
                  onTap: () => _startNew(
                    () => context.read<GameState>().startDaily(today),
                  ),
                ),
                _MenuButton(
                  icon: Icons.tag,
                  label: 'Play by Number',
                  onTap: _playByNumber,
                ),

                const SizedBox(height: 8),
                const _SectionLabel('New Game'),
                for (final d in Difficulty.values)
                  _MenuButton(
                    icon: Icons.grid_on,
                    label: d.label,
                    onTap: () =>
                        _startNew(() => context.read<GameState>().newGame(d)),
                  ),

                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.inbox,
                  label: _unseen > 0 ? 'Inbox ($_unseen new)' : 'Inbox',
                  onTap: () => _open(const InboxScreen()),
                ),
                _MenuButton(
                  icon: Icons.bar_chart,
                  label: 'Statistics',
                  onTap: () => _open(const StatsScreen()),
                ),
                _MenuButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => _open(const SettingsScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );
}

class _InProgressTile extends StatelessWidget {
  final SavedGameSummary summary;
  final String timeText;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _InProgressTile({
    required this.summary,
    required this.timeText,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final empties = 81 - summary.givenCount;
    return Card(
      color: const Color(0xFFE7F0FB),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(summary.isDaily ? Icons.today : Icons.play_arrow,
            color: const Color(0xFF2E6FB7)),
        title: Text(
          '${summary.isDaily ? 'Daily · ' : ''}${summary.difficulty.label}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '#${summary.gameId} · $timeText · ${summary.filledCount}/$empties filled',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Discard this game',
          onPressed: onDelete,
        ),
        onTap: onResume,
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        onPressed: onTap,
      ),
    );
  }
}
