import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'leaderboard.dart';
import 'storage.dart';

/// On-device notifications for incoming challenges and friend results.
///
/// There is no formal push server (issue #24 explicitly didn't need one). Instead
/// the app polls the existing backend — on launch/resume in the foreground, and
/// periodically in the background via [BackgroundPoller] — and raises a *local*
/// notification for anything new. "New" is tracked with a per-type high-water
/// mark (the largest row id we've already accounted for) stored locally, so each
/// item notifies exactly once even across many polls and isolates.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'sudoku_challenges';
  static const _channelName = 'Game challenges';
  static const _channelDesc = 'New games and results from friends';

  // High-water marks: the largest id we've already considered for each feed.
  static const _shareHwmKey = 'notif_share_hwm';
  static const _resultHwmKey = 'notif_result_hwm';

  // Distinct id spaces so a share and a result never collide in the tray.
  static const _shareIdBase = 0x10000000;
  static const _resultIdBase = 0x20000000;

  static bool _inited = false;

  /// Initialise the plugin. [onTap] fires when the user taps a notification
  /// while the app is alive; the payload is one of the `payload*` constants.
  static Future<void> init({void Function(String? payload)? onTap}) async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      // We ask for permission explicitly (see [requestPermission]) so it can be
      // tied to enabling the feature rather than first launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) => onTap?.call(resp.payload),
    );
    // Pre-create the Android channel so importance is correct on first post.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));
    _inited = true;
  }

  /// Ask the OS for permission to post notifications (Android 13+, iOS). Safe to
  /// call repeatedly; a no-op where already granted.
  static Future<bool?> requestPermission() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios;
  }

  /// If the app was cold-started by tapping a notification, returns its payload.
  static Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  static Future<void> _show(
      int id, String title, String body, String payload) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    return _plugin.show(id, title, body, details, payload: payload);
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Post a sample notification right now, to verify the channel + permission
  /// are working without waiting for a real challenge. Returns false if the OS
  /// permission isn't granted (so the caller can tell the user).
  static Future<bool> showTest() async {
    await init();
    final granted = await requestPermission();
    await _show(
      0x7FFFFFFF,
      'Sudoku notifications are on',
      'This is a test — real challenges from friends will look like this.',
      payloadInbox,
    );
    return granted ?? true;
  }

  /// Decides which feed rows are "new" — newer than the stored high-water mark
  /// [rawHwm] and not already seen in-app — and the high-water mark to store
  /// next. Pure (no plugin / I/O), so it's unit-testable.
  ///
  /// On the first run for a feed ([rawHwm] is null) it only baselines: nothing
  /// is reported new, so enabling the feature doesn't dump notifications for a
  /// pre-existing backlog. The watermark always advances to the largest id seen,
  /// even for already-seen rows, so we never reconsider them.
  @visibleForTesting
  static (List<int> toNotify, String nextHwm) selectNew(
      List<({int id, bool seen})> feed, String? rawHwm) {
    final firstRun = rawHwm == null;
    final hwm = int.tryParse(rawHwm ?? '0') ?? 0;
    var maxId = hwm;
    final toNotify = <int>[];
    for (final row in feed) {
      if (!firstRun && row.id > hwm && !row.seen) toNotify.add(row.id);
      if (row.id > maxId) maxId = row.id;
    }
    return (toNotify, '$maxId');
  }

  /// Poll the backend and raise a notification for every *new* incoming game and
  /// friend result. Safe to call from a background isolate. Returns how many
  /// notifications were shown.
  static Future<int> pollAndNotify({
    required LeaderboardService svc,
    required String email,
  }) async {
    if (email.isEmpty) return 0;
    await init();

    var shown = 0;

    // --- Games a friend sent you ("here's a challenge"). ---
    final games = await svc.inbox(email);
    final (newShares, shareHwm) = selectNew(
      [for (final g in games) (id: g.id, seen: g.seen)],
      Storage.getString(_shareHwmKey),
    );
    for (final g in games) {
      if (!newShares.contains(g.id)) continue;
      final who = g.fromName.isEmpty ? g.fromEmail : g.fromName;
      await _show(
        _shareIdBase ^ (g.id & 0xFFFFFF),
        'New challenge from $who',
        g.message.isEmpty
            ? 'Game #${g.gameId} — tap to play'
            : '#${g.gameId}: “${g.message}”',
        payloadInbox,
      );
      shown++;
    }
    await Storage.setString(_shareHwmKey, shareHwm);

    // --- A friend finished a game you're both racing on. ---
    final results = await svc.notifications(email);
    final (newResults, resultHwm) = selectNew(
      [for (final r in results) (id: r.id, seen: r.seen)],
      Storage.getString(_resultHwmKey),
    );
    for (final r in results) {
      if (!newResults.contains(r.id)) continue;
      final who = r.fromName.isEmpty ? r.fromEmail : r.fromName;
      await _show(
        _resultIdBase ^ (r.id & 0xFFFFFF),
        '$who finished #${r.gameId}',
        'Their time: ${_fmt(r.seconds)} · '
            '${r.hints} hint${r.hints == 1 ? '' : 's'}',
        payloadInbox,
      );
      shown++;
    }
    await Storage.setString(_resultHwmKey, resultHwm);

    return shown;
  }

  /// Show a notification with the given text — used to surface an FCM push that
  /// arrives while the app is in the foreground (FCM doesn't display those).
  static Future<void> showMessage(
      String title, String body, String payload) async {
    await init();
    // A stable-ish id from the text so identical re-pushes collapse in the tray.
    await _show(0x30000000 ^ (title.hashCode & 0xFFFFFF), title, body, payload);
  }

  /// Payload meaning "open the inbox".
  static const String payloadInbox = 'inbox';
}
