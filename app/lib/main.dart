import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'engine/sudoku_engine.dart';
import 'models/game_state.dart';
import 'ui/sudoku_grid.dart';
import 'ui/control_pad.dart';

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState()..newGame(Difficulty.easy),
      child: MaterialApp(
        title: 'Sudoku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E6FB7),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
                  '${game.difficulty.label}   ${_fmt(game.elapsed)}',
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
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: SudokuGrid(),
              ),
              ControlPad(),
              SizedBox(height: 8),
              _NewGameBar(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewGameBar extends StatelessWidget {
  const _NewGameBar();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameState>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final d in Difficulty.values)
          OutlinedButton(
            onPressed: () => game.newGame(d),
            child: Text(d.label),
          ),
      ],
    );
  }
}
