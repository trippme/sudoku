/// Base URL of the optional backend (the PHP API in /server).
///
/// Point this at the folder you uploaded `server/` to. Leave it as-is and the
/// app works fully offline — online calls just fail soft until the backend is
/// reachable.
const String kBackendBaseUrl = 'https://the949dude.com/sudoku';

/// Optional shared key, if you set API_KEY in the server's config.php.
const String kBackendApiKey = '';
