import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/games/bubble/bubble_game.dart';
import 'package:sudoku_app/games/bubble/bubble_options_screen.dart';
import 'package:sudoku_app/games/bubble/bubble_prefs.dart';
import 'package:sudoku_app/games/bubble/bubble_widgets.dart';
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

/// How long a popped bubble takes to burst away.
const Duration kBubblePopDuration = Duration(milliseconds: 240);

/// Bubble Breaker: resumes the saved board if there is one, otherwise deals a
/// new one.
class BubbleScreen extends StatefulWidget {
  /// Skips persistence (used by widget tests).
  final bool persist;

  /// Start a specific board (e.g. a friend's challenge). Replaces any save.
  final int? initialDeal;

  /// Size/level/mode variant for [initialDeal] (see `GameRef`); defaults to the
  /// player's chosen options.
  final int? initialVariant;

  /// Test hook: start from an arbitrary position.
  final BubbleGame? initialGame;

  /// Test hook: options to start with (otherwise loaded from storage, or the
  /// defaults when [persist] is false).
  final BubblePrefs? prefs;

  const BubbleScreen({
    super.key,
    this.persist = true,
    this.initialDeal,
    this.initialVariant,
    this.initialGame,
    this.prefs,
  });

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

/// A popped bubble that is bursting away.
class _Ghost {
  final int key;
  final int c, r, color;
  const _Ghost(this.key, this.c, this.r, this.color);
}

class _BubbleScreenState extends State<BubbleScreen> {
  late BubbleGame _game;
  late final GameClock _clock;
  late BubblePrefs _prefs;
  List<(int, int)> _selCells = [];
  Set<int> _selIds = {};
  int _best = 0;
  bool _finishing = false;

  List<_Ghost> _ghosts = [];
  int _ghostKey = 0;
  Timer? _ghostTimer;

  GameRef get _ref => GameRef.bubble(_game.deal, variant: _game.variant);

  @override
  void initState() {
    super.initState();
    var secs = 0;
    _prefs = widget.prefs ??
        (widget.persist ? BubblePrefs.load() : BubblePrefs());
    if (widget.persist) {
      _best = int.tryParse(Storage.getString(kBubbleBestKey) ?? '') ?? 0;
    }
    final saved = _loadSaved();
    if (widget.initialGame != null) {
      _game = widget.initialGame!;
    } else if (saved != null) {
      _game = saved.$1;
      secs = saved.$2;
    } else {
      final v = widget.initialVariant;
      _game = BubbleGame.deal(
        widget.initialDeal ?? _randomDeal(),
        size: v != null ? BubbleGame.sizeOfVariant(v) : _prefs.size,
        level: v != null ? BubbleGame.levelOfVariant(v) : _prefs.level,
        collapse: v != null ? BubbleGame.collapseOfVariant(v) : _prefs.collapse,
      );
    }
    _clock = GameClock(seconds: secs, onTick: () {
      if (mounted) setState(() {});
    });
    if (!_game.over) _clock.start();
  }

  @override
  void dispose() {
    _save();
    _ghostTimer?.cancel();
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

  /// Deals [deal] with the given options, or the player's chosen ones.
  void _newBoard(
    int deal, {
    BubbleSize? size,
    BubbleLevel? level,
    bool? collapse,
  }) {
    setState(() {
      _game = BubbleGame.deal(deal,
          size: size ?? _prefs.size,
          level: level ?? _prefs.level,
          collapse: collapse ?? _prefs.collapse);
      _clearSelection();
      _ghosts = [];
      _finishing = false;
      _clock
        ..reset()
        ..start();
    });
    _save();
  }

  void _clearSelection() {
    _selCells = [];
    _selIds = {};
  }

  // ---- taps ---------------------------------------------------------------

  /// First tap highlights a group; tapping that highlighted group pops it.
  /// (With "Auto Eliminate" on, the first tap pops straight away.)
  void _tap(int c, int r) {
    final b = _game.at(c, r);
    if (b == null || _game.over) return;
    final group = _game.groupAt(c, r);
    if (group.isEmpty) {
      setState(_clearSelection);
      return;
    }
    if (_prefs.autoEliminate || _selIds.contains(b.id)) {
      _pop(c, r, group);
    } else {
      setState(() {
        _selCells = group;
        _selIds = {for (final (cc, rr) in group) _game.at(cc, rr)!.id};
      });
    }
  }

  void _pop(int c, int r, List<(int, int)> group) {
    if (_prefs.disappear) {
      _ghosts = [
        for (final (cc, rr) in group)
          _Ghost(_ghostKey++, cc, rr, _game.at(cc, rr)!.color)
      ];
      _ghostTimer?.cancel();
      _ghostTimer = Timer(kBubblePopDuration + const Duration(milliseconds: 40),
          () {
        if (mounted) setState(() => _ghosts = []);
      });
    }
    if (_prefs.sound) {
      try {
        SystemSound.play(SystemSoundType.click).catchError((_) {});
      } catch (_) {/* no audio on this platform */}
    }
    _game.pop(c, r);
    _clearSelection();
    _save();
    setState(() {});
    if (_game.over) _finish();
  }

  void _undo() {
    if (!_game.canUndo) return;
    _game.undo();
    _finishing = false;
    _ghosts = [];
    _clearSelection();
    if (!_game.over && !_clock.running) _clock.start();
    _save();
    setState(() {});
  }

  void _finish() {
    _clock.stop();
    if (_game.score > _best) {
      _best = _game.score;
      if (widget.persist) Storage.setString(kBubbleBestKey, '$_best');
    }
    if (_finishing) return;
    _finishing = true;
    // Let the last bubbles settle before the sheet covers the board.
    Future.delayed(kBubbleFallDuration + const Duration(milliseconds: 200), () {
      if (mounted && _game.over) _showFinished();
    });
  }

  Future<SubmitOutcome?> _submit() async {
    final profile = context.read<Profile>();
    if (!profile.hasIdentity) return null;
    final svc = context.read<LeaderboardService>();
    final secs = _clock.seconds < 1 ? 1 : _clock.seconds;
    final hints =
        GameRef.hintsForScore(_game.score, variant: _game.variant);
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
    final g = _game;
    final cleared = g.cleared;
    final seconds = _clock.seconds;

    Widget stat(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('$k: $v', style: const TextStyle(fontSize: 15)),
        );

    final restart = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(cleared ? 'Board cleared! 🎉' : 'Game Over',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Game Statistic',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    stat('Board', _ref.label),
                    stat('rows*cols*types',
                        '${g.height}*${g.width}*${g.colors}'),
                    stat('Mode', g.collapse ? 'Standard' : 'Fixed'),
                    stat('Final score', '${g.score}'),
                    stat('Tap count', '${g.moves}'),
                    stat('Largest single score', '${g.bestPop}'),
                    stat('Consumed time (seconds)', '$seconds'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => LeaderboardScreen(gameId: _ref.id))),
                    child: const Text('Leaderboard'),
                  ),
                  TextButton(
                    onPressed: () => sendGameToFriends(ctx,
                        gameId: _ref.id, label: _ref.label),
                    child: const Text('Challenge'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('OK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Restart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (restart == true && mounted) _newBoard(_randomDeal());
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

  /// The Options screen. Look/sound/behaviour changes apply at once; board
  /// size, level and mode apply to NEW boards, so we offer to start one.
  Future<void> _openOptions() async {
    final before = _prefs.copy();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Theme(
        data: bubbleTheme(),
        child: BubbleOptionsScreen(
          prefs: _prefs,
          onChanged: () {
            if (widget.persist) _prefs.save();
          },
        ),
      ),
    ));
    if (!mounted) return;
    setState(() {});
    if (_prefs.boardSettingsDiffer(before)) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start a new board?'),
          content: const Text('Board size, level and mode apply to new boards. '
              'Each combination has its own leaderboard.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('New board')),
          ],
        ),
      );
      if (go == true && mounted) _newBoard(_randomDeal());
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: bubbleTheme(),
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final selCount = _selIds.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bubble Breaker #${_game.deal}',
            style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            key: const Key('bb-undo'),
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _game.canUndo ? _undo : null,
          ),
          IconButton(
            key: const Key('bb-options'),
            tooltip: 'Options',
            icon: const Icon(Icons.tune),
            onPressed: _openOptions,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'new':
                  _newBoard(_randomDeal());
                case 'choose':
                  _chooseBoard();
                case 'restart':
                  _newBoard(_game.deal,
                      size: _game.size,
                      level: _game.level,
                      collapse: _game.collapse);
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
          const chrome = 190.0; // header + footer around the board
          final byWidth = (box.maxWidth - 2 * pad) / _game.width;
          final byHeight = (box.maxHeight - chrome) / _game.height;
          final cell = max(16.0, min(60.0, min(byWidth, byHeight)));
          final boardW = cell * _game.width;
          final boardH = cell * _game.height;
          final counts = _game.colorCounts();
          final selColor = _selCells.isEmpty
              ? null
              : _game.at(_selCells.first.$1, _selCells.first.$2)?.color;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(pad),
            child: Center(
              child: SizedBox(
                width: max(boardW, box.maxWidth - 2 * pad),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${_game.score}',
                                key: const Key('bb-score'),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(GameClock.format(_clock.seconds),
                                style: const TextStyle(fontSize: 18)),
                            Text(
                              'Best: $_best · '
                              '${_game.collapse ? 'Standard' : 'Fixed'}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: boardW,
                      height: boardH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var c = 0; c < _game.columns.length; c++)
                            for (var r = 0; r < _game.columns[c].length; r++)
                              _bubbleAt(c, r, cell),
                          for (final g in _ghosts) _ghostAt(g, cell),
                          if (_selCells.isNotEmpty) ...[
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: GroupOutlinePainter(
                                      _selCells, _game.height, cell),
                                ),
                              ),
                            ),
                            _scoreBadge(cell),
                          ],
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
                                  '${BubbleGame.pointsFor(selCount)} points'
                                  '${_prefs.autoEliminate ? '' : ' · tap again to pop'}'
                              : 'Tap a group of matching bubbles'
                                  '${_prefs.autoEliminate ? '' : ', then tap it again to pop'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // How many bubbles are selected, in their colour, like
                        // the "-34" in the classic game.
                        SizedBox(
                          width: 64,
                          child: selCount >= 2 && selColor != null
                              ? Text('-$selCount',
                                  key: const Key('bb-selcount'),
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: kBubbleColors[selColor]))
                              : null,
                        ),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            children: [
                              for (var i = 0; i < counts.length; i++)
                                Container(
                                  key: Key('bb-count-$i'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: selColor == i
                                        ? Border.all(
                                            color: kBubbleColors[i], width: 2)
                                        : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${counts[i]}',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: kBubbleColors[i])),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 64),
                      ],
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

  /// The group's score, floating over the group like in the classic game.
  Widget _scoreBadge(double cell) {
    var sx = 0.0, sy = 0.0;
    for (final (c, r) in _selCells) {
      sx += (c + 0.5) * cell;
      sy += (_game.height - 1 - r + 0.5) * cell;
    }
    final cx = sx / _selCells.length;
    final cy = sy / _selCells.length;
    return Positioned(
      left: cx,
      top: cy,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Container(
            key: const Key('bb-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${BubbleGame.pointsFor(_selCells.length)}',
              style: const TextStyle(
                  color: Color(0xFF4A1FB8),
                  fontWeight: FontWeight.w900,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghostAt(_Ghost g, double cell) {
    return Positioned(
      key: ValueKey('ghost-${g.key}'),
      left: g.c * cell,
      top: (_game.height - 1 - g.r) * cell,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: kBubblePopDuration,
          builder: (_, t, child) => Opacity(
            opacity: 1 - t,
            child: Transform.scale(scale: 1 + 0.6 * t, child: child),
          ),
          child: Padding(
            padding: EdgeInsets.all(cell * 0.06),
            child: BubbleView(
                color: g.color, size: cell * 0.88, theme: _prefs.theme),
          ),
        ),
      ),
    );
  }

  /// A bubble that drops (AnimatedPositioned) whenever its spot changes.
  Widget _bubbleAt(int c, int r, double cell) {
    final b = _game.columns[c][r];
    final selected = _selIds.contains(b.id);
    return AnimatedPositioned(
      key: ValueKey('${_game.deal}-${b.id}'),
      duration: _prefs.motion ? kBubbleFallDuration : Duration.zero,
      curve: Curves.easeIn,
      left: c * cell,
      top: (_game.height - 1 - r) * cell,
      width: cell,
      height: cell,
      child: GestureDetector(
        key: Key('bb-$c-$r'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(c, r),
        child: Padding(
          padding: EdgeInsets.all(cell * (selected ? 0.03 : 0.06)),
          child: BubbleView(
            color: b.color,
            size: cell * (selected ? 0.94 : 0.88),
            theme: _prefs.theme,
          ),
        ),
      ),
    );
  }
}
