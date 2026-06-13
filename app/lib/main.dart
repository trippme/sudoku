import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'models/game_state.dart';
import 'models/settings.dart';
import 'models/stats.dart';
import 'models/profile.dart';
import 'services/storage.dart';
import 'services/leaderboard.dart';
import 'ui/home_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.load();
    final stats = Stats.load();
    final profile = Profile.load();
    final LeaderboardService leaderboard =
        RemoteLeaderboard(kBackendBaseUrl, apiKey: kBackendApiKey);

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
