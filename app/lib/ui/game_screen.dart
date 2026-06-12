import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';
import 'sudoku_grid.dart';
import 'control_pad.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
          Consumer<GameState>(
            builder: (_, game, _) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${game.isDaily ? 'Daily · ' : ''}${game.difficulty.label}'
                  '   ${_fmt(game.elapsed)}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
