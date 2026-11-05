import 'package:flutter/material.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_prefs.dart';
import 'package:sudoku_app/games/bubble/bubble_widgets.dart';

/// Bubble Breaker options, laid out in sections like the classic game:
/// sound, UI effects, bubble appearance, board size and game settings.
///
/// Edits [prefs] in place and calls [onChanged] after every change (so the
/// caller can persist). Board size, level and mode apply to the next board.
class BubbleOptionsScreen extends StatefulWidget {
  final BubblePrefs prefs;
  final VoidCallback onChanged;
  const BubbleOptionsScreen({
    super.key,
    required this.prefs,
    required this.onChanged,
  });

  @override
  State<BubbleOptionsScreen> createState() => _BubbleOptionsScreenState();
}

class _BubbleOptionsScreenState extends State<BubbleOptionsScreen> {
  BubblePrefs get p => widget.prefs;

  void _change(VoidCallback edit) {
    setState(edit);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Section('Game Sound Settings', [
            SwitchListTile(
              key: const Key('opt-sound'),
              title: const Text('Sound Effect'),
              subtitle: const Text('Play sounds during gameplay'),
              value: p.sound,
              onChanged: (v) => _change(() => p.sound = v),
            ),
          ]),
          _Section('Game UI Effect Settings', [
            SwitchListTile(
              key: const Key('opt-motion'),
              title: const Text('Bubble Motion'),
              subtitle: const Text('Animate bubble movements'),
              value: p.motion,
              onChanged: (v) => _change(() => p.motion = v),
            ),
            SwitchListTile(
              key: const Key('opt-disappear'),
              title: const Text('Disappear Animation'),
              subtitle: const Text('Bubble elimination visual effect'),
              value: p.disappear,
              onChanged: (v) => _change(() => p.disappear = v),
            ),
          ]),
          _Section('Bubble Appearance', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'Bubble Theme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final t in BubbleTheme.values)
                    Expanded(
                      child: _ThemeCard(
                        key: Key('opt-theme-${t.name}'),
                        theme: t,
                        selected: p.theme == t,
                        onTap: () => _change(() => p.theme = t),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          _Section('Bubble Size Setting', [
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final s in BubbleSize.values)
                    _SizeCard(
                      key: Key('opt-size-${s.name}'),
                      size: s,
                      selected: p.size == s,
                      onTap: () => _change(() => p.size = s),
                    ),
                ],
              ),
            ),
          ]),
          _Section('Game Settings', [
            _DropdownTile<BubbleLevel>(
              key: const Key('opt-level'),
              title: 'Level',
              subtitle: 'Default difficulty level',
              value: p.level,
              items: BubbleLevel.values,
              label: (l) => '${l.label} (${l.colors} colours)',
              shortLabel: (l) => l.label,
              onSelected: (v) => _change(() => p.level = v),
            ),
            _DropdownTile<bool>(
              key: const Key('opt-mode'),
              title: 'Mode',
              subtitle: p.collapse
                  ? 'Empty columns close up'
                  : 'The board stays fixed',
              value: p.collapse,
              items: const [true, false],
              label: (v) => v ? 'Standard' : 'Fixed',
              shortLabel: (v) => v ? 'Standard' : 'Fixed',
              onSelected: (v) => _change(() => p.collapse = v),
            ),
            SwitchListTile(
              key: const Key('opt-auto'),
              title: const Text('Auto Eliminate'),
              subtitle: const Text('Auto-pop selected bubbles after selection'),
              value: p.autoEliminate,
              onChanged: (v) => _change(() => p.autoEliminate = v),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Size, level and mode apply to your next board. Each combination '
              'has its own leaderboard.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 22, 8, 10),
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_up, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// A "Title / subtitle ........ Value ▾" row that opens a menu.
class _DropdownTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<T> items;
  final String Function(T) label;
  final String Function(T) shortLabel;
  final ValueChanged<T> onSelected;
  const _DropdownTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.label,
    required this.shortLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final i in items)
          PopupMenuItem<T>(value: i, child: Text(label(i))),
      ],
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortLabel(value),
              style: TextStyle(color: cs.primary, fontSize: 16),
            ),
            Icon(Icons.keyboard_arrow_down, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final BubbleTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.black26,
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    BubbleView(color: i, size: 30, theme: theme),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                theme.label,
                style: TextStyle(
                  color: selected ? cs.onPrimaryContainer : null,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final BubbleSize size;
  final bool selected;
  final VoidCallback onTap;
  const _SizeCard({
    super.key,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.black26,
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _DotGridPainter(size.width, size.height, cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              size.label,
              style: TextStyle(
                color: fg,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '${size.width}×${size.height}',
              style: TextStyle(fontSize: 12, color: fg ?? cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny preview of a board: [cols]×[rows] dots scaled to fit.
class _DotGridPainter extends CustomPainter {
  final int cols, rows;
  final Color color;
  _DotGridPainter(this.cols, this.rows, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = (size.width / cols).clamp(0.0, size.height / rows);
    final w = cell * cols, h = cell * rows;
    final dx = (size.width - w) / 2, dy = (size.height - h) / 2;
    final paint = Paint()..color = color;
    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        canvas.drawCircle(
          Offset(dx + (c + 0.5) * cell, dy + (r + 0.5) * cell),
          cell * 0.38,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.cols != cols || old.rows != rows || old.color != color;
}
