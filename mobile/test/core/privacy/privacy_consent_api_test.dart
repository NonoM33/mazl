import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/privacy/privacy_consent_api.dart';
import 'package:mazl/core/privacy/religious_data_consent.dart';
import 'package:mazl/core/services/api_service.dart';

class _Seen {
  String method = '';
  String path = '';
  String body = '';
  Map<String, String> headers = {};
}

HttpPrivacyConsentApi _api(_Seen seen, int status, Object body) {
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
  return HttpPrivacyConsentApi(
    client: client,
    baseUrl: 'https://api.test',
    tokenProvider: () => 'jwt-1',
  );
}

Map<String, Object?> _consents({
  bool? granted,
  String? version,
  String? decidedAt,
}) => {
  'success': true,
  'consents': {
    'religious_data': {
      'granted': granted,
      'version': version,
      'decided_at': decidedAt,
      'current_version': '2026-10-24',
      'text': 'Je consens au traitement.',
    },
  },
};

void main() {
  test('religiousData reads the entry of GET /api/privacy/consents', () async {
    final seen = _Seen();
    final response = await _api(
      seen,
      200,
      _consents(
        granted: true,
        version: '2026-10-24',
        decidedAt: '2026-10-24T10:00:00.000Z',
      ),
    ).religiousData();

    expect([seen.method, seen.path], ['GET', '/api/privacy/consents']);
    expect(seen.headers['Authorization'], 'Bearer jwt-1');
    final consent = response.data!;
    expect(consent.granted, isTrue);
    expect(consent.text, 'Je consens au traitement.');
    expect(consent.currentVersion, '2026-10-24');
    expect(consent.decidedAt!.toUtc(), DateTime.utc(2026, 10, 24, 10));
    expect(consent.isValid, isTrue);
  });

  test('a member never asked has granted null and no valid consent', () async {
    final response = await _api(_Seen(), 200, _consents()).religiousData();

    expect(response.data!.granted, isNull);
    expect(response.data!.decidedAt, isNull);
    expect(response.data!.isValid, isFalse);
  });

  test('isValid needs granted AND the current version', () {
    ReligiousDataConsent make(bool? granted, String? version) =>
        ReligiousDataConsent(
          granted: granted,
          version: version,
          decidedAt: null,
          currentVersion: '2026-10-24',
          text: 't',
        );

    expect(make(true, '2026-10-24').isValid, isTrue);
    expect(make(true, '2026-01-01').isValid, isFalse);
    expect(make(false, '2026-10-24').isValid, isFalse);
    expect(make(null, null).isValid, isFalse);
  });

  test('a malformed body is an invalid_response failure', () async {
    final response = await _api(_Seen(), 200, {
      'success': true,
      'consents': <String, Object?>{},
    }).religiousData();

    expect(response.success, isFalse);
    expect(response.error, 'invalid_response');
  });

  test('decide sends the exact body to the exact path', () async {
    final seen = _Seen();
    final response = await _api(seen, 200, {
      'success': true,
      'consent': {
        'granted': true,
        'version': '2026-10-24',
        'decided_at': '2026-10-24T10:00:00.000Z',
      },
    }).decideReligiousData(granted: true, version: '2026-10-24');

    expect(response.success, isTrue);
    expect(
      [seen.method, seen.path],
      ['PUT', '/api/privacy/consents/religious_data'],
    );
    expect(jsonDecode(seen.body), {
      'granted': true,
      'version': '2026-10-24',
      'source': 'app',
    });
  });

  test('decide can refuse with granted false', () async {
    final seen = _Seen();
    await _api(seen, 200, {
      'success': true,
    }).decideReligiousData(granted: false, version: '2026-10-24');

    expect(jsonDecode(seen.body), {
      'granted': false,
      'version': '2026-10-24',
      'source': 'app',
    });
  });

  test('decide reports 409 as consent_version_outdated', () async {
    final response = await _api(_Seen(), 409, {
      'success': false,
      'error': 'consent_version_outdated',
      'current_version': '2026-10-24',
    }).decideReligiousData(granted: true, version: '2026-01-01');

    expect(response.success, isFalse);
    expect(response.error, PrivacyConsentError.versionOutdated);
    expect(response.errorKind, ApiErrorKind.server);
  });

  test('429 and 500 are typed', () async {
    final limited = await _api(_Seen(), 429, {
      'error': 'x',
    }).decideReligiousData(granted: true, version: 'v');
    expect(limited.error, PrivacyConsentError.rateLimited);

    final broken = await _api(_Seen(), 500, {
      'success': false,
      'error': 'internal_error',
    }).religiousData();
    expect(broken.error, 'internal_error');
  });

  test('network failures are typed, not thrown', () async {
    HttpPrivacyConsentApi failing(Exception error) => HttpPrivacyConsentApi(
      client: MockClient((_) async => throw error),
      baseUrl: 'https://api.test',
      tokenProvider: () => 'jwt-1',
    );

    final offline = await failing(
      const SocketException('down'),
    ).religiousData();
    expect(offline.error, 'network');
    expect(offline.errorKind, ApiErrorKind.network);

    final client = await failing(
      http.ClientException('down'),
    ).decideReligiousData(granted: true, version: 'v');
    expect(client.errorKind, ApiErrorKind.network);
  });
}
