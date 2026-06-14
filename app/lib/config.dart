/// Base URL of the optional backend (the PHP API in /server).
///
/// Point this at the folder you uploaded `server/` to. Leave it as-is and the
/// app works fully offline — online calls just fail soft until the backend is
/// reachable.
const String kBackendBaseUrl = 'https://the949dude.com/sudoku';

/// Shared key sent as the `X-Api-Key` header on every backend call. Injected at
/// build time via `--dart-define=BACKEND_API_KEY=...` (the build scripts read it
/// from server/data/api-key.txt), so it isn't committed to the repo. Empty =>
/// no key sent, which matches a server with no API_KEY configured.
const String kBackendApiKey =
    String.fromEnvironment('BACKEND_API_KEY', defaultValue: '');
