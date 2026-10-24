import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/http_verification_api.dart';
import 'package:mazl/core/services/verification_api.dart';

// Response bodies below are copied from docs/verification/CONTRAT.md, §3 and §4.

http.Response _json(int status, Map<String, Object?> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

HttpVerificationApi _api(Future<http.Response> Function(http.Request) handler) => HttpVerificationApi(
      client: MockClient(handler),
      baseUrl: 'https://api.test',
      tokenProvider: () => 'jwt-abc',
    );

Uint8List _jpeg(int marker) => Uint8List.fromList([0xFF, 0xD8, marker, 0xFF, 0xD9]);

void main() {
  group('startFaceSession', () {
    test('parses a 3 step session and sends purpose + bearer token', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(200, {
          'success': true,
          'session_id': '7f9c2f0e-4c1c-4f7e-9d3c-0a1b2c3d4e5f',
          'challenges': ['front', 'right', 'left'],
          'expires_at': '2026-10-23T10:02:00.000Z',
        });
      });

      final response = await api.startFaceSession(FacePurpose.photo);

      expect(response.success, isTrue);
      expect(response.data!.sessionId, '7f9c2f0e-4c1c-4f7e-9d3c-0a1b2c3d4e5f');
      expect(response.data!.challenges, [FaceChallenge.front, FaceChallenge.right, FaceChallenge.left]);
      expect(response.data!.expiresAt, DateTime.utc(2026, 10, 23, 10, 2));
      expect(seen.url.toString(), 'https://api.test/api/verification/face/session');
      expect(seen.method, 'POST');
      expect(jsonDecode(seen.body), {'purpose': 'photo'});
      expect(seen.headers['Authorization'], 'Bearer jwt-abc');
    });

    test('parses a 4 step session ending with a second front', () async {
      final api = _api((_) async => _json(200, {
            'success': true,
            'session_id': 'abc',
            'challenges': ['front', 'left', 'right', 'front'],
            'expires_at': '2026-10-23T10:02:00Z',
          }));
      final response = await api.startFaceSession(FacePurpose.identity);
      expect(response.data!.challenges.length, 4);
      expect(response.data!.challenges.last, FaceChallenge.front);
    });

    test('429 becomes daily_limit_reached', () async {
      final api = _api((_) async => _json(429, {
            'success': false,
            'error': 'daily_limit_reached',
            'next_attempt_time': '2026-10-24T08:00:00Z',
          }));
      final response = await api.startFaceSession(FacePurpose.photo);
      expect(response.success, isFalse);
      expect(response.error, 'daily_limit_reached');
    });

    test('429 without a JSON body is still daily_limit_reached', () async {
      final api = _api((_) async => http.Response('Too Many Requests', 429));
      expect((await api.startFaceSession(FacePurpose.photo)).error, 'daily_limit_reached');
    });

    test('401 keeps the server error code', () async {
      final api = _api((_) async => _json(401, {'success': false, 'error': 'unauthorized'}));
      expect((await api.startFaceSession(FacePurpose.photo)).error, 'unauthorized');
    });
  });

  group('submitFace', () {
    test('sends session_id and frame_0..n as image/jpeg multipart parts', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(200, {
          'success': true,
          'verified': true,
          'photo_matches': [
            {'photo_id': 12, 'match': true},
            {'photo_id': 13, 'match': false},
          ],
        });
      });

      final response = await api.submitFace('sess-1', [_jpeg(1), _jpeg(2), _jpeg(3)]);

      expect(seen.url.path, '/api/verification/face/submit');
      expect(seen.headers['content-type'], startsWith('multipart/form-data'));
      expect(seen.headers['Authorization'], 'Bearer jwt-abc');
      final body = latin1.decode(seen.bodyBytes);
      expect(body, contains('name="session_id"'));
      expect(body, contains('sess-1'));
      for (final name in ['frame_0', 'frame_1', 'frame_2']) {
        expect(body, contains('name="$name"'));
      }
      expect(body, isNot(contains('name="frame_3"')));
      expect('image/jpeg'.allMatches(body.toLowerCase()).length, 3);

      expect(response.success, isTrue);
      expect(response.data!.verified, isTrue);
      expect(response.data!.reason, isNull);
      expect(response.data!.photoMatches.map((m) => (m.photoId, m.match)), [(12, true), (13, false)]);
    });

    test('a refusal is a successful call with verified false and a reason', () async {
      final api = _api((_) async => _json(200, {'success': true, 'verified': false, 'reason': 'pose_mismatch'}));
      final response = await api.submitFace('s', [_jpeg(1)]);
      expect(response.success, isTrue);
      expect(response.data!.verified, isFalse);
      expect(response.data!.reason, 'pose_mismatch');
      expect(response.data!.photoMatches, isEmpty);
    });

    test('429 on submit maps to daily_limit_reached', () async {
      final api = _api((_) async => _json(429, {'success': false, 'error': 'daily_limit_reached'}));
      expect((await api.submitFace('s', [_jpeg(1)])).error, 'daily_limit_reached');
    });

    test('a success:false body becomes a failure with its error code', () async {
      final api = _api((_) async => _json(200, {'success': false, 'error': 'session_expired'}));
      final response = await api.submitFace('s', [_jpeg(1)]);
      expect(response.success, isFalse);
      expect(response.error, 'session_expired');
    });

    test('a connection error is a network failure, not an exception', () async {
      final api = _api((_) async => throw http.ClientException('boom'));
      final response = await api.submitFace('s', [_jpeg(1)]);
      expect(response.success, isFalse);
      expect(response.errorKind, ApiErrorKind.network);
    });
  });

  group('submitIdentity', () {
    test('adds the raw chip files next to the frames', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(200, {'success': true, 'verified': false, 'reason': 'document_expired'});
      });
      final chip = ChipReadResult(dg1: Uint8List.fromList([1]), dg2: Uint8List.fromList([2]), sod: Uint8List.fromList([3]));

      final response = await api.submitIdentity('sess', [_jpeg(1), _jpeg(2)], chip);

      expect(seen.url.path, '/api/verification/identity');
      final body = latin1.decode(seen.bodyBytes);
      for (final name in ['session_id', 'frame_0', 'frame_1', 'dg1', 'dg2', 'sod']) {
        expect(body, contains('name="$name"'));
      }
      expect(response.data!.reason, 'document_expired');
    });
  });

  group('getStatus', () {
    test('parses the contract shape (verified photo, no identity)', () async {
      final api = _api((_) async => _json(200, {
            'success': true,
            'photo': {'verified': true, 'verified_at': '2026-10-20T09:00:00Z', 'attempts_today': 1},
            'identity': {'verified': false, 'verified_at': null, 'attempts_today': 0},
            'level': 'photo',
            'is_verified': true,
            'attempts_today': 1,
            'next_attempt_time': null,
          }));

      final status = (await api.getStatus()).data!;

      expect(status.photo.verified, isTrue);
      expect(status.photo.verifiedAt, DateTime.utc(2026, 10, 20, 9));
      expect(status.photo.attemptsToday, 1);
      expect(status.identity.verified, isFalse);
      expect(status.identity.verifiedAt, isNull);
      expect(status.level, 'photo');
      expect(status.isVerified, isTrue);
      expect(status.nextAttemptTime, isNull);
    });

    test('parses a quota reached status', () async {
      final api = _api((_) async => _json(200, {
            'success': true,
            'photo': {'verified': false, 'verified_at': null, 'attempts_today': 3},
            'identity': {'verified': false, 'verified_at': null, 'attempts_today': 0},
            'level': 'none',
            'is_verified': false,
            'attempts_today': 3,
            'next_attempt_time': '2026-10-24T08:00:00Z',
          }));
      final status = (await api.getStatus()).data!;
      expect(status.level, 'none');
      expect(status.photo.attemptsToday, 3);
      expect(status.nextAttemptTime, DateTime.utc(2026, 10, 24, 8));
    });

    test('a 500 is a failure', () async {
      final api = _api((_) async => http.Response('oops', 500));
      final response = await api.getStatus();
      expect(response.success, isFalse);
      expect(response.error, 'http_500');
    });
  });

  group('deleteFaceReference', () {
    test('sends DELETE and succeeds on 200', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(200, {'success': true});
      });
      final response = await api.deleteFaceReference();
      expect(response.success, isTrue);
      expect(seen.method, 'DELETE');
      expect(seen.url.path, '/api/verification/face/reference');
    });

    test('fails when the server refuses', () async {
      final api = _api((_) async => _json(404, {'success': false, 'error': 'not_found'}));
      expect((await api.deleteFaceReference()).error, 'not_found');
    });
  });
}
