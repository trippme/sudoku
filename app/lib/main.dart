import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_app/config.dart';
import 'package:sudoku_app/games/sudoku/models/game_state.dart';
import 'package:sudoku_app/models/settings.dart';
import 'package:sudoku_app/games/sudoku/models/stats.dart';
import 'package:sudoku_app/models/profile.dart';
import 'package:sudoku_app/services/storage.dart';
import 'package:sudoku_app/services/leaderboard.dart';
import 'package:sudoku_app/services/notifications.dart';
import 'package:sudoku_app/services/background.dart';
import 'package:sudoku_app/services/push.dart';
import 'package:sudoku_app/ui/game_picker.dart';
import 'package:sudoku_app/ui/inbox_screen.dart';
import 'package:sudoku_app/ui/theme.dart';

/// Lets notification taps (which happen outside any widget's context) push a
/// route onto the app's navigator.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _handleNotificationTap(String? payload) {
  if (payload == NotificationService.payloadInbox) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const InboxScreen()),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  GameState.migrateLegacySave(); // one-time: old single save → per-game slot

  await NotificationService.init(onTap: _handleNotificationTap);
  await BackgroundPoller.init();
  // Optional FCM push (instant delivery). No-ops if Firebase isn't configured.
  await PushService.init(onTap: _handleNotificationTap);

  final settings = Settings.load();
  final profile = Profile.load();
  // Turn background polling on/off to match the saved preference, and register
  // for push. Push gives instant delivery when configured; the WorkManager poll
  // is the fallback when it isn't (or when Play services are unavailable).
  if (settings.notifyChallenges && profile.hasIdentity) {
    await NotificationService.requestPermission();
    await BackgroundPoller.enable();
    PushService.registerToken(profile.email);
  } else {
    await BackgroundPoller.disable();
  }

  // If a notification cold-started the app, jump to the inbox after first frame.
  final launchPayload = await NotificationService.launchPayload();

  runApp(SudokuApp(
    settings: settings,
    profile: profile,
    launchPayload: launchPayload,
  ));
}

class SudokuApp extends StatelessWidget {
  final Settings settings;
  final Profile profile;
  final String? launchPayload;

  const SudokuApp({
    super.key,
    required this.settings,
    required this.profile,
    this.launchPayload,
  });

  @override
  Widget build(BuildContext context) {
    final stats = Stats.load();
    final LeaderboardService leaderboard =
        RemoteLeaderboard(kBackendBaseUrl, apiKey: kBackendApiKey);

    if (launchPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleNotificationTap(launchPayload),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: stats),
        ChangeNotifierProvider.value(value: profile),
        Provider<LeaderboardService>.value(value: leaderboard),
        ChangeNotifierProvider(
          create: (_) => GameState(
            settings: settings,
            stats: stats,
            profile: profile,
            leaderboard: leaderboard,
          ),
        ),
      ],
      // Rebuild the app when the theme preference changes (issue #40).
      child: Consumer<Settings>(
        builder: (context, s, _) => MaterialApp(
          title: "Tripp's Games",
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: s.themeMode,
          home: const GamePicker(),
        ),
      ),
    );
  }
}
