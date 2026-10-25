import 'dart:convert';

/// Why the app ended the member's session by itself (V1-CONTRAT §5).
enum SessionEndReason {
  /// The server no longer accepts the token (expired, revoked).
  expired,

  /// The account was disabled by moderation.
  accountDisabled,
}

/// Close code of the WebSocket for an expired token.
const int webSocketTokenExpiredClose = 4001;

/// Close code of the WebSocket for a disabled account.
const int webSocketAccountDisabledClose = 4003;

const String _accountDisabledCode = 'account_disabled';

/// What an answer of the server to an AUTHENTICATED request says about the
/// session: a 401, or a 403 `account_disabled`, ends it. `null` for any other
/// answer. The server may also send `account_disabled` with a 401: that is
/// still a disabled account, not an expired token.
SessionEndReason? sessionEndForResponse(int status, String body) {
  final disabled = _errorCodeOf(body) == _accountDisabledCode;
  if (status == 401) {
    return disabled
        ? SessionEndReason.accountDisabled
        : SessionEndReason.expired;
  }
  if (status == 403 && disabled) return SessionEndReason.accountDisabled;
  return null;
}

/// What a WebSocket close code says about the session; `null` when the
/// connection merely dropped and may be reopened.
SessionEndReason? sessionEndForSocketClose(int? code) => switch (code) {
  webSocketTokenExpiredClose => SessionEndReason.expired,
  webSocketAccountDisabledClose => SessionEndReason.accountDisabled,
  _ => null,
};

String? _errorCodeOf(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}
