import 'dart:convert';
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
      await Firebase.initializeApp();
      _available = true;
    } catch (_) {
      _available = false; // not configured → push off, polling still covers us
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
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
    FirebaseMessaging.onMessageOpenedApp.listen((m) =>
        onTap?.call((m.data['type'] as String?) ?? NotificationService.payloadInbox));
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      onTap?.call((initial.data['type'] as String?) ??
          NotificationService.payloadInbox);
    }

    // Keep the backend current if the token rotates.
    messaging.onTokenRefresh.listen((t) {
      _token = t;
      if (_email.isNotEmpty) _post(t, _email);
    });
  }

  /// Register this device's token with the backend for [email]. No-op when push
  /// is unavailable or there's no identity yet.
  static Future<void> registerToken(String email) async {
    if (!_available || email.isEmpty) return;
    _email = email;
    try {
      _token ??= await FirebaseMessaging.instance.getToken();
      final token = _token;
      if (token == null || token.isEmpty) return;
      await _post(token, email);
    } catch (_) {/* best effort */}
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
            body: jsonEncode(
                {'email': email, 'token': token, 'platform': 'android'}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* best effort */}
  }
}
