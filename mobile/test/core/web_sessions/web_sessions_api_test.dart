import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/web_sessions/web_session_models.dart';
import 'package:mazl/core/web_sessions/web_sessions_api.dart';

class _Seen {
  String method = '';
  String path = '';
  String body = '';
  Map<String, String> headers = {};
}

HttpWebSessionsApi _api(_Seen seen, int status, Object body) {
  final client = MockClient((request) async {
    seen
      ..method = request.method
      ..path = request.url.path
      ..body = request.body
      ..headers = request.headers;
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return HttpWebSessionsApi(
    client: client,
    baseUrl: 'https://api.test',
    tokenProvider: () => 'jwt-1',
  );
}

const _pairing = {
  'success': true,
  'pairing': {
    'id': 'p1',
    'browser': 'Chrome sur macOS',
    'address': '198.51.100.x',
    'created_at': '2026-10-24T10:00:00.000Z',
    'expires_at': '2026-10-24T10:02:00.000Z',
  },
};

void main() {
  test('scan posts the code and parses the pairing', () async {
    final seen = _Seen();
    final response = await _api(seen, 200, _pairing).scan('code-1');

    expect(seen.method, 'POST');
    expect(seen.path, '/api/web/pairings/scan');
    expect(jsonDecode(seen.body), {'code': 'code-1'});
    expect(seen.headers['Authorization'], 'Bearer jwt-1');
    expect(response.success, isTrue);
    expect(response.data!.id, 'p1');
    expect(response.data!.browser, 'Chrome sur macOS');
    expect(response.data!.expiresAt.toUtc(), DateTime.utc(2026, 10, 24, 10, 2));
  });

  test('scan maps 404, 429 and 400 to typed errors', () async {
    final notFound = await _api(_Seen(), 404, {
      'success': false,
      'error': 'pairing_not_found',
    }).scan('c');
    expect(notFound.success, isFalse);
    expect(notFound.error, WebSessionsError.pairingNotFound);

    final limited = await _api(_Seen(), 429, {'error': 'slow down'}).scan('c');
    expect(limited.error, WebSessionsError.rateLimited);

    final invalid = await _api(_Seen(), 400, {
      'success': false,
      'error': 'invalid_body',
    }).scan('c');
    expect(invalid.error, 'invalid_body');
  });

  test('approve and deny hit the exact paths', () async {
    final seen = _Seen();
    final api = _api(seen, 200, {'success': true});

    expect((await api.approve('p 1')).success, isTrue);
    expect(
      [seen.method, seen.path],
      ['POST', '/api/web/pairings/p%201/approve'],
    );

    expect((await api.deny('p1')).success, isTrue);
    expect([seen.method, seen.path], ['POST', '/api/web/pairings/p1/deny']);
  });

  test('approve reports 409 as pairing_not_pending', () async {
    final response = await _api(_Seen(), 409, {
      'success': false,
      'error': 'pairing_not_pending',
    }).approve('p1');

    expect(response.success, isFalse);
    expect(response.error, WebSessionsError.pairingNotPending);
    expect(response.errorKind, ApiErrorKind.server);
  });

  test('listSessions parses every field', () async {
    final seen = _Seen();
    final response = await _api(seen, 200, {
      'success': true,
      'sessions': [
        {
          'id': 's1',
          'browser': 'Safari sur macOS',
          'method': 'google',
          'created_at': '2026-10-20T08:00:00.000Z',
          'last_seen_at': '2026-10-24T09:00:00.000Z',
          'expires_at': '2026-10-27T08:00:00.000Z',
          'current': false,
        },
      ],
    }).listSessions();

    expect([seen.method, seen.path], ['GET', '/api/web/sessions']);
    final session = response.data!.single;
    expect(session.id, 's1');
    expect(session.method, WebSessionMethod.google);
    expect(session.lastSeenAt.toUtc(), DateTime.utc(2026, 10, 24, 9));
    expect(session.current, isFalse);
  });

  test('revoke and revokeAll use DELETE on the right paths', () async {
    final seen = _Seen();
    final api = _api(seen, 200, {'success': true});

    await api.revoke('s1');
    expect([seen.method, seen.path], ['DELETE', '/api/web/sessions/s1']);

    await api.revokeAll();
    expect([seen.method, seen.path], ['DELETE', '/api/web/sessions']);
  });

  test('a network failure is a typed failure, not an exception', () async {
    final api = HttpWebSessionsApi(
      client: MockClient((_) async => throw http.ClientException('down')),
      baseUrl: 'https://api.test',
      tokenProvider: () => null,
    );
    final response = await api.listSessions();

    expect(response.success, isFalse);
    expect(response.errorKind, ApiErrorKind.network);
  });

  test('a malformed body is an invalid_response failure', () async {
    final response = await _api(_Seen(), 200, {
      'success': true,
      'sessions': 'oops',
    }).listSessions();

    expect(response.error, 'invalid_response');
  });
}
