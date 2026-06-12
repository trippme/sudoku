import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';

/// The 9×9 playing field. Tapping a cell selects it.
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, c) {
            final size = c.maxWidth;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  for (var r = 0; r < 9; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < 9; col++)
                            Expanded(
                              child: _CellView(
                                index: r * 9 + col,
                                game: game,
                                cellSize: size / 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CellView extends StatelessWidget {
  final int index;
  final GameState game;
  final double cellSize;

  const _CellView({
    required this.index,
    required this.game,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final cell = game.cells[index];
    final r = SudokuEngine.rowOf(index);
    final col = SudokuEngine.colOf(index);
    final selected = game.selected;

    // Thick borders on box boundaries.
    Border border = Border(
      right: BorderSide(
        color: Colors.black,
        width: (col % 3 == 2 && col != 8) ? 2 : 0.5,
      ),
      bottom: BorderSide(
        color: Colors.black,
        width: (r % 3 == 2 && r != 8) ? 2 : 0.5,
      ),
      left: BorderSide(color: Colors.black54, width: col == 0 ? 0 : 0.0),
      top: BorderSide(color: Colors.black54, width: r == 0 ? 0 : 0.0),
    );

    final color = _background(game, index, selected);
    final mistake = game.isMistake(index);

    return GestureDetector(
      onTap: () => game.select(index),
      child: Container(
        decoration: BoxDecoration(color: color, border: border),
        alignment: Alignment.center,
        child: cell.value != 0
            ? Text(
                '${cell.value}',
                style: TextStyle(
                  fontSize: cellSize * 0.6,
                  fontWeight: cell.given ? FontWeight.bold : FontWeight.w500,
                  color: mistake
                      ? Colors.red
                      : cell.given
                          ? Colors.black
                          : const Color(0xFF2E6FB7),
                ),
              )
            : _PencilMarks(marks: cell.marks, cellSize: cellSize),
      ),
    );
  }

  Color _background(GameState game, int index, int? selected) {
    if (selected == null) return Colors.white;
    if (selected == index) return const Color(0xFFBBDEFB); // selected
    final selValue = game.cells[selected].value;
    // Highlight same-value cells.
    if (game.settings.highlightSameValue &&
        selValue != 0 &&
        game.cells[index].value == selValue) {
      return const Color(0xFFFFF1A8);
    }
    // Highlight peers (row/col/box) of the selected cell.
    if (game.settings.highlightPeers &&
        SudokuEngine.peers[selected].contains(index)) {
      return const Color(0xFFEAF1FB);
    }
    return Colors.white;
  }
}

class _PencilMarks extends StatelessWidget {
  final Set<int> marks;
  final double cellSize;
  const _PencilMarks({required this.marks, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(
                        child: Text(
                          marks.contains(row * 3 + c + 1)
                              ? '${row * 3 + c + 1}'
                              : '',
                          style: TextStyle(
                            fontSize: cellSize * 0.22,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
