import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';
import 'sudoku_grid.dart';
import 'control_pad.dart';
import 'leaderboard_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _shareGame(BuildContext context) {
    final game = context.read<GameState>();
    final text = "I'm playing Sudoku game #${game.gameId} "
        '(${game.difficulty.label}). How fast can you solve it? '
        'Open the app and Play by Number → ${game.gameId}.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: "Sudoku game #${game.gameId}" challenge')),
    );
  }

  Future<void> _showHint(BuildContext context) async {
    final game = context.read<GameState>();
    final hint = game.requestHint();
    if (!context.mounted) return;

    if (hint == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No simple hint'),
          content: const Text(
            'No basic technique (single, locked candidate, naked pair) applies '
            'right now. You can reveal the selected cell instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                game.revealSelected();
                Navigator.pop(context);
              },
              child: const Text('Reveal cell'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(hint.technique),
        content: Text(hint.explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              game.applyHint(hint);
              Navigator.pop(context);
            },
            child: Text(hint.placements.isNotEmpty ? 'Place it' : 'Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            tooltip: 'Share this game',
            icon: const Icon(Icons.share),
            onPressed: () => _shareGame(context),
          ),
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              final id = context.read<GameState>().gameId;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LeaderboardScreen(gameId: id),
              ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Consumer<GameState>(
                builder: (_, game, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${game.isDaily ? 'Daily · ' : ''}Game #${game.gameId}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        '${game.difficulty.label} · ${_fmt(game.elapsed)}'
                        '${game.hintsUsed > 0 ? ' · ${game.hintsUsed} hint${game.hintsUsed == 1 ? '' : 's'}' : ''}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: SudokuGrid(),
              ),
              ControlPad(onHint: () => _showHint(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
