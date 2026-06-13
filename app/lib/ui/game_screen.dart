import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../engine/sudoku_engine.dart';
import '../models/game_state.dart';
import '../models/profile.dart';
import '../services/leaderboard.dart';
import 'sudoku_grid.dart';
import 'control_pad.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameState? _game;
  bool _completionShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = context.read<GameState>();
    if (g != _game) {
      _game?.removeListener(_onGameChanged);
      _game = g;
      _game!.addListener(_onGameChanged);
    }
  }

  @override
  void dispose() {
    _game?.removeListener(_onGameChanged);
    super.dispose();
  }

  // Show the completion popup once, when the game becomes solved.
  void _onGameChanged() {
    if ((_game?.isSolved ?? false) && !_completionShown) {
      _completionShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletion();
      });
    }
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Future<void> _showCompletion() async {
    await showDialog<void>(
      context: context,
      builder: (dctx) => Consumer<GameState>(
        builder: (_, g, _) => AlertDialog(
          title: const Text('🎉 Solved!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${g.isDaily ? 'Daily · ' : ''}${g.difficulty.label} · Game #${g.gameId}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _statRow('Time', _fmt(g.elapsed)),
              _statRow('Hints used', '${g.hintsUsed}'),
              _statRow('Mistakes', '${g.mistakesMade}'),
              if (g.lastOutcome != null)
                _statRow('Rank', '${g.lastOutcome!.rank} of ${g.lastOutcome!.total}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dctx); // close dialog
                Navigator.pop(context); // back to menu
              },
              child: const Text('Back to menu'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _shareGame(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send to a friend'),
              subtitle: const Text("It lands in their in-app inbox"),
              onTap: () {
                Navigator.pop(sheet);
                _sendToFriends(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy challenge'),
              subtitle: const Text('Paste into any chat'),
              onTap: () {
                Navigator.pop(sheet);
                _copyChallenge(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyChallenge(BuildContext context) {
    final game = context.read<GameState>();
    final text = "I'm playing Sudoku game #${game.gameId} "
        '(${game.difficulty.label}). How fast can you solve it? '
        'Open the app and Play by Number → ${game.gameId}.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: "Sudoku game #${game.gameId}" challenge')),
    );
  }

  Future<void> _sendToFriends(BuildContext context) async {
    final profile = context.read<Profile>();
    final game = context.read<GameState>();
    final svc = context.read<LeaderboardService>();
    final messenger = ScaffoldMessenger.of(context);

    if (!profile.hasIdentity || profile.friends.isEmpty) {
      final goSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set up friends first'),
          content: Text(profile.hasIdentity
              ? 'Add a friend by email in Settings to send them games.'
              : 'Set your name and email, then add friends, in Settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (goSettings == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
      return;
    }

    final selected = <String>{};
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Send game #${game.gameId} to…'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final f in profile.friends)
                  CheckboxListTile(
                    dense: true,
                    value: selected.contains(f),
                    title: Text(f),
                    onChanged: (v) => setInner(() =>
                        v == true ? selected.add(f) : selected.remove(f)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  selected.isEmpty ? null : () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (send != true || selected.isEmpty) return;

    var ok = 0;
    for (final f in selected) {
      if (await svc.sendGame(
        fromEmail: profile.email,
        fromName: profile.name,
        toEmail: f,
        gameId: game.gameId,
      )) {
        ok++;
      }
    }
    messenger.showSnackBar(SnackBar(
      content: Text(ok > 0
          ? 'Sent game #${game.gameId} to $ok friend${ok == 1 ? '' : 's'}'
          : 'Could not send — check your connection'),
    ));
  }

  Future<void> _showHint(BuildContext context) async {
    final game = context.read<GameState>();
    final hint = game.requestHint();
    if (!context.mounted) return;

    if (hint == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No simple hint'),
          content: const Text(
            'No basic technique (single, locked candidate, naked pair) applies '
            'right now. You can reveal the selected cell instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                game.revealSelected();
                Navigator.pop(context);
              },
              child: const Text('Reveal cell'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(hint.technique),
        content: Text(hint.explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              game.applyHint(hint);
              Navigator.pop(context);
            },
            child: Text(hint.placements.isNotEmpty ? 'Place it' : 'Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            tooltip: 'Share this game',
            icon: const Icon(Icons.share),
            onPressed: () => _shareGame(context),
          ),
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              final id = context.read<GameState>().gameId;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LeaderboardScreen(gameId: id),
              ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Consumer<GameState>(
                builder: (_, game, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${game.isDaily ? 'Daily · ' : ''}Game #${game.gameId}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        '${game.difficulty.label} · ${_fmt(game.elapsed)}'
                        '${game.hintsUsed > 0 ? ' · ${game.hintsUsed} hint${game.hintsUsed == 1 ? '' : 's'}' : ''}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: SudokuGrid(),
              ),
              ControlPad(onHint: () => _showHint(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
