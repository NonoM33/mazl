/// Environment configuration resolved from `--dart-define` at build/run time.
///
/// Values are injected via compile-time environment variables so that switching
/// between dev / staging / prod does not require editing any source file.
///
/// Launch examples:
///
/// Dev (local backend):
/// ```sh
/// flutter run \
///   --dart-define=API_BASE_URL=http://localhost:3999 \
///   --dart-define=WS_URL=ws://localhost:3999/ws \
///   --dart-define=APP_ENV=dev
/// ```
///
/// Staging:
/// ```sh
/// flutter run \
///   --dart-define=API_BASE_URL=https://staging-api.mazl.app \
///   --dart-define=WS_URL=wss://staging-api.mazl.app/ws \
///   --dart-define=APP_ENV=staging
/// ```
///
/// Prod (defaults, no dart-define needed):
/// ```sh
/// flutter run
/// ```
class Env {
  const Env._();

  /// Base URL for the REST API. Defaults to production.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mazl.app',
  );

  /// WebSocket URL for realtime chat. Defaults to production.
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.mazl.app/ws',
  );

  /// Current environment name (dev / staging / prod). For info/debug only.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );
}
