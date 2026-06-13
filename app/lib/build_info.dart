/// Build identity, injected at build time via `--dart-define` (see sideload.bat).
///
/// They fall back to `dev` / `local` for plain `flutter run` builds, so a
/// build that wasn't produced by sideload.bat is obvious.
const String kGitSha = String.fromEnvironment('GIT_SHA', defaultValue: 'dev');
const String kBuildTime =
    String.fromEnvironment('BUILD_TIME', defaultValue: 'local');
