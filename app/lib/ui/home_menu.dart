import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';
import '../models/stats.dart';
import '../services/game_catalog.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

/// The main menu: continue, new game, daily, stats, settings.
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _playByNumber(BuildContext context) async {
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
    if (number == null || !context.mounted) return;
    context.read<GameState>().playGame(number);
    _open(context, const GameScreen());
  }

  @override
  Widget build(BuildContext context) {
    final hasSaved = GameState.hasSavedGame();
    final stats = context.watch<Stats>();
    final today = DateTime.now();
    final dailyDone = stats.dailyDoneToday(today);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
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
                const SizedBox(height: 28),

                if (hasSaved)
                  _MenuButton(
                    icon: Icons.play_arrow,
                    label: 'Continue',
                    primary: true,
                    onTap: () {
                      final game = context.read<GameState>();
                      if (game.restore()) {
                        _open(context, const GameScreen());
                      }
                    },
                  ),

                _MenuButton(
                  icon: Icons.today,
                  label: dailyDone
                      ? 'Daily Puzzle ✓ (${GameCatalog.dailyDifficultyFor(today).label})'
                      : 'Daily Puzzle (${GameCatalog.dailyDifficultyFor(today).label})',
                  onTap: () {
                    context.read<GameState>().startDaily(today);
                    _open(context, const GameScreen());
                  },
                ),
                _MenuButton(
                  icon: Icons.tag,
                  label: 'Play by Number',
                  onTap: () => _playByNumber(context),
                ),

                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('New Game', style: TextStyle(color: Colors.black54)),
                ),
                for (final d in Difficulty.values)
                  _MenuButton(
                    icon: Icons.grid_on,
                    label: d.label,
                    onTap: () {
                      context.read<GameState>().newGame(d);
                      _open(context, const GameScreen());
                    },
                  ),

                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.bar_chart,
                  label: 'Statistics',
                  onTap: () => _open(context, const StatsScreen()),
                ),
                _MenuButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primary ? const Color(0xFF2E6FB7) : null,
          foregroundColor: primary ? Colors.white : null,
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        onPressed: onTap,
      ),
    );
  }
}
