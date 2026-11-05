import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_prefs.dart';
import 'package:sudoku_app/services/storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('defaults match the classic game', () {
    final p = BubblePrefs.load();
    expect(p.sound, isTrue);
    expect(p.motion, isTrue);
    expect(p.disappear, isTrue);
    expect(p.autoEliminate, isFalse);
    expect(p.theme, BubbleTheme.shapes);
    expect(p.size, BubbleSize.medium);
    expect(p.level, BubbleLevel.normal);
    expect(p.collapse, isTrue);
  });

  test('every option survives a save and load', () {
    BubblePrefs(
      sound: false,
      motion: false,
      disappear: false,
      autoEliminate: true,
      theme: BubbleTheme.round,
      size: BubbleSize.xlarge,
      level: BubbleLevel.hard,
      collapse: false,
    ).save();
    final p = BubblePrefs.load();
    expect(p.sound, isFalse);
    expect(p.motion, isFalse);
    expect(p.disappear, isFalse);
    expect(p.autoEliminate, isTrue);
    expect(p.theme, BubbleTheme.round);
    expect(p.size, BubbleSize.xlarge);
    expect(p.level, BubbleLevel.hard);
    expect(p.collapse, isFalse);
  });

  test('earlier versions\u2019 size and mode keys still load', () async {
    // The size/fixed options shipped before the Options screen, under the same keys.
    SharedPreferences.setMockInitialValues(
        {'bubble.size': '2', 'bubble.collapse': 'false'});
    await Storage.init();
    final p = BubblePrefs.load();
    expect(p.size, BubbleSize.large);
    expect(p.collapse, isFalse);
  });

  test('a corrupt value falls back to the default', () async {
    SharedPreferences.setMockInitialValues(
        {'bubble.size': '99', 'bubble.level': 'x', 'bubble.theme': '-1'});
    await Storage.init();
    final p = BubblePrefs.load();
    expect(p.size, BubbleSize.medium);
    expect(p.level, BubbleLevel.normal);
    expect(p.theme, BubbleTheme.shapes);
  });

  test('only size, level and mode need a new board', () {
    final a = BubblePrefs();
    expect(a.boardSettingsDiffer(a.copy()), isFalse);
    expect((a.copy()..theme = BubbleTheme.round).boardSettingsDiffer(a), isFalse);
    expect((a.copy()..autoEliminate = true).boardSettingsDiffer(a), isFalse);
    expect((a.copy()..size = BubbleSize.small).boardSettingsDiffer(a), isTrue);
    expect((a.copy()..level = BubbleLevel.easy).boardSettingsDiffer(a), isTrue);
    expect((a.copy()..collapse = false).boardSettingsDiffer(a), isTrue);
  });
}
