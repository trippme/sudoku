import 'dart:async';
import 'package:flutter/widgets.dart';

/// A pausable stopwatch for the card games. Ticks once a second while running
/// and pauses automatically when the app goes to the background.
class GameClock with WidgetsBindingObserver {
  int seconds;
  final VoidCallback onTick;
  Timer? _timer;
  bool _wanted = false;

  GameClock({this.seconds = 0, required this.onTick});

  bool get running => _timer != null;

  void start() {
    _wanted = true;
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      onTick();
    });
  }

  void stop() {
    _wanted = false;
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    seconds = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_wanted) return;
    if (state == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        onTick();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    stop();
    WidgetsBinding.instance.removeObserver(this);
  }

  static String format(int s) {
    final m = s ~/ 60;
    return '$m:${(s % 60).toString().padLeft(2, '0')}';
  }
}
