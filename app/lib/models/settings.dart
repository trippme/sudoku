import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import '../engine/sudoku_engine.dart';
import '../services/storage.dart';

/// How mistakes are surfaced while playing.
enum MistakeMode {
  off, // never highlight
  conflicts, // highlight only logical conflicts (duplicate in a house)
  solution, // highlight any digit that disagrees with the solution
}

/// Input interaction model, matching the original "Enjoy Sudoku":
///  - hybrid: tap a digit OR a cell first; the app follows your lead.
///  - digitThenCell: always pick a digit (it stays selected), then tap cells.
///  - cellThenDigit: always pick a cell, then tap a digit.
enum InputMode { hybrid, digitThenCell, cellThenDigit }

extension InputModeLabel on InputMode {
  String get label => switch (this) {
        InputMode.hybrid => 'Hybrid',
        InputMode.digitThenCell => 'Digit, then cell',
        InputMode.cellThenDigit => 'Cell, then digit',
      };
}

extension MistakeModeLabel on MistakeMode {
  String get label => switch (this) {
        MistakeMode.off => 'Off',
        MistakeMode.conflicts => 'Conflicts only',
        MistakeMode.solution => 'Against solution',
      };
}

/// User preferences, persisted locally.
class Settings extends ChangeNotifier {
  static const _key = 'settings_v1';

  MistakeMode mistakeMode;
  InputMode inputMode;
  bool highlightPeers;
  bool highlightSameValue;
  bool autoRemoveMarks; // remove pencil marks from peers when placing a digit
  bool notifyChallenges; // notify when a challenge/result arrives from a friend
  int dailyDifficulty; // -1 = rotate by weekday; else a Difficulty.index
  int themeModeIndex; // index into ThemeMode.values: 0=system, 1=light, 2=dark

  Settings({
    this.mistakeMode = MistakeMode.conflicts,
    this.inputMode = InputMode.hybrid,
    this.highlightPeers = true,
    this.highlightSameValue = true,
    this.autoRemoveMarks = true,
    this.notifyChallenges = true,
    this.dailyDifficulty = -1,
    this.themeModeIndex = 0,
  });

  /// The fixed daily difficulty the player chose, or null to rotate by weekday.
  Difficulty? get dailyDifficultyOverride =>
      dailyDifficulty < 0 || dailyDifficulty >= Difficulty.values.length
          ? null
          : Difficulty.values[dailyDifficulty];

  /// Light/dark/system preference (default: follow the system — issue #40).
  ThemeMode get themeMode => themeModeIndex >= 0 &&
          themeModeIndex < ThemeMode.values.length
      ? ThemeMode.values[themeModeIndex]
      : ThemeMode.system;

  factory Settings.load() {
    final raw = Storage.getString(_key);
    if (raw == null) return Settings();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return Settings(
        mistakeMode: MistakeMode.values[(m['mistakeMode'] ?? 1) as int],
        inputMode: InputMode.values[(m['inputMode'] ?? 0) as int],
        highlightPeers: (m['highlightPeers'] ?? true) as bool,
        highlightSameValue: (m['highlightSameValue'] ?? true) as bool,
        autoRemoveMarks: (m['autoRemoveMarks'] ?? true) as bool,
        notifyChallenges: (m['notifyChallenges'] ?? true) as bool,
        dailyDifficulty: (m['dailyDifficulty'] ?? -1) as int,
        themeModeIndex: (m['themeMode'] ?? 0) as int,
      );
    } catch (_) {
      return Settings();
    }
  }

  Map<String, dynamic> _toJson() => {
        'mistakeMode': mistakeMode.index,
        'inputMode': inputMode.index,
        'highlightPeers': highlightPeers,
        'highlightSameValue': highlightSameValue,
        'autoRemoveMarks': autoRemoveMarks,
        'notifyChallenges': notifyChallenges,
        'dailyDifficulty': dailyDifficulty,
        'themeMode': themeModeIndex,
      };

  void _save() {
    Storage.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  void setMistakeMode(MistakeMode m) {
    mistakeMode = m;
    _save();
  }

  void setInputMode(InputMode m) {
    inputMode = m;
    _save();
  }

  void setHighlightPeers(bool v) {
    highlightPeers = v;
    _save();
  }

  void setHighlightSameValue(bool v) {
    highlightSameValue = v;
    _save();
  }

  void setAutoRemoveMarks(bool v) {
    autoRemoveMarks = v;
    _save();
  }

  void setNotifyChallenges(bool v) {
    notifyChallenges = v;
    _save();
  }

  void setDailyDifficulty(int v) {
    dailyDifficulty = v;
    _save();
  }

  void setThemeModeIndex(int v) {
    themeModeIndex = v;
    _save();
  }
}
