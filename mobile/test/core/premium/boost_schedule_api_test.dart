import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/premium/boost_schedule_api.dart';

// Written from the HTTP contract (docs/premium/MONETISATION.md §8):
// GET /api/boost/best-time → data { city, best_time {starts_at, weekday, hour}
// | null, scheduled_at | null }; POST /api/boost/schedule { at } → 201
// data { scheduled_at }; 400 invalid_time, 402 boosts_exhausted,
// 409 already_scheduled; DELETE /api/boost/schedule → data { scheduled_at: null }.

HttpBoostScheduleApi _api(
  Future<http.Response> Function(http.Request request) handler, {
  List<http.Request>? log,
}) => HttpBoostScheduleApi.withClient(
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

Future<BoostScheduleErrorKind> _kind(Future<Object?> call) async {
  try {
    await call;
  } on BoostScheduleException catch (e) {
    return e.kind;
  }
  fail('no exception');
}

void main() {
  group('GET /api/boost/best-time', () {
    test('reads the city, the best time and the scheduled time', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {
            'city': 'Paris',
            'best_time': {
              'starts_at': '2026-10-31T20:00:00.000Z',
              'weekday': 6,
              'hour': 21,
            },
            'scheduled_at': '2026-10-31T20:00:00.000Z',
          },
        }),
      );
      final info = await api.bestTime();
      expect(info.city, 'Paris');
      expect(info.bestTime!.startsAt, DateTime.utc(2026, 10, 31, 20));
      expect(info.bestTime!.startsAt.isUtc, isTrue);
      expect(info.scheduledAt, DateTime.utc(2026, 10, 31, 20));
    });

    test('best_time null: the city has not enough measured traffic', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'city': null, 'best_time': null, 'scheduled_at': null},
        }),
      );
      final info = await api.bestTime();
      expect(info.bestTime, isNull);
      expect(info.city, isNull);
      expect(info.scheduledAt, isNull);
    });

    test('a best_time with an unreadable date is an error', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {
            'city': 'Paris',
            'best_time': {'starts_at': 'demain', 'weekday': 6, 'hour': 21},
            'scheduled_at': null,
          },
        }),
      );
      expect(await _kind(api.bestTime()), BoostScheduleErrorKind.unknown);
    });
  });

  group('POST /api/boost/schedule', () {
    test('sends the instant in UTC and returns the scheduled time', () async {
      final log = <http.Request>[];
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'scheduled_at': '2026-10-31T20:00:00.000Z'},
        }, 201),
        log: log,
      );
      final at = await api.schedule(DateTime.utc(2026, 10, 31, 20));
      expect(at, DateTime.utc(2026, 10, 31, 20));
      expect(log.single.method, 'POST');
      expect(log.single.url.path, '/api/boost/schedule');
      expect(jsonDecode(log.single.body), {'at': '2026-10-31T20:00:00.000Z'});
    });

    test('a local instant is converted to UTC before sending', () async {
      final log = <http.Request>[];
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'scheduled_at': '2026-10-31T20:00:00.000Z'},
        }, 201),
        log: log,
      );
      await api.schedule(DateTime.utc(2026, 10, 31, 20).toLocal());
      expect(jsonDecode(log.single.body), {'at': '2026-10-31T20:00:00.000Z'});
    });

    test('maps the three refusals of the contract', () async {
      Future<BoostScheduleErrorKind> refused(String code, int status) => _kind(
        _api(
          (_) async => _json({'success': false, 'error': code}, status),
        ).schedule(DateTime.utc(2026, 10, 31, 20)),
      );
      expect(
        await refused('invalid_time', 400),
        BoostScheduleErrorKind.invalidTime,
      );
      expect(
        await refused('boosts_exhausted', 402),
        BoostScheduleErrorKind.boostsExhausted,
      );
      expect(
        await refused('already_scheduled', 409),
        BoostScheduleErrorKind.alreadyScheduled,
      );
    });

    test('401, 5xx and a lost connection', () async {
      Future<BoostScheduleErrorKind> with_(
        Future<http.Response> Function(http.Request) h,
      ) => _kind(_api(h).schedule(DateTime.utc(2026, 10, 31, 20)));
      expect(
        await with_((_) async => _json({'success': false}, 401)),
        BoostScheduleErrorKind.sessionExpired,
      );
      expect(
        await with_((_) async => _json({'success': false}, 503)),
        BoostScheduleErrorKind.server,
      );
      expect(
        await with_((_) async => throw http.ClientException('down')),
        BoostScheduleErrorKind.network,
      );
    });
  });

  group('DELETE /api/boost/schedule', () {
    test('cancels and completes on scheduled_at null', () async {
      final log = <http.Request>[];
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'scheduled_at': null},
        }),
        log: log,
      );
      await api.cancel();
      expect(log.single.method, 'DELETE');
      expect(log.single.url.path, '/api/boost/schedule');
    });

    test('an answer that still holds a schedule is an error', () async {
      final api = _api(
        (_) async => _json({
          'success': true,
          'data': {'scheduled_at': '2026-10-31T20:00:00.000Z'},
        }),
      );
      expect(await _kind(api.cancel()), BoostScheduleErrorKind.unknown);
    });
  });
}
