import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Assistance'),
          ListTile(
            title: const Text('Mark mistakes'),
            subtitle: Text(settings.mistakeMode.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await showDialog<MistakeMode>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Mark mistakes'),
                  children: [
                    for (final m in MistakeMode.values)
                      ListTile(
                        title: Text(m.label),
                        trailing: settings.mistakeMode == m
                            ? const Icon(Icons.check, color: Color(0xFF2E6FB7))
                            : null,
                        onTap: () => Navigator.pop(context, m),
                      ),
                  ],
                ),
              );
              if (choice != null) settings.setMistakeMode(choice);
            },
          ),
          SwitchListTile(
            title: const Text('Auto-remove pencil marks'),
            subtitle:
                const Text('Clear a digit from peers\' marks when you place it'),
            value: settings.autoRemoveMarks,
            onChanged: settings.setAutoRemoveMarks,
          ),
          const _SectionHeader('Display'),
          SwitchListTile(
            title: const Text('Highlight related cells'),
            subtitle: const Text('Shade the row, column, and box'),
            value: settings.highlightPeers,
            onChanged: settings.setHighlightPeers,
          ),
          SwitchListTile(
            title: const Text('Highlight matching digits'),
            value: settings.highlightSameValue,
            onChanged: settings.setHighlightSameValue,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
