import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../engine/sudoku_engine.dart';
import '../engine/hint_engine.dart';
import '../services/storage.dart';
import '../services/game_catalog.dart';
import '../services/leaderboard.dart';
import 'settings.dart';
import 'stats.dart';
import 'profile.dart';

/// What triggered a flash, so the UI can colour it (house = amber, an entire
/// digit completed = green), echoing the original "Blink Completed".
enum FlashKind { house, digit }

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

/// A lightweight summary of a saved, in-progress game (for the menu list).
class SavedGameSummary {
  final String category; // slot key suffix: 'd0'..'d3' or 'daily'
  final int gameId;
  final Difficulty difficulty;
  final bool isDaily;
  final int elapsedSeconds;
  final int filledCount; // player-filled cells (progress indicator)
  final int givenCount;
  final int lastPlayed; // epoch millis, for sorting

  SavedGameSummary({
    required this.category,
    required this.gameId,
    required this.difficulty,
    required this.isDaily,
    required this.elapsedSeconds,
    required this.filledCount,
    required this.givenCount,
    required this.lastPlayed,
  });
}

class GameState extends ChangeNotifier {
  // We keep at most one in-progress game per difficulty band, plus one daily —
  // so saved games are stored by *category* ("d0".."d3" or "daily"), not by
  // game number. Starting a new game in a band that already has one replaces it
  // (the menu confirms first). A game is saved only once it has progress.
  static const _keyPrefix = 'game_';
  static const _legacyKey = 'game_v1';

  static String _catKey(String category) => '$_keyPrefix$category';

  /// The category a game belongs to: its daily slot, or its difficulty band.
  static String categoryFor({required bool isDaily, required Difficulty d}) =>
      isDaily ? 'daily' : 'd${d.index}';

  /// The difficulty band of a game number (deterministic, no generation).
  static Difficulty bandOf(int gameId) =>
      Difficulty.values[gameId % Difficulty.values.length];

  final SudokuEngine engine = SudokuEngine();
  final Settings settings;
  final Stats stats;
  final Profile profile;
  final LeaderboardService leaderboard;

  GameState({
    required this.settings,
    required this.stats,
    required this.profile,
    required this.leaderboard,
  });

  List<Cell> cells = List.generate(81, (_) => Cell());
  List<int> solution = List<int>.filled(81, 0);
  Difficulty difficulty = Difficulty.easy;
  int gameId = 0; // the shareable game number
  bool isDaily = false;
  String? dailyDateIso;

  // Per-game counters used for ranking/submission.
  int hintsUsed = 0;
  int mistakesMade = 0;

  // Input state machine, mirroring the original "Enjoy Sudoku":
  //   selectionMode: 0 = neutral, 1 = a digit is selected (digit-then-cell),
  //                  2 = a cell is selected (cell-then-digit).
  //   activeDigit:   the working digit, 1..9 or 10 = erase.
  //   selectedCell:  the focused cell (only meaningful in mode 2).
  int selectionMode = 0;
  int activeDigit = 1;
  int? selectedCell;
  bool pencilMode = false;

  // When a placement completes a house (row/column/box) or all nine of a digit,
  // these hold the cells to flash, what kind it is (for colour), and a serial
  // the UI watches to trigger the animation.
  Set<int> flashCells = {};
  FlashKind flashKind = FlashKind.house;
  int flashSerial = 0;

  /// True when [d] is the selected digit shown green on the keypad.
  bool isDigitActive(int d) => selectionMode == 1 && activeDigit == d;

  /// The digit whose occurrences should be highlighted across the board
  /// (yellow for placed, pink for pencil marks), or null for none.
  int? get highlightDigit {
    if (activeDigit < 1 || activeDigit > 9) return null;
    if (selectionMode == 1) return activeDigit;
    if (selectionMode == 2 &&
        selectedCell != null &&
        cells[selectedCell!].value == activeDigit) {
      return activeDigit;
    }
    return null;
  }

  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];

  // Timer
  Duration elapsed = Duration.zero;
  Timer? _timer;
  bool _solved = false;
  bool _completionRecorded = false;
  int lastPlayed = 0; // epoch millis of last save

  bool get isSolved => _solved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// True once the player has entered any digit or pencil mark. A game is only
  /// persisted (kept in the in-progress list) once it has progress.
  bool get hasProgress {
    for (final c in cells) {
      if (!c.given && (c.value != 0 || c.marks.isNotEmpty)) return true;
    }
    return false;
  }

  // ---- Game lifecycle ---------------------------------------------------

  void newGame(Difficulty d) {
    // Always a fresh game in band [d], replacing any existing one there
    // (the menu confirms before calling this when that band is occupied).
    final id = GameCatalog.randomGameId(d);
    _install(id, GameCatalog.puzzleForGame(id), daily: false, dailyIso: null);
    stats.recordStart(difficulty);
  }

  /// Start the deterministic daily puzzle for [date] — resuming saved progress
  /// on today's daily if you've already begun it, else starting it fresh.
  void startDaily(DateTime date) {
    final id = GameCatalog.dailyGameId(date);
    final saved = savedSlot('daily');
    if (saved != null && saved.gameId == id && resumeSlot('daily')) return;
    _install(id, GameCatalog.puzzleForGame(id),
        daily: true, dailyIso: Stats.isoDate(date));
    stats.recordStart(difficulty);
  }

  /// Start a specific game by its number (Play by Number / shared games).
  /// Resumes if that exact number is the one already saved in its band.
  void playGame(int id) {
    final cat = categoryFor(isDaily: false, d: bandOf(id));
    final saved = savedSlot(cat);
    if (saved != null && saved.gameId == id && resumeSlot(cat)) return;
    _install(id, GameCatalog.puzzleForGame(id), daily: false, dailyIso: null);
    stats.recordStart(difficulty);
  }

  void _install(
    int id,
    Puzzle puzzle, {
    required bool daily,
    required String? dailyIso,
  }) {
    final givens = puzzle.givens;
    final sol = puzzle.solution;
    gameId = id;
    // Difficulty (and slot category) come from the number's band, so they're
    // consistent everywhere without depending on the rater.
    difficulty = bandOf(id);
    solution = sol;
    isDaily = daily;
    dailyDateIso = dailyIso;
    // Starting fresh in this category discards whatever was there.
    Storage.remove(_catKey(categoryFor(isDaily: daily, d: difficulty)));
    hintsUsed = 0;
    mistakesMade = 0;
    lastPlayed = 0;
    lastOutcome = null;
    cells = List.generate(
      81,
      (i) => Cell(value: givens[i], given: givens[i] != 0),
    );
    // Initial mode follows the input-method setting (like the original's
    // `s.j = I.ha`): hybrid starts neutral, the others start pre-armed.
    selectionMode = switch (settings.inputMode) {
      InputMode.hybrid => 0,
      InputMode.digitThenCell => 1,
      InputMode.cellThenDigit => 2,
    };
    activeDigit = 1;
    selectedCell = null;
    pencilMode = false;
    flashCells = {};
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

  // ---- Input state machine (faithful to the original) -------------------

  bool get _hybrid => settings.inputMode == InputMode.hybrid;

  /// A keypad press: [d] is 1..9, or 10 for Erase.
  void pressDigit(int d) {
    if (_solved) return;
    if (selectionMode == 2) {
      // A cell is already selected → set the digit and drop it in.
      activeDigit = d;
      if (selectedCell != null) _commit(selectedCell!);
    } else if (_hybrid && selectionMode == 1 && activeDigit == d) {
      // Re-tapping the green digit clears the selection (hybrid only).
      selectionMode = 0;
    } else {
      // Select this digit; it stays armed for the next cell taps.
      selectionMode = 1;
      activeDigit = d;
    }
    notifyListeners();
  }

  /// A board press on [cell].
  void pressCell(int cell) {
    if (_solved) {
      selectedCell = cell;
      notifyListeners();
      return;
    }
    if (selectionMode != 1) {
      // Neutral or cell-selected → (de)select the cell.
      if (_hybrid && selectionMode == 2 && selectedCell == cell) {
        selectionMode = 0;
        selectedCell = null;
      } else {
        if (selectionMode == 0) selectionMode = 2;
        selectedCell = cell;
        // Highlight follows the digit already in the tapped cell.
        if (cells[cell].value != 0) activeDigit = cells[cell].value;
      }
    } else {
      // A digit is armed → just fill the cell. Don't make it the "selected"
      // cell, so the row/column/box stay unshaded — only place the number.
      selectedCell = null;
      _commit(cell);
    }
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

  /// Applies [activeDigit] (place / toggle-off / erase / pencil) to [cell],
  /// recording undo only if something actually changed. Mirrors `s.xb`.
  void _commit(int cell) {
    final snapshot = _Snapshot(cells);
    if (_apply(cell)) {
      _undo.add(snapshot);
      _redo.clear();
      _maybeFlashCompletedHouses(cell);
      _afterChange();
    }
  }

  /// If placing into [cell] just completed all nine of its digit, or its row,
  /// column, or box, mark the relevant cells to flash. A finished digit takes
  /// priority (it's the more satisfying "you're done with this number" cue).
  void _maybeFlashCompletedHouses(int cell) {
    final digit = cells[cell].value;
    if (digit == 0) return; // erase/toggle-off can't complete anything

    // All nine of this digit placed, with no conflicts → flash them green.
    final ofDigit = [for (var i = 0; i < 81; i++) if (cells[i].value == digit) i];
    if (ofDigit.length == 9 && ofDigit.every((i) => !hasConflict(i))) {
      flashCells = ofDigit.toSet();
      flashKind = FlashKind.digit;
      flashSerial++;
      return;
    }

    // Otherwise, a completed row/column/box → flash that house amber.
    final r = SudokuEngine.rowOf(cell);
    final c = SudokuEngine.colOf(cell);
    final bRow = (r ~/ 3) * 3, bCol = (c ~/ 3) * 3;
    final houses = <List<int>>[
      [for (var i = 0; i < 9; i++) r * 9 + i], // row
      [for (var i = 0; i < 9; i++) i * 9 + c], // column
      [
        for (var dr = 0; dr < 3; dr++)
          for (var dc = 0; dc < 3; dc++) (bRow + dr) * 9 + (bCol + dc)
      ], // box
    ];
    final toFlash = <int>{};
    for (final house in houses) {
      final seen = <int>{};
      var full = true;
      for (final x in house) {
        if (cells[x].value == 0) {
          full = false;
          break;
        }
        seen.add(cells[x].value);
      }
      if (full && seen.length == 9) toFlash.addAll(house);
    }
    if (toFlash.isNotEmpty) {
      flashCells = toFlash;
      flashKind = FlashKind.house;
      flashSerial++;
    }
  }

  bool _apply(int cell) {
    final c = cells[cell];
    if (c.given) return false;

    if (activeDigit >= 10) {
      // Erase mode: clear a value, else clear pencil marks.
      if (c.value != 0) {
        c.value = 0;
        c.marks.clear();
        return true;
      }
      if (c.marks.isNotEmpty) {
        c.marks.clear();
        return true;
      }
      return false;
    }

    if (pencilMode) {
      if (c.value != 0) return false;
      if (!c.marks.remove(activeDigit)) c.marks.add(activeDigit);
      return true;
    }

    // Normal placement. Tapping the digit already in the cell removes it.
    if (c.value == activeDigit) {
      c.value = 0;
      return true;
    }
    // A wrong digit (disagrees with the unique solution) counts as a mistake.
    if (solution[cell] != 0 && activeDigit != solution[cell]) {
      mistakesMade++;
    }
    c.value = activeDigit;
    c.marks.clear();
    if (settings.autoRemoveMarks) {
      for (final p in SudokuEngine.peers[cell]) {
        cells[p].marks.remove(activeDigit);
      }
    }
    return true;
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
    hintsUsed++;
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
    final i = selectedCell;
    if (i == null || cells[i].given || _solved || solution[i] == 0) return;
    if (cells[i].value == solution[i]) return;
    hintsUsed++;
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
      _submitResult();
      // finished game leaves the in-progress list
      Storage.remove(_catKey(categoryFor(isDaily: isDaily, d: difficulty)));
    }
  }

  /// Fire-and-forget submit to the backend (no-op if no email set or offline).
  /// Stores the outcome so the UI can show your rank.
  SubmitOutcome? lastOutcome;
  void _submitResult() {
    if (profile.email.isEmpty) return;
    leaderboard
        .submitResult(
          gameId: gameId,
          email: profile.email,
          name: profile.name,
          seconds: elapsed.inSeconds,
          hints: hintsUsed,
          mistakes: mistakesMade,
          difficulty: difficulty.index,
        )
        .then((outcome) {
      if (outcome != null) {
        lastOutcome = outcome;
        notifyListeners();
      }
    });
  }

  // ---- Persistence ------------------------------------------------------

  String _encode() => jsonEncode({
        'gameId': gameId,
        'difficulty': difficulty.index,
        'isDaily': isDaily,
        'dailyDateIso': dailyDateIso,
        'elapsed': elapsed.inSeconds,
        'hintsUsed': hintsUsed,
        'mistakesMade': mistakesMade,
        'lastPlayed': lastPlayed,
        'solution': solution,
        'cells': [
          for (final c in cells)
            {'v': c.value, 'g': c.given, 'm': c.marks.toList()}
        ],
      });

  /// Persist the active game to its category slot — but only once it has
  /// progress, so untouched games never clutter the in-progress list.
  void _save() {
    if (_solved || gameId == 0) return;
    final key = _catKey(categoryFor(isDaily: isDaily, d: difficulty));
    if (!hasProgress) {
      Storage.remove(key);
      return;
    }
    lastPlayed = DateTime.now().millisecondsSinceEpoch;
    Storage.setString(key, _encode());
  }

  void _saveLight() => _save();

  static SavedGameSummary? _decode(String category, String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      var filled = 0, givens = 0;
      for (final c in (m['cells'] as List)) {
        if (c['g'] as bool) {
          givens++;
        } else if ((c['v'] as int) != 0) {
          filled++;
        }
      }
      return SavedGameSummary(
        category: category,
        gameId: (m['gameId'] ?? 0) as int,
        difficulty: Difficulty.values[m['difficulty'] as int],
        isDaily: (m['isDaily'] ?? false) as bool,
        elapsedSeconds: (m['elapsed'] ?? 0) as int,
        filledCount: filled,
        givenCount: givens,
        lastPlayed: (m['lastPlayed'] ?? 0) as int,
      );
    } catch (_) {
      return null;
    }
  }

  /// Summary of the saved game in [category], or null if none.
  static SavedGameSummary? savedSlot(String category) {
    final raw = Storage.getString(_catKey(category));
    return raw == null ? null : _decode(category, raw);
  }

  /// All saved in-progress games (at most one per band + daily), newest first.
  static List<SavedGameSummary> listSavedGames() {
    final out = <SavedGameSummary>[];
    for (final key in Storage.getKeys()) {
      if (!key.startsWith(_keyPrefix) || key == _legacyKey) continue;
      final raw = Storage.getString(key);
      if (raw == null) continue;
      final s = _decode(key.substring(_keyPrefix.length), raw);
      if (s != null) out.add(s);
    }
    out.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return out;
  }

  /// Delete the saved game in [category].
  static void deleteSlot(String category) => Storage.remove(_catKey(category));

  /// One-time migration of the old single-slot save (`game_v1`) into its
  /// category slot. Safe to call on every launch.
  static void migrateLegacySave() {
    final raw = Storage.getString(_legacyKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final id = (m['gameId'] ?? 0) as int;
        final daily = (m['isDaily'] ?? false) as bool;
        final cat = categoryFor(isDaily: daily, d: bandOf(id));
        if (id != 0 && savedSlot(cat) == null) {
          Storage.setString(_catKey(cat), raw);
        }
      } catch (_) {/* ignore */}
      Storage.remove(_legacyKey);
    }
  }

  /// Load the saved game in [category] into this state. Returns false if
  /// missing/corrupt.
  bool resumeSlot(String category) {
    final raw = Storage.getString(_catKey(category));
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      gameId = (m['gameId'] ?? 0) as int;
      difficulty = Difficulty.values[m['difficulty'] as int];
      isDaily = (m['isDaily'] ?? false) as bool;
      dailyDateIso = m['dailyDateIso'] as String?;
      elapsed = Duration(seconds: (m['elapsed'] ?? 0) as int);
      hintsUsed = (m['hintsUsed'] ?? 0) as int;
      mistakesMade = (m['mistakesMade'] ?? 0) as int;
      lastPlayed = (m['lastPlayed'] ?? 0) as int;
      solution = (m['solution'] as List).map((e) => e as int).toList();
      cells = [
        for (final c in (m['cells'] as List))
          Cell(
            value: c['v'] as int,
            given: c['g'] as bool,
            marks: {for (final d in (c['m'] as List)) d as int},
          )
      ];
      selectionMode = switch (settings.inputMode) {
        InputMode.hybrid => 0,
        InputMode.digitThenCell => 1,
        InputMode.cellThenDigit => 2,
      };
      activeDigit = 1;
      selectedCell = null;
      pencilMode = false;
      flashCells = {};
      lastOutcome = null;
      _undo.clear();
      _redo.clear();
      _solved = false;
      _completionRecorded = false;
      _startTimer();
      notifyListeners();
      return true;
    } catch (_) {
      Storage.remove(_catKey(category));
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
