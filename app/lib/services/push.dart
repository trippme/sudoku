import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'notifications.dart';

/// Background/terminated message handler. Runs in its own isolate. We send
/// "notification" messages, which the OS displays automatically while the app
/// isn't foregrounded, so there's nothing to do here — but FCM requires a
/// registered top-level handler.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging integration: instant push when a friend sends a
/// challenge or finishes a shared game.
///
/// Entirely optional. If Firebase isn't configured (no `google-services.json`),
/// [init] disables itself and the app keeps working with polling — nothing else
/// changes. When configured, the device's FCM token is registered with the
/// backend (keyed by email) and the server pushes on share/finish.
class PushService {
  static bool _available = false;
  static String? _token;
  static String _email = '';

  static bool get available => _available;

  /// Initialise Firebase + messaging. [onTap] fires with a payload when a push
  /// notification opens/resumes the app.
  static Future<void> init({void Function(String? payload)? onTap}) async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      _available = true;
    } catch (_) {
      _available = false; // not configured / stalled → push off, polling covers us
      return;
    }

    // Everything below is best-effort and runs on the startup path (main()
    // awaits init() before runApp()). On iOS these calls touch APNs
    // registration, which STALLS until APNs is fully configured — so they must
    // never hang or throw into main(), or the app white-screens before its
    // first frame. Guard the whole block and time-box the awaited calls.
    try {
      final messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      // Foreground: FCM does not show a notification itself, so we raise a local
      // one to match the look of the polled notifications.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) {
          NotificationService.showMessage(
            n.title ?? 'Sudoku',
            n.body ?? '',
            (m.data['type'] as String?) ?? NotificationService.payloadInbox,
          );
        }
      });

      // Tapped a push that brought the app to the foreground, or launched it.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onTap
          ?.call((m.data['type'] as String?) ?? NotificationService.payloadInbox));

      // Keep the backend current if the token rotates.
      messaging.onTokenRefresh.listen((t) {
        _token = t;
        if (_email.isNotEmpty) _post(t, _email);
      });

      // Permission prompt: fire it but don't let a stalled APNs handshake block
      // startup. We don't use the result, so a timeout is harmless.
      try {
        await messaging.requestPermission().timeout(const Duration(seconds: 8));
      } catch (_) {/* slow/unavailable — permission still resolves out of band */}

      // Cold-start-from-push routing; null (and a timeout → null) just means the
      // app wasn't launched by tapping a notification.
      final initial = await messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (initial != null) {
        onTap?.call((initial.data['type'] as String?) ??
            NotificationService.payloadInbox);
      }
    } catch (_) {
      // Messaging wiring failed/timed out. Firebase core is up (_available
      // stays true) so token registration + polling still work; startup
      // continues regardless.
    }
  }

  /// Register this device's token with the backend for [email]. No-op when push
  /// is unavailable or there's no identity yet.
  static Future<void> registerToken(String email) async {
    if (!_available || email.isEmpty) return;
    _email = email;
    try {
      final messaging = FirebaseMessaging.instance;
      // iOS only mints an FCM token once the APNs device token has been set,
      // which happens asynchronously after registration (kicked off explicitly
      // in AppDelegate). At startup that hasn't completed yet, so getToken()
      // throws `apns-token-not-set` and we'd register nothing. Wait, bounded,
      // for the APNs token first.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 15 && (await messaging.getAPNSToken()) == null; i++) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      _token ??= await messaging.getToken();
      final token = _token;
      if (token == null || token.isEmpty) return;
      await _post(token, email);
    } catch (_) {/* best effort; onTokenRefresh will catch a later token */}
  }

  static Future<void> _post(String token, String email) async {
    try {
      final uri = Uri.parse('$kBackendBaseUrl/index.php')
          .replace(queryParameters: {'r': 'register_token'});
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (kBackendApiKey.isNotEmpty) 'X-Api-Key': kBackendApiKey,
            },
            body: jsonEncode({
              'email': email,
              'token': token,
              'platform':
                  defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* best effort */}
  }
}
