import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/stats.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  String _fmt(int? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<Stats>();
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          // Daily streak card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Metric(
                    label: 'Current streak',
                    value: '🔥 ${stats.currentStreak}',
                  ),
                  _Metric(
                    label: 'Longest streak',
                    value: '${stats.longestStreak}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Per-difficulty table
          Card(
            child: Column(
              children: [
                const ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Difficulty', style: _h)),
                      Expanded(flex: 2, child: Text('Won', style: _h)),
                      Expanded(flex: 2, child: Text('Best', style: _h)),
                      Expanded(flex: 2, child: Text('Avg', style: _h)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (final d in Difficulty.values)
                  ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Expanded(flex: 3, child: Text(d.label)),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${stats.byDifficulty[d]!.completed}'
                            '/${stats.byDifficulty[d]!.played}',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_fmt(stats.byDifficulty[d]!.bestSeconds)),
                        ),
                        Expanded(
                          flex: 2,
                          child:
                              Text(_fmt(stats.byDifficulty[d]!.averageSeconds)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent games (a local "leaderboard" of your own times)
          if (stats.recent.isNotEmpty) ...[
            Text('Recent games',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in stats.recent.take(15))
              ListTile(
                dense: true,
                leading: Icon(
                  r.daily ? Icons.today : Icons.grid_on,
                  size: 20,
                ),
                title: Text('${r.difficulty.label}${r.daily ? ' · Daily' : ''}'),
                subtitle: Text(r.dateIso),
                trailing: Text(
                  _fmt(r.seconds),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No games finished yet.')),
            ),
        ],
      ),
    );
  }

  static const _h = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
