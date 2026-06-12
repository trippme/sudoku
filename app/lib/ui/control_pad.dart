import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

/// Digit buttons plus tool buttons (pencil, auto-pencil, erase, undo, redo,
/// hint).
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
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🎉 Solved!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    onTap: () => game.input(d),
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
                icon: Icons.auto_fix_high,
                label: 'Auto',
                onTap: game.autoPencil,
              ),
              _Tool(
                icon: Icons.backspace_outlined,
                label: 'Erase',
                onTap: game.erase,
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
  final VoidCallback onTap;

  const _DigitButton({
    required this.digit,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 0.8,
        child: Material(
          color: done ? Colors.grey.shade200 : const Color(0xFFE7F0FB),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: done ? null : onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$digit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.grey : const Color(0xFF2E6FB7),
                  ),
                ),
                Text(
                  done ? '✓' : '$remaining',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
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
    final color = !enabled
        ? Colors.grey.shade400
        : active
            ? const Color(0xFF2E6FB7)
            : Colors.black87;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE7F0FB) : null,
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
