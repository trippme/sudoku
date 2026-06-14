import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../config.dart';
import '../models/profile.dart';
import 'leaderboard.dart';
import 'notifications.dart';
import 'storage.dart';

const _uniqueName = 'sudoku-inbox-poll';
const _taskName = 'pollInbox';

/// Entry point for the isolate Workmanager spawns to run a background task.
///
/// This runs with NO app state — a fresh isolate — so it must re-initialise
/// everything it touches (storage, the notifications plugin) itself. It reads
/// the saved profile directly and polls the backend, raising local
/// notifications for anything new. Kept deliberately tiny and failure-tolerant:
/// a thrown error would make WorkManager retry/back off, which we don't want for
/// a transient network blip.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Storage.init();
      final profile = Profile.load();
      if (!profile.hasIdentity) return true;
      final svc = RemoteLeaderboard(kBackendBaseUrl, apiKey: kBackendApiKey);
      await NotificationService.pollAndNotify(svc: svc, email: profile.email);
    } catch (_) {
      // Swallow — try again on the next scheduled run.
    }
    return true;
  });
}

/// Schedules periodic background polling so a challenge can reach you while the
/// app is closed, without a push server.
///
/// Background work is Android-only here: Android's WorkManager gives a reliable
/// (if ~15-min-floored) periodic task. iOS background fetch is opportunistic and
/// needs extra native plumbing; on iOS the app still notifies on launch/resume
/// (foreground polling), which is the documented trade-off of not using APNs.
class BackgroundPoller {
  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Register the Workmanager dispatcher. Call once at startup.
  static Future<void> init() async {
    if (!supported) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Start (or keep) the periodic poll. Idempotent.
  static Future<void> enable() async {
    if (!supported) return;
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(minutes: 15), // Android's minimum interval
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Stop background polling.
  static Future<void> disable() async {
    if (!supported) return;
    await Workmanager().cancelByUniqueName(_uniqueName);
  }
}
