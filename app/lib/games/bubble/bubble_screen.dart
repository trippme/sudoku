import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/cards/game_clock.dart';
import 'package:sudoku_app/games/game_ref.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/ui/leaderboard_screen.dart';
import 'package:sudoku_app/ui/send_to_friends.dart';

const String kBubbleSaveKey = 'bubble.save';
const String kBubbleBestKey = 'bubble.best';

/// How long a bubble takes to drop into its new spot.
const Duration kBubbleFallDuration = Duration(milliseconds: 280);

const List<Color> _palette = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFDD835), // yellow
  Color(0xFF8E24AA), // purple
];

/// Bubble Breaker: resumes the saved board if there is one, otherwise deals a
/// new one.
class BubbleScreen extends StatefulWidget {
  /// Skips persistence (used by widget tests).
  final bool persist;

  /// Start a specific board (e.g. a friend's challenge). Replaces any save.
  final int? initialDeal;

  /// Test hook: start from an arbitrary position.
  final BubbleGame? initialGame;
  const BubbleScreen({
    super.key,
    this.persist = true,
    this.initialDeal,
    this.initialGame,
  });

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen> {
  late BubbleGame _game;
  late final GameClock _clock;
  Set<int> _selIds = {};
  int _best = 0;
  bool _finishing = false;

  GameRef get _ref => GameRef.bubble(_game.deal);

  @override
  void initState() {
    super.initState();
    var secs = 0;
    final saved = _loadSaved();
    if (widget.initialGame != null) {
      _game = widget.initialGame!;
    } else if (saved != null) {
      _game = saved.$1;
      secs = saved.$2;
    } else {
      _game = BubbleGame.deal(widget.initialDeal ?? _randomDeal());
    }
    if (widget.persist) {
      _best = int.tryParse(Storage.getString(kBubbleBestKey) ?? '') ?? 0;
    }
    _clock = GameClock(seconds: secs, onTick: () {
      if (mounted) setState(() {});
    });
    if (!_game.over) _clock.start();
  }

  @override
  void dispose() {
    _save();
    _clock.dispose();
    super.dispose();
  }

  static int _randomDeal() => Random().nextInt(1000000) + 1;

  (BubbleGame, int)? _loadSaved() {
    if (!widget.persist || widget.initialDeal != null) return null;
    try {
      final raw = Storage.getString(kBubbleSaveKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (BubbleGame.fromJson(m), (m['secs'] ?? 0) as int);
    } catch (_) {
      return null;
    }
  }

  void _save() {
    if (!widget.persist) return;
    if (_game.over) {
      Storage.remove(kBubbleSaveKey);
    } else {
      Storage.setString(kBubbleSaveKey,
          jsonEncode({..._game.toJson(), 'secs': _clock.seconds}));
    }
  }

  void _newBoard(int deal) {
    setState(() {
      _game = BubbleGame.deal(deal);
      _selIds = {};
      _finishing = false;
      _clock
        ..reset()
        ..start();
    });
    _save();
  }

  // ---- taps ---------------------------------------------------------------

  /// First tap highlights a group; tapping that highlighted group pops it.
  void _tap(int c, int r) {
    final b = _game.at(c, r);
    if (b == null || _game.over) return;
    final group = _game.groupAt(c, r);
    if (group.isEmpty) {
      setState(() => _selIds = {});
      return;
    }
    if (_selIds.contains(b.id)) {
      _game.pop(c, r);
      _selIds = {};
      _save();
      setState(() {});
      if (_game.over) _finish();
    } else {
      setState(() => _selIds = {for (final (cc, rr) in group) _game.at(cc, rr)!.id});
    }
  }

  void _finish() {
    _clock.stop();
    if (_game.score > _best) {
      _best = _game.score;
      if (widget.persist) Storage.setString(kBubbleBestKey, '$_best');
    }
    if (_finishing) return;
    _finishing = true;
    // Let the last bubbles settle before the dialog covers the board.
    Future.delayed(kBubbleFallDuration + const Duration(milliseconds: 200), () {
      if (mounted) _showFinished();
    });
  }

  Future<SubmitOutcome?> _submit() async {
    final profile = context.read<Profile>();
    if (!profile.hasIdentity) return null;
    final svc = context.read<LeaderboardService>();
    final secs = _clock.seconds < 1 ? 1 : _clock.seconds;
    final hints = GameRef.hintsForScore(_game.score);
    final outcome = await svc.submitResult(
      gameId: _ref.id,
      email: profile.email,
      name: profile.name,
      seconds: secs,
      hints: hints,
      mistakes: 0,
      difficulty: 0,
    );
    svc.notifyFinish(
      email: profile.email,
      name: profile.name,
      gameId: _ref.id,
      seconds: secs,
      hints: hints,
    );
    return outcome;
  }

  Future<void> _showFinished() async {
    final hasProfile = context.read<Profile>().hasIdentity;
    final outcome = _submit();
    final cleared = _game.cleared;
    final again = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cleared ? 'Board cleared! 🎉' : 'No more moves'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_ref.label}: ${_game.score} points in '
                '${GameClock.format(_clock.seconds)}.'),
            if (_game.score >= _best && _best > 0)
              const Text('That’s your best score!'),
            const SizedBox(height: 10),
            if (!hasProfile)
              const Text('Set your name and email in Settings to join the '
                  'leaderboard and compete with friends.')
            else
              FutureBuilder<SubmitOutcome?>(
                future: outcome,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Text('Submitting your score…');
                  }
                  final o = snap.data;
                  if (o == null) {
                    return const Text('Couldn’t reach the leaderboard.');
                  }
                  return Text(o.improved
                      ? 'Rank #${o.rank} of ${o.total} on this board.'
                      : 'Not your best — you’re #${o.rank} of ${o.total}.');
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => LeaderboardScreen(gameId: _ref.id))),
            child: const Text('Leaderboard'),
          ),
          TextButton(
            onPressed: () =>
                sendGameToFriends(ctx, gameId: _ref.id, label: _ref.label),
            child: const Text('Challenge'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Close')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('New board')),
        ],
      ),
    );
    if (again == true && mounted) _newBoard(_randomDeal());
  }

  Future<void> _chooseBoard() async {
    final controller = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Play board number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1 – 1,000,000'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(controller.text)),
              child: const Text('Play')),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= GameRef.maxDeal) _newBoard(n);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selCount = _selIds.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bubble Breaker #${_game.deal}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'new':
                  _newBoard(_randomDeal());
                case 'choose':
                  _chooseBoard();
                case 'restart':
                  _newBoard(_game.deal);
                case 'board':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(gameId: _ref.id)));
                case 'send':
                  sendGameToFriends(context,
                      gameId: _ref.id, label: _ref.label);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New random board')),
              PopupMenuItem(value: 'choose', child: Text('Play board number…')),
              PopupMenuItem(value: 'restart', child: Text('Restart this board')),
              PopupMenuItem(value: 'board', child: Text('Leaderboard')),
              PopupMenuItem(value: 'send', child: Text('Challenge a friend')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          const pad = 8.0;
          final cell = min(52.0, (box.maxWidth - 2 * pad) / BubbleGame.numColumns);
          final boardW = cell * BubbleGame.numColumns;
          final boardH = cell * BubbleGame.numRows;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Center(
              child: SizedBox(
                width: boardW,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Score: ${_game.score}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(GameClock.format(_clock.seconds),
                            style: const TextStyle(fontSize: 16)),
                        Text('Best: $_best',
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: boardW,
                      height: boardH,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          for (var c = 0; c < _game.columns.length; c++)
                            for (var r = 0; r < _game.columns[c].length; r++)
                              _bubbleAt(c, r, cell),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _game.over
                          ? (_game.cleared
                              ? 'Cleared! +${BubbleGame.clearBonus} bonus'
                              : 'No more moves · ${_game.remaining} left')
                          : selCount >= 2
                              ? '$selCount bubbles = '
                                  '${BubbleGame.pointsFor(selCount)} points · '
                                  'tap again to pop'
                              : 'Tap a group of matching bubbles, then tap it again to pop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// A bubble that drops (AnimatedPositioned) whenever its spot changes.
  Widget _bubbleAt(int c, int r, double cell) {
    final b = _game.columns[c][r];
    final selected = _selIds.contains(b.id);
    final color = _palette[b.color % _palette.length];
    return AnimatedPositioned(
      key: ValueKey('${_game.deal}-${b.id}'),
      duration: kBubbleFallDuration,
      curve: Curves.easeIn,
      left: c * cell,
      top: (BubbleGame.numRows - 1 - r) * cell,
      width: cell,
      height: cell,
      child: GestureDetector(
        key: Key('bb-$c-$r'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(c, r),
        child: Padding(
          padding: EdgeInsets.all(cell * (selected ? 0.04 : 0.09)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [
                  Color.lerp(color, Colors.white, 0.55)!,
                  color,
                  Color.lerp(color, Colors.black, 0.25)!,
                ],
                stops: const [0, 0.55, 1],
              ),
              border: selected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: selected
                  ? const [BoxShadow(color: Colors.black38, blurRadius: 6)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
