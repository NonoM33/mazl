/// How a computer signed in to app.mazl.app.
enum WebSessionMethod {
  qr,
  google,
  apple;

  static WebSessionMethod parse(Object? raw) => switch (raw) {
    'google' => google,
    'apple' => apple,
    _ => qr,
  };
}

/// A computer currently connected to the member's account.
class WebSession {
  const WebSession({
    required this.id,
    required this.browser,
    required this.method,
    required this.createdAt,
    required this.lastSeenAt,
    required this.expiresAt,
    required this.current,
  });

  factory WebSession.fromJson(Map<String, dynamic> json) => WebSession(
    id: _string(json, 'id'),
    browser: _string(json, 'browser'),
    method: WebSessionMethod.parse(json['method']),
    createdAt: _date(json, 'created_at'),
    lastSeenAt: _date(json, 'last_seen_at'),
    expiresAt: _date(json, 'expires_at'),
    current: json['current'] == true,
  );

  final String id;
  final String browser;
  final WebSessionMethod method;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime expiresAt;
  final bool current;
}

/// A login request read from a computer's QR code, waiting for approval.
class WebPairing {
  const WebPairing({
    required this.id,
    required this.browser,
    required this.createdAt,
    required this.expiresAt,
  });

  factory WebPairing.fromJson(Map<String, dynamic> json) => WebPairing(
    id: _string(json, 'id'),
    browser: _string(json, 'browser'),
    createdAt: _date(json, 'created_at'),
    expiresAt: _date(json, 'expires_at'),
  );

  final String id;
  final String browser;
  final DateTime createdAt;
  final DateTime expiresAt;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('missing $key');
  return value;
}

DateTime _date(Map<String, dynamic> json, String key) =>
    DateTime.parse(_string(json, key)).toLocal();
