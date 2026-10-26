import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/analytics/analytics_event.dart';
import 'package:mazl/core/analytics/analytics_transport.dart';

class _Seen {
  String method = '';
  String path = '';
  String body = '';
  Map<String, String> headers = {};
  int calls = 0;
}

HttpAnalyticsTransport _transport(
  _Seen seen,
  Future<http.Response> Function() answer, {
  String? token = 'jwt-1',
}) => HttpAnalyticsTransport(
  platform: 'ios',
  appVersion: () async => '1.0.0+1',
  baseUrl: 'https://api.test',
  tokenProvider: () => token,
  client: MockClient((request) async {
    seen
      ..calls += 1
      ..method = request.method
      ..path = request.url.path
      ..body = request.body
      ..headers = request.headers;
    return answer();
  }),
);

final _batch = [
  QueuedEvent(
    AnalyticsEvent.screenViewed('discover')!,
    DateTime.utc(2026, 10, 26, 10, 0, 5),
  ),
  QueuedEvent(
    AnalyticsEvent.onboardingStepViewed(step: 2, stepName: 'photos')!,
    DateTime.utc(2026, 10, 26, 10, 0, 6),
  ),
  QueuedEvent(
    AnalyticsEvent.signupCompleted()!,
    DateTime.utc(2026, 10, 26, 10, 0, 7),
  ),
];

Future<http.Response> _status(int code) async => http.Response('{}', code);

void main() {
  test('posts the exact body of the contract with the Bearer token', () async {
    final seen = _Seen();
    final result = await _transport(seen, () => _status(202)).send(_batch);

    expect(result, AnalyticsSendResult.sent);
    expect([seen.method, seen.path], ['POST', '/api/analytics/events']);
    expect(seen.headers['Authorization'], 'Bearer jwt-1');
    expect(seen.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(seen.body), {
      'platform': 'ios',
      'app_version': '1.0.0+1',
      'events': [
        {
          'name': 'screen_viewed',
          'properties': {'screen': 'discover'},
          'at': '2026-10-26T10:00:05.000Z',
        },
        {
          'name': 'onboarding_step_viewed',
          'properties': {'step': 2, 'step_name': 'photos'},
          'at': '2026-10-26T10:00:06.000Z',
        },
        {
          'name': 'signup_completed',
          'properties': <String, Object?>{},
          'at': '2026-10-26T10:00:07.000Z',
        },
      ],
    });
  });

  test('a local time is sent as UTC', () async {
    final seen = _Seen();
    await _transport(seen, () => _status(202)).send([
      QueuedEvent(
        AnalyticsEvent.appOpened()!,
        DateTime.parse('2026-10-26T12:00:00+02:00').toLocal(),
      ),
    ]);
    final events = jsonDecode(seen.body)['events'] as List<dynamic>;
    expect((events.single as Map)['at'], '2026-10-26T10:00:00.000Z');
  });

  test('without a token nothing is sent and the batch is kept', () async {
    final seen = _Seen();
    final result = await _transport(
      seen,
      () => _status(202),
      token: null,
    ).send(_batch);
    expect(result, AnalyticsSendResult.retry);
    expect(seen.calls, 0);
  });

  group('the batch is kept when', () {
    for (final status in [401, 403, 408, 429, 500, 502, 503]) {
      test('the server answers $status', () async {
        final result = await _transport(
          _Seen(),
          () => _status(status),
        ).send(_batch);
        expect(result, AnalyticsSendResult.retry);
      });
    }

    test('the network fails', () async {
      final result = await _transport(
        _Seen(),
        () async => throw const SocketException('offline'),
      ).send(_batch);
      expect(result, AnalyticsSendResult.retry);
    });

    test('the client fails', () async {
      final result = await _transport(
        _Seen(),
        () async => throw http.ClientException('down'),
      ).send(_batch);
      expect(result, AnalyticsSendResult.retry);
    });
  });

  for (final status in [400, 413, 422]) {
    test('the server refusing the batch ($status) drops it', () async {
      final result = await _transport(
        _Seen(),
        () => _status(status),
      ).send(_batch);
      expect(result, AnalyticsSendResult.rejected);
    });
  }
}
