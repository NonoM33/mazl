import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/session_end.dart';

/// Written from docs/launch/V1-CONTRAT.md §5: a 401, or a 403 whose error is
/// `account_disabled`, on an authenticated request; a WebSocket closed with
/// 4001 or 4003.
void main() {
  group('an answer to an authenticated request', () {
    test('401 ends the session', () {
      expect(
        sessionEndForResponse(401, '{"success":false,"error":"Unauthorized"}'),
        SessionEndReason.expired,
      );
    });

    test('401 with no readable body still ends the session', () {
      expect(sessionEndForResponse(401, ''), SessionEndReason.expired);
      expect(sessionEndForResponse(401, '<html>'), SessionEndReason.expired);
    });

    test('403 account_disabled ends the session', () {
      expect(
        sessionEndForResponse(403, '{"success":false,"error":"account_disabled"}'),
        SessionEndReason.accountDisabled,
      );
    });

    test('the server also sends account_disabled with a 401', () {
      expect(
        sessionEndForResponse(401, '{"success":false,"error":"account_disabled"}'),
        SessionEndReason.accountDisabled,
      );
    });

    test('any other 403 is a refused action, not the end of the session', () {
      expect(sessionEndForResponse(403, '{"success":false,"error":"not_matched"}'), isNull);
      expect(sessionEndForResponse(403, '{"success":false,"error":"Forbidden"}'), isNull);
      expect(sessionEndForResponse(403, ''), isNull);
    });

    test('nothing else ends it', () {
      for (final status in [200, 201, 204, 400, 404, 409, 429, 500, 503]) {
        expect(
          sessionEndForResponse(status, '{"error":"account_disabled"}'),
          isNull,
          reason: '$status',
        );
      }
    });
  });

  group('a closed WebSocket', () {
    test('4001 (token expired) and 4003 (account disabled) end the session', () {
      expect(sessionEndForSocketClose(4001), SessionEndReason.expired);
      expect(sessionEndForSocketClose(4003), SessionEndReason.accountDisabled);
    });

    test('a connection that merely dropped does not', () {
      for (final code in [null, 1000, 1001, 1006, 1011, 4000, 4002, 4004]) {
        expect(sessionEndForSocketClose(code), isNull, reason: '$code');
      }
    });
  });
}
