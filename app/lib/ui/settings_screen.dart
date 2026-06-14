import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../models/profile.dart';
import '../services/background.dart';
import '../services/notifications.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Reconcile background polling with the current preference + identity.
  /// Requesting permission only makes sense when turning the feature on.
  Future<void> _syncNotifications(Settings settings, Profile profile,
      {required bool requestPermission}) async {
    if (settings.notifyChallenges && profile.hasIdentity) {
      if (requestPermission) await NotificationService.requestPermission();
      await BackgroundPoller.enable();
    } else {
      await BackgroundPoller.disable();
    }
  }

  Future<void> _editIdentity(BuildContext context, Profile profile) async {
    final nameCtl = TextEditingController(text: profile.name);
    final emailCtl = TextEditingController(text: profile.email);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (your identity, no password)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!Profile.isValidEmail(emailCtl.text)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid email')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      profile.setIdentity(name: nameCtl.text, email: emailCtl.text);
      // Now that we have an identity, start polling if notifications are on.
      if (context.mounted) {
        await _syncNotifications(context.read<Settings>(), profile,
            requestPermission: true);
      }
    }
  }

  Future<void> _manageFriends(BuildContext context, Profile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final addCtl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Friends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addCtl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Friend's email",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (Profile.isValidEmail(addCtl.text)) {
                          profile.addFriend(addCtl.text);
                          addCtl.clear();
                          setSheet(() {});
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (profile.friends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No friends yet.',
                        style: TextStyle(color: Colors.black54)),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final f in profile.friends)
                          ListTile(
                            dense: true,
                            title: Text(f),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                profile.removeFriend(f);
                                setSheet(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final profile = context.watch<Profile>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          const _SectionHeader('Profile (for leaderboard & friends)'),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(profile.name.isEmpty ? 'Set your name' : profile.name),
            subtitle: Text(profile.email.isEmpty
                ? 'No email set — tap to join the leaderboard'
                : profile.email),
            trailing: const Icon(Icons.edit),
            onTap: () => _editIdentity(context, profile),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Friends'),
            subtitle: Text(profile.friends.isEmpty
                ? 'Add friends by email to compete'
                : '${profile.friends.length} friend(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _manageFriends(context, profile),
          ),
          const _SectionHeader('Input'),
          ListTile(
            title: const Text('Input method'),
            subtitle: Text(settings.inputMode.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await showDialog<InputMode>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Input method'),
                  children: [
                    for (final m in InputMode.values)
                      ListTile(
                        title: Text(m.label),
                        subtitle: Text(switch (m) {
                          InputMode.hybrid =>
                            'Tap a digit or a cell first — the app follows your lead.',
                          InputMode.digitThenCell =>
                            'Pick a digit, then tap cells to place it.',
                          InputMode.cellThenDigit =>
                            'Pick a cell, then tap a digit.',
                        }),
                        trailing: settings.inputMode == m
                            ? const Icon(Icons.check, color: Color(0xFF2E6FB7))
                            : null,
                        onTap: () => Navigator.pop(context, m),
                      ),
                  ],
                ),
              );
              if (choice != null) settings.setInputMode(choice);
            },
          ),
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
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Challenge notifications'),
            subtitle: Text(profile.hasIdentity
                ? 'Get notified when a friend sends a game or finishes one '
                    'you\'re racing'
                : 'Set your email above first to receive challenges'),
            value: settings.notifyChallenges,
            onChanged: profile.hasIdentity
                ? (v) async {
                    settings.setNotifyChallenges(v);
                    await _syncNotifications(settings, profile,
                        requestPermission: v);
                  }
                : null,
          ),
          if (profile.hasIdentity && settings.notifyChallenges)
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Send a test notification'),
              subtitle: const Text('Check notifications are allowed and working'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final granted = await NotificationService.showTest();
                messenger.showSnackBar(SnackBar(
                  content: Text(granted
                      ? 'Test sent — check your notification shade.'
                      : 'Notifications are blocked for Sudoku. Enable them in '
                          'Android Settings → Apps → Sudoku → Notifications.'),
                ));
              },
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
