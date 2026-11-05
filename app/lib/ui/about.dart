import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sudoku_app/build_info.dart';

/// "v1.0.0 (build 87)" — or an empty string if the platform can't say.
String formatVersion(PackageInfo? info) =>
    info == null ? '' : 'v${info.version} (build ${info.buildNumber})';

/// The About dialog: what the app is, which version/build is running, and
/// exactly which commit it was built from.
Future<void> showAboutGames(
  BuildContext context, {
  Future<PackageInfo>? packageInfo,
  List<String> games = const ['Sudoku', 'FreeCell', 'Solitaire'],
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => FutureBuilder<PackageInfo>(
      future: packageInfo ?? PackageInfo.fromPlatform(),
      builder: (ctx, snap) {
        final info = snap.data;
        final theme = Theme.of(ctx);
        Widget row(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(k,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(child: Text(v)),
                ],
              ),
            );
        return AlertDialog(
          title: const Text("Tripp's Games"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A small collection of classic games to play solo or '
                    'against friends: ${games.join(', ')}.'),
                const SizedBox(height: 14),
                row('Version', info?.version ?? '…'),
                row('Build', info?.buildNumber ?? '…'),
                row('Commit', kGitSha),
                row('Built', kBuildTime),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => showLicensePage(
                context: ctx,
                applicationName: "Tripp's Games",
                applicationVersion: formatVersion(info),
              ),
              child: const Text('Licenses'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}

/// Small, tappable version line for the landing page: "v1.0.0 (build 87) ·
/// About". Opens [showAboutGames].
class VersionAboutButton extends StatelessWidget {
  final Future<PackageInfo>? packageInfo;
  const VersionAboutButton({super.key, this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return FutureBuilder<PackageInfo>(
      future: packageInfo ?? PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = formatVersion(snap.data);
        return TextButton.icon(
          key: const Key('about-button'),
          onPressed: () => showAboutGames(context, packageInfo: packageInfo),
          icon: Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          label: Text(v.isEmpty ? 'About' : '$v · About', style: style),
        );
      },
    );
  }
}
