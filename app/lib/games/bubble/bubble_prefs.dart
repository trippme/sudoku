import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/services/storage.dart';

/// How bubbles are drawn.
enum BubbleTheme {
  round('Round'),
  shapes('Shapes');

  final String label;
  const BubbleTheme(this.label);
}

/// The player's Bubble Breaker options. Size, level and mode apply to NEW
/// boards; everything else takes effect immediately.
class BubblePrefs {
  bool sound;
  bool motion;
  bool disappear;
  bool autoEliminate;
  BubbleTheme theme;
  BubbleSize size;
  BubbleLevel level;

  /// Mode: true = Standard (empty columns close up), false = Fixed board.
  bool collapse;

  BubblePrefs({
    this.sound = true,
    this.motion = true,
    this.disappear = true,
    this.autoEliminate = false,
    this.theme = BubbleTheme.shapes,
    this.size = BubbleSize.medium,
    this.level = BubbleLevel.normal,
    this.collapse = true,
  });

  BubblePrefs copy() => BubblePrefs(
        sound: sound,
        motion: motion,
        disappear: disappear,
        autoEliminate: autoEliminate,
        theme: theme,
        size: size,
        level: level,
        collapse: collapse,
      );

  /// Do these differ from [other] in a way that needs a new board?
  bool boardSettingsDiffer(BubblePrefs other) =>
      size != other.size || level != other.level || collapse != other.collapse;

  static const _kSound = 'bubble.sound';
  static const _kMotion = 'bubble.motion';
  static const _kDisappear = 'bubble.disappear';
  static const _kAuto = 'bubble.auto';
  static const _kTheme = 'bubble.theme';
  static const _kSize = 'bubble.size';
  static const _kLevel = 'bubble.level';
  static const _kCollapse = 'bubble.collapse';

  static T _pick<T>(List<T> values, String? raw, T fallback) {
    final i = int.tryParse(raw ?? '');
    return (i != null && i >= 0 && i < values.length) ? values[i] : fallback;
  }

  factory BubblePrefs.load() => BubblePrefs(
        sound: Storage.getString(_kSound) != 'false',
        motion: Storage.getString(_kMotion) != 'false',
        disappear: Storage.getString(_kDisappear) != 'false',
        autoEliminate: Storage.getString(_kAuto) == 'true',
        theme: _pick(BubbleTheme.values, Storage.getString(_kTheme),
            BubbleTheme.shapes),
        size: _pick(
            BubbleSize.values, Storage.getString(_kSize), BubbleSize.medium),
        level: _pick(
            BubbleLevel.values, Storage.getString(_kLevel), BubbleLevel.normal),
        collapse: Storage.getString(_kCollapse) != 'false',
      );

  void save() {
    Storage.setString(_kSound, '$sound');
    Storage.setString(_kMotion, '$motion');
    Storage.setString(_kDisappear, '$disappear');
    Storage.setString(_kAuto, '$autoEliminate');
    Storage.setString(_kTheme, '${theme.index}');
    Storage.setString(_kSize, '${size.index}');
    Storage.setString(_kLevel, '${level.index}');
    Storage.setString(_kCollapse, '$collapse');
  }
}
