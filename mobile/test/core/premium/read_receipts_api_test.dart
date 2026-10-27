import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/premium/read_receipts_api.dart';

// Written from docs/premium/MONETISATION.md §4 and the HTTP contract of the
// brief: `GET /api/premium/settings` → data.send_read_receipts;
// `PUT /api/profile/read-receipts { enabled }` → data.send_read_receipts.

HttpReadReceiptsApi _api(
  Future<http.Response> Function(http.Request request) handler, {
  List<http.Request>? log,
}) => HttpReadReceiptsApi.withClient(
  baseUrl: 'https://api.example.com',
  token: () => '<jwt>',
  clientFactory: () => MockClient((request) {
    log?.add(request);
    return handler(request);
  }),
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('reading the setting', () {
    test('reads send_read_receipts from the premium settings', () async {
      final log = <http.Request>[];
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {
            'is_plus': false,
            'passport': null,
            'incognito': false,
            'send_read_receipts': false,
          },
        }),
        log: log,
      );
      expect(await api.load(), isFalse);
      expect(log.single.method, 'GET');
      expect(log.single.url.path, '/api/premium/settings');
      expect(log.single.headers['Authorization'], 'Bearer <jwt>');
    });

    test('an answer without the boolean is an error, not « on »', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'is_plus': true},
        }),
      );
      expect(
        api.load(),
        throwsA(
          isA<ReadReceiptsException>().having(
            (e) => e.kind,
            'kind',
            ReadReceiptsErrorKind.unknown,
          ),
        ),
      );
    });
  });

  group('writing the setting', () {
    test('PUTs {enabled} and returns what the server now holds', () async {
      final log = <http.Request>[];
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'send_read_receipts': false},
        }),
        log: log,
      );
      expect(await api.set(false), isFalse);
      expect(log.single.method, 'PUT');
      expect(log.single.url.path, '/api/profile/read-receipts');
      expect(jsonDecode(log.single.body), {'enabled': false});
    });

    test('the server value wins over the one asked for', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'send_read_receipts': true},
        }),
      );
      expect(await api.set(false), isTrue);
    });

    test('401, 5xx and a refusal are typed, not swallowed', () async {
      Future<ReadReceiptsErrorKind> kindFor(http.Response response) async {
        try {
          await _api((_) async => response).set(true);
        } on ReadReceiptsException catch (e) {
          return e.kind;
        }
        fail('no exception');
      }

      expect(
        await kindFor(_json({'success': false, 'error': 'unauthorized'}, 401)),
        ReadReceiptsErrorKind.sessionExpired,
      );
      expect(
        await kindFor(_json({'success': false, 'error': 'boom'}, 500)),
        ReadReceiptsErrorKind.server,
      );
      expect(
        await kindFor(_json({'success': false, 'error': 'invalid_body'}, 400)),
        ReadReceiptsErrorKind.unknown,
      );
    });

    test('a dropped connection is a network error', () async {
      final api = _api((_) async => throw http.ClientException('down'));
      expect(
        api.set(true),
        throwsA(
          isA<ReadReceiptsException>().having(
            (e) => e.kind,
            'kind',
            ReadReceiptsErrorKind.network,
          ),
        ),
      );
    });
  });
}
