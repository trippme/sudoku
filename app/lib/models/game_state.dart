import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../engine/sudoku_engine.dart';
import '../engine/hint_engine.dart';
import '../services/storage.dart';
import '../services/daily.dart';
import 'settings.dart';
import 'stats.dart';

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
  static const _saveKey = 'game_v1';

  final SudokuEngine engine = SudokuEngine();
  final Settings settings;
  final Stats stats;

  GameState({required this.settings, required this.stats});

  List<Cell> cells = List.generate(81, (_) => Cell());
  List<int> solution = List<int>.filled(81, 0);
  Difficulty difficulty = Difficulty.easy;
  bool isDaily = false;
  String? dailyDateIso;

  int? selected; // selected cell index
  bool pencilMode = false;

  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];

  // Timer
  Duration elapsed = Duration.zero;
  Timer? _timer;
  bool _solved = false;
  bool _completionRecorded = false;

  bool get isSolved => _solved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  // ---- Game lifecycle ---------------------------------------------------

  void newGame(Difficulty d) {
    final puzzle = engine.generate(d);
    _install(puzzle.givens, puzzle.solution, puzzle.difficulty,
        daily: false, dailyIso: null);
    stats.recordStart(puzzle.difficulty);
  }

  /// Start (or resume in-progress) the deterministic daily puzzle for [date].
  void startDaily(DateTime date) {
    final puzzle = DailyPuzzle.generate(date);
    _install(puzzle.givens, puzzle.solution, puzzle.difficulty,
        daily: true, dailyIso: Stats.isoDate(date));
    stats.recordStart(puzzle.difficulty);
  }

  void _install(
    List<int> givens,
    List<int> sol,
    Difficulty d, {
    required bool daily,
    required String? dailyIso,
  }) {
    difficulty = d;
    solution = sol;
    isDaily = daily;
    dailyDateIso = dailyIso;
    cells = List.generate(
      81,
      (i) => Cell(value: givens[i], given: givens[i] != 0),
    );
    selected = null;
    pencilMode = false;
    _undo.clear();
    _redo.clear();
    _solved = false;
    _completionRecorded = false;
    elapsed = Duration.zero;
    _startTimer();
    _save();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_solved) return;
      elapsed += const Duration(seconds: 1);
      _saveLight();
      notifyListeners();
    });
  }

  // ---- Selection / modes ------------------------------------------------

  void select(int index) {
    selected = index;
    notifyListeners();
  }

  void togglePencil() {
    pencilMode = !pencilMode;
    notifyListeners();
  }

  // ---- Editing ----------------------------------------------------------

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
      if (settings.autoRemoveMarks) {
        for (final p in SudokuEngine.peers[i]) {
          cells[p].marks.remove(digit);
        }
      }
    }
    _afterChange();
  }

  void erase() {
    final i = selected;
    if (i == null || cells[i].given || _solved) return;
    if (cells[i].value == 0 && cells[i].marks.isEmpty) return;
    _pushUndo();
    cells[i].value = 0;
    cells[i].marks.clear();
    _afterChange();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_Snapshot(cells));
    cells = _undo.removeLast().cells;
    _afterChange();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_Snapshot(cells));
    cells = _redo.removeLast().cells;
    _afterChange();
  }

  /// Fill every empty cell's pencil marks with its current candidates.
  void autoPencil() {
    _pushUndo();
    for (var i = 0; i < 81; i++) {
      if (cells[i].value != 0) continue;
      final used = <int>{};
      for (final p in SudokuEngine.peers[i]) {
        if (cells[p].value != 0) used.add(cells[p].value);
      }
      cells[i].marks = {
        for (var d = 1; d <= 9; d++)
          if (!used.contains(d)) d
      };
    }
    _afterChange();
  }

  void _afterChange() {
    _checkSolved();
    _save();
    notifyListeners();
  }

  // ---- Hints ------------------------------------------------------------

  /// Returns the next logical hint, or null if no supported technique applies.
  Hint? requestHint() {
    final grid = [for (final c in cells) c.value];
    return HintEngine.nextHint(grid);
  }

  /// Applies a hint's placements/eliminations to the board.
  void applyHint(Hint hint) {
    _pushUndo();
    for (final p in hint.placements) {
      cells[p.cell].value = p.digit;
      cells[p.cell].marks.clear();
      if (settings.autoRemoveMarks) {
        for (final peer in SudokuEngine.peers[p.cell]) {
          cells[peer].marks.remove(p.digit);
        }
      }
    }
    for (final e in hint.eliminations) {
      cells[e.cell].marks.remove(e.digit);
    }
    _afterChange();
  }

  /// Reveal the correct digit for the selected cell (a "give up on this cell").
  void revealSelected() {
    final i = selected;
    if (i == null || cells[i].given || _solved || solution[i] == 0) return;
    if (cells[i].value == solution[i]) return;
    _pushUndo();
    cells[i].value = solution[i];
    cells[i].marks.clear();
    _afterChange();
  }

  // ---- Mistake / conflict detection ------------------------------------

  /// A logical conflict: the same value appears in a peer (row/col/box).
  bool hasConflict(int i) {
    final v = cells[i].value;
    if (v == 0) return false;
    for (final p in SudokuEngine.peers[i]) {
      if (cells[p].value == v) return true;
    }
    return false;
  }

  /// Whether [i] should be drawn as a mistake, per the current setting.
  bool isMistake(int i) {
    final v = cells[i].value;
    if (v == 0 || cells[i].given) return false;
    switch (settings.mistakeMode) {
      case MistakeMode.off:
        return false;
      case MistakeMode.conflicts:
        return hasConflict(i);
      case MistakeMode.solution:
        return solution[i] != 0 && v != solution[i];
    }
  }

  int placedCount(int digit) => cells.where((c) => c.value == digit).length;

  void _checkSolved() {
    for (var i = 0; i < 81; i++) {
      if (cells[i].value != solution[i]) return;
    }
    _solved = true;
    _timer?.cancel();
    if (!_completionRecorded) {
      _completionRecorded = true;
      stats.recordCompletion(
        difficulty: difficulty,
        seconds: elapsed.inSeconds,
        daily: isDaily,
        now: DateTime.now(),
      );
      Storage.remove(_saveKey); // finished game no longer needs resuming
    }
  }

  // ---- Persistence ------------------------------------------------------

  String _encode() => jsonEncode({
        'difficulty': difficulty.index,
        'isDaily': isDaily,
        'dailyDateIso': dailyDateIso,
        'elapsed': elapsed.inSeconds,
        'solution': solution,
        'cells': [
          for (final c in cells)
            {'v': c.value, 'g': c.given, 'm': c.marks.toList()}
        ],
      });

  void _save() {
    if (_solved) return;
    Storage.setString(_saveKey, _encode());
  }

  // Lightweight save used by the per-second timer (same payload; kept separate
  // so the intent is clear and easy to throttle later if needed).
  void _saveLight() => _save();

  /// True if a resumable saved game exists.
  static bool hasSavedGame() => Storage.getString(_saveKey) != null;

  /// Restore a previously saved in-progress game. Returns false if none/corrupt.
  bool restore() {
    final raw = Storage.getString(_saveKey);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      difficulty = Difficulty.values[m['difficulty'] as int];
      isDaily = (m['isDaily'] ?? false) as bool;
      dailyDateIso = m['dailyDateIso'] as String?;
      elapsed = Duration(seconds: (m['elapsed'] ?? 0) as int);
      solution = (m['solution'] as List).map((e) => e as int).toList();
      cells = [
        for (final c in (m['cells'] as List))
          Cell(
            value: c['v'] as int,
            given: c['g'] as bool,
            marks: {for (final d in (c['m'] as List)) d as int},
          )
      ];
      selected = null;
      pencilMode = false;
      _undo.clear();
      _redo.clear();
      _solved = false;
      _completionRecorded = false;
      _startTimer();
      notifyListeners();
      return true;
    } catch (_) {
      Storage.remove(_saveKey);
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
