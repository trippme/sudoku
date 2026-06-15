import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'theme.dart';

/// Digit keypad plus tool buttons. The keypad mirrors the original
/// "Enjoy Sudoku": a selected digit (or Erase) stays highlighted green so you
/// can tap multiple cells with it.
class ControlPad extends StatelessWidget {
  final VoidCallback onHint;
  const ControlPad({super.key, required this.onHint});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (game.isSolved)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appColors.armed.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                game.lastOutcome != null
                    ? '🎉 Solved!  Rank ${game.lastOutcome!.rank} of ${game.lastOutcome!.total}'
                    : '🎉 Solved!',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          // Digit row
          Row(
            children: [
              for (var d = 1; d <= 9; d++)
                Expanded(
                  child: _DigitButton(
                    digit: d,
                    remaining: 9 - game.placedCount(d),
                    selected: game.isDigitActive(d),
                    onTap: () => game.pressDigit(d),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Tools row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Tool(
                icon: Icons.edit,
                label: 'Pencil',
                active: game.pencilMode,
                onTap: game.togglePencil,
              ),
              _Tool(
                icon: Icons.backspace_outlined,
                label: 'Erase',
                active: game.isDigitActive(10),
                onTap: () => game.pressDigit(10),
              ),
              _Tool(
                icon: Icons.auto_fix_high,
                label: 'Auto',
                active: game.autoPencilOn,
                onTap: game.toggleAutoPencil,
              ),
              _Tool(
                icon: Icons.undo,
                label: 'Undo',
                enabled: game.canUndo,
                onTap: game.undo,
              ),
              _Tool(
                icon: Icons.redo,
                label: 'Redo',
                enabled: game.canRedo,
                onTap: game.redo,
              ),
              _Tool(
                icon: Icons.lightbulb_outline,
                label: 'Hint',
                onTap: onHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitButton extends StatelessWidget {
  final int digit;
  final int remaining;
  final bool selected;
  final VoidCallback onTap;

  const _DigitButton({
    required this.digit,
    required this.remaining,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = remaining <= 0;
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (selected) {
      bg = colors.armed; // green = armed (original behavior)
      fg = Colors.white;
    } else if (done) {
      bg = colors.doneBg;
      fg = scheme.onSurfaceVariant;
    } else {
      bg = colors.keypadBg;
      fg = scheme.primary;
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          // When a digit is "done" it can still be selected for highlighting,
          // so keep it tappable.
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$digit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                Text(
                  done ? '✓' : '$remaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : active
            ? Colors.white
            : scheme.onSurface;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? context.appColors.armed : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
