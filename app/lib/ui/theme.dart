import 'package:flutter/material.dart';

const _seed = Color(0xFF2E6FB7);

/// App-specific colours that don't map cleanly onto [ColorScheme] — mostly the
/// Sudoku board's cell shades and highlights. Generic things (text, accents,
/// errors, surfaces) come from the ColorScheme so they adapt automatically; the
/// values here have explicit light/dark variants for a legible board in both.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color gridLine; // box/cell borders
  final Color cellBg; // an ordinary empty cell
  final Color cellSelected; // the focused cell
  final Color cellPeer; // its row/column/box shading
  final Color highlightSame; // cells holding the active digit (yellow)
  final Color highlightPencil; // cells pencil-marked with it (pink)
  final Color keypadBg; // an unselected digit/tool button
  final Color doneBg; // a fully-placed digit button
  final Color armed; // green: armed digit / active tool (same in both)
  final Color hintHouse; // a hint's highlighted region (green)
  final Color hintTarget; // a hint's exact answer cell (stronger green)

  const AppColors({
    required this.gridLine,
    required this.cellBg,
    required this.cellSelected,
    required this.cellPeer,
    required this.highlightSame,
    required this.highlightPencil,
    required this.keypadBg,
    required this.doneBg,
    required this.armed,
    required this.hintHouse,
    required this.hintTarget,
  });

  static const light = AppColors(
    gridLine: Color(0xFF222222),
    cellBg: Colors.white,
    cellSelected: Color(0xFFBBDEFB),
    cellPeer: Color(0xFFEAF1FB),
    highlightSame: Color(0xFFFFF1A8),
    highlightPencil: Color(0xFFF7D6E8),
    keypadBg: Color(0xFFE7F0FB),
    doneBg: Color(0xFFEEEEEE),
    armed: Color(0xFF4CAF50),
    hintHouse: Color(0xFFC5E8C9),
    hintTarget: Color(0xFF80C784),
  );

  // Brighter/more-saturated than a flat near-black so the board has life and the
  // highlights pop, while keeping white digits readable on the tinted cells
  // (issue #47).
  static const dark = AppColors(
    gridLine: Color(0xFF8A95A4),
    cellBg: Color(0xFF222B3C),
    cellSelected: Color(0xFF3D6098),
    cellPeer: Color(0xFF324158),
    highlightSame: Color(0xFF8A6F16), // gold, not muddy olive
    highlightPencil: Color(0xFF8E3A6A), // vivid pink
    keypadBg: Color(0xFF2C3A50),
    doneBg: Color(0xFF2A3242),
    armed: Color(0xFF4CAF50),
    hintHouse: Color(0xFF3C6044),
    hintTarget: Color(0xFF50A05E),
  );

  @override
  AppColors copyWith({
    Color? gridLine,
    Color? cellBg,
    Color? cellSelected,
    Color? cellPeer,
    Color? highlightSame,
    Color? highlightPencil,
    Color? keypadBg,
    Color? doneBg,
    Color? armed,
    Color? hintHouse,
    Color? hintTarget,
  }) =>
      AppColors(
        gridLine: gridLine ?? this.gridLine,
        cellBg: cellBg ?? this.cellBg,
        cellSelected: cellSelected ?? this.cellSelected,
        cellPeer: cellPeer ?? this.cellPeer,
        highlightSame: highlightSame ?? this.highlightSame,
        highlightPencil: highlightPencil ?? this.highlightPencil,
        keypadBg: keypadBg ?? this.keypadBg,
        doneBg: doneBg ?? this.doneBg,
        armed: armed ?? this.armed,
        hintHouse: hintHouse ?? this.hintHouse,
        hintTarget: hintTarget ?? this.hintTarget,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      cellBg: Color.lerp(cellBg, other.cellBg, t)!,
      cellSelected: Color.lerp(cellSelected, other.cellSelected, t)!,
      cellPeer: Color.lerp(cellPeer, other.cellPeer, t)!,
      highlightSame: Color.lerp(highlightSame, other.highlightSame, t)!,
      highlightPencil: Color.lerp(highlightPencil, other.highlightPencil, t)!,
      keypadBg: Color.lerp(keypadBg, other.keypadBg, t)!,
      doneBg: Color.lerp(doneBg, other.doneBg, t)!,
      armed: Color.lerp(armed, other.armed, t)!,
      hintHouse: Color.lerp(hintHouse, other.hintHouse, t)!,
      hintTarget: Color.lerp(hintTarget, other.hintTarget, t)!,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [
      brightness == Brightness.dark ? AppColors.dark : AppColors.light,
    ],
  );
}

/// Convenience accessors so widgets read `context.appColors.cellSelected` etc.
extension ThemeX on BuildContext {
  // Falls back to the light palette if the extension isn't installed (e.g. a
  // bare MaterialApp in a widget test), so widgets never null-crash.
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
