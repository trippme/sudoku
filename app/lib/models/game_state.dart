import 'dart:async';
import 'package:flutter/foundation.dart';
import '../engine/sudoku_engine.dart';

/// Holds one cell's worth of mutable play state.
class Cell {
  int value; // 0 = empty
  final bool given; // part of the original puzzle (immutable)
  Set<int> marks; // pencil marks

  Cell({this.value = 0, this.given = false, Set<int>? marks})
      : marks = marks ?? <int>{};

  Cell copy() => Cell(value: value, given: given, marks: Set.of(marks));
}

/// A single undoable snapshot of the board.
class _Snapshot {
  final List<Cell> cells;
  _Snapshot(List<Cell> source) : cells = source.map((c) => c.copy()).toList();
}

class GameState extends ChangeNotifier {
  final SudokuEngine engine = SudokuEngine();

  List<Cell> cells = List.generate(81, (_) => Cell());
  List<int> solution = List<int>.filled(81, 0);
  Difficulty difficulty = Difficulty.easy;

  int? selected; // selected cell index
  bool pencilMode = false;
  bool markMistakes = true;

  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];

  // Timer
  Duration elapsed = Duration.zero;
  Timer? _timer;
  bool _solved = false;

  bool get isSolved => _solved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void newGame(Difficulty d) {
    final puzzle = engine.generate(d);
    difficulty = puzzle.difficulty;
    solution = puzzle.solution;
    cells = List.generate(
      81,
      (i) => Cell(value: puzzle.givens[i], given: puzzle.givens[i] != 0),
    );
    selected = null;
    pencilMode = false;
    _undo.clear();
    _redo.clear();
    _solved = false;
    elapsed = Duration.zero;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_solved) return;
      elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void select(int index) {
    selected = index;
    notifyListeners();
  }

  void togglePencil() {
    pencilMode = !pencilMode;
    notifyListeners();
  }

  void _pushUndo() {
    _undo.add(_Snapshot(cells));
    _redo.clear();
  }

  /// Enter [digit] (1..9) into the selected cell, or toggle a pencil mark.
  void input(int digit) {
    final i = selected;
    if (i == null || cells[i].given || _solved) return;

    if (pencilMode) {
      _pushUndo();
      if (!cells[i].marks.remove(digit)) cells[i].marks.add(digit);
    } else {
      if (cells[i].value == digit) return;
      _pushUndo();
      cells[i].value = digit;
      cells[i].marks.clear();
      // Tidy: remove this digit from peers' pencil marks.
      for (final p in SudokuEngine.peers[i]) {
        cells[p].marks.remove(digit);
      }
    }
    _checkSolved();
    notifyListeners();
  }

  void erase() {
    final i = selected;
    if (i == null || cells[i].given || _solved) return;
    if (cells[i].value == 0 && cells[i].marks.isEmpty) return;
    _pushUndo();
    cells[i].value = 0;
    cells[i].marks.clear();
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_Snapshot(cells));
    cells = _undo.removeLast().cells;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_Snapshot(cells));
    cells = _redo.removeLast().cells;
    notifyListeners();
  }

  /// Fill the selected cell with the correct digit from the solution.
  void hint() {
    final i = selected;
    if (i == null || cells[i].given || _solved || solution[i] == 0) return;
    if (cells[i].value == solution[i]) return;
    _pushUndo();
    cells[i].value = solution[i];
    cells[i].marks.clear();
    for (final p in SudokuEngine.peers[i]) {
      cells[p].marks.remove(solution[i]);
    }
    _checkSolved();
    notifyListeners();
  }

  /// True if [i] holds a value that conflicts with the known solution.
  bool isMistake(int i) {
    if (!markMistakes) return false;
    final v = cells[i].value;
    return v != 0 && !cells[i].given && solution[i] != 0 && v != solution[i];
  }

  /// How many of [digit] are already placed correctly (for digit-pad badges).
  int placedCount(int digit) =>
      cells.where((c) => c.value == digit).length;

  void _checkSolved() {
    for (var i = 0; i < 81; i++) {
      if (cells[i].value != solution[i]) return;
    }
    _solved = true;
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
