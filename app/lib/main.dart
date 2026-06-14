import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'models/game_state.dart';
import 'models/settings.dart';
import 'models/stats.dart';
import 'models/profile.dart';
import 'services/storage.dart';
import 'services/leaderboard.dart';
import 'services/notifications.dart';
import 'services/background.dart';
import 'ui/home_menu.dart';
import 'ui/inbox_screen.dart';

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

  final settings = Settings.load();
  final profile = Profile.load();
  // Turn background polling on/off to match the saved preference. Tray
  // notifications come from the background isolate; while the app is open the
  // in-app inbox badge is the signal, so we don't double up with a foreground
  // poll here.
  if (settings.notifyChallenges && profile.hasIdentity) {
    await NotificationService.requestPermission();
    await BackgroundPoller.enable();
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
      child: MaterialApp(
        title: 'Sudoku',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E6FB7),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomeMenu(),
      ),
    );
  }
}
