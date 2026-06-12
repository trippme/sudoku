import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';

/// The 9×9 playing field. Tapping a cell selects it. When a row, column, or
/// box is completed, its cells flash twice (like the original "Blink
/// Completed").
class SudokuGrid extends StatefulWidget {
  const SudokuGrid({super.key});

  @override
  State<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends State<SudokuGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  int _lastSerial = 0;
  Set<int> _flashCells = {};

  @override
  void initState() {
    super.initState();
    // ~720ms total → two visible pulses (see _intensity).
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  /// 0..1 flash strength for [index]: two sine humps so the group blinks twice.
  double _intensity(int index) {
    if (!_flash.isAnimating || !_flashCells.contains(index)) return 0;
    final s = math.sin(_flash.value * 4 * math.pi); // two positive humps
    return s > 0 ? s : 0;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    // A new completed-group event → start the flash on the next frame.
    if (game.flashSerial != _lastSerial) {
      _lastSerial = game.flashSerial;
      _flashCells = game.flashCells;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flash.forward(from: 0);
      });
    }

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
                                key: ValueKey('cell-${r * 9 + col}'),
                                index: r * 9 + col,
                                game: game,
                                cellSize: size / 9,
                                flash: _intensity(r * 9 + col),
                                // Completed digit flashes green, a completed
                                // row/column/box flashes amber.
                                flashColor: game.flashKind == FlashKind.digit
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFFFC107),
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
  final double flash;
  final Color flashColor;

  const _CellView({
    super.key,
    required this.index,
    required this.game,
    required this.cellSize,
    this.flash = 0,
    this.flashColor = const Color(0xFFFFC107),
  });

  @override
  Widget build(BuildContext context) {
    final cell = game.cells[index];
    final r = SudokuEngine.rowOf(index);
    final col = SudokuEngine.colOf(index);
    final selected = game.selectedCell;

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

    var color = _background(game, index, selected);
    if (flash > 0) {
      // Blink the completed group, echoing the original "Blink Completed".
      color = Color.lerp(color, flashColor, flash) ?? color;
    }
    final mistake = game.isMistake(index);

    return GestureDetector(
      onTap: () => game.pressCell(index),
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
    if (selected == index && selected != null) {
      return const Color(0xFFBBDEFB); // selected cell
    }
    final cell = game.cells[index];
    final hd = game.highlightDigit; // digit-driven highlight (the original feel)

    // Cells holding the active digit glow yellow.
    if (game.settings.highlightSameValue && hd != null && cell.value == hd) {
      return const Color(0xFFFFF1A8);
    }
    // Cells pencil-marked with the active digit glow pink.
    if (game.settings.highlightSameValue &&
        hd != null &&
        cell.value == 0 &&
        cell.marks.contains(hd)) {
      return const Color(0xFFF7D6E8);
    }
    // Shade the selected cell's row/column/box.
    if (game.settings.highlightPeers &&
        selected != null &&
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
