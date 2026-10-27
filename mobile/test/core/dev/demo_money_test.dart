import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/models/event.dart';
import 'package:mazl/core/premium/boost_schedule_api.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/presentation/features/boost/logic/boost_moment.dart';

/// The demo answers the new routes of the revenue lot like the server
/// (docs/premium/MONETISATION.md §4, §8, §10), read back by the REAL decoders
/// of the app. Nothing leaves the device.

({int status, Map<String, dynamic> json}) _call(
  String method,
  String path, {
  Map<String, dynamic> body = const {},
}) {
  final reply = DemoRoutes.respond(DemoRequest(method, path, const {}, body));
  return (
    status: reply.status,
    json: jsonDecode(reply.json) as Map<String, dynamic>,
  );
}

BoostScheduleInfo _info() {
  final reply = _call('GET', '/api/boost/best-time');
  expect(reply.status, 200);
  return BoostScheduleInfo.tryParse(reply.json['data'])!;
}

void main() {
  setUp(DemoStore.reset);

  group('read receipts', () {
    test('on by default, read back by the settings decoder', () {
      final settings = PremiumSettings.tryParse(
        _call('GET', '/api/premium/settings').json['data'],
      );
      expect(settings!.sendReadReceipts, isTrue);
    });

    test(
      'PUT keeps the value and the settings show it; a new session resets it',
      () {
        final put = _call(
          'PUT',
          '/api/profile/read-receipts',
          body: {'enabled': false},
        );
        expect(put.status, 200);
        expect(put.json['data'], {'send_read_receipts': false});
        expect(
          PremiumSettings.tryParse(
            _call('GET', '/api/premium/settings').json['data'],
          )!.sendReadReceipts,
          isFalse,
        );
        DemoStore.reset();
        expect(
          PremiumSettings.tryParse(
            _call('GET', '/api/premium/settings').json['data'],
          )!.sendReadReceipts,
          isTrue,
        );
      },
    );

    test('a body without a boolean is a 400', () {
      final put = _call(
        'PUT',
        '/api/profile/read-receipts',
        body: {'enabled': 'oui'},
      );
      expect(put.status, 400);
      expect(put.json['error'], 'invalid_body');
    });
  });

  group('best time and scheduled Boost', () {
    test('the best time is a Saturday evening of the next 7 days', () {
      final best = _info().bestTime!;
      final local = best.startsAt.toLocal();
      expect(local.weekday, DateTime.saturday);
      expect(local.hour, 21);
      final now = DateTime.now();
      expect(best.startsAt.isAfter(now), isTrue);
      expect(best.startsAt.isBefore(now.add(const Duration(days: 7))), isTrue);
      expect(isAfterShabbat(best.startsAt), isTrue);
      expect(_info().city, isNotNull);
      expect(_info().scheduledAt, isNull);
    });

    test('schedule, read it back, refuse a second one, cancel', () {
      final best = _info().bestTime!.startsAt;
      final first = _call(
        'POST',
        '/api/boost/schedule',
        body: {'at': best.toIso8601String()},
      );
      expect(first.status, 201);
      expect(
        DateTime.parse(first.json['data']['scheduled_at'] as String),
        best,
      );
      expect(_info().scheduledAt, best);

      final second = _call(
        'POST',
        '/api/boost/schedule',
        body: {'at': best.toIso8601String()},
      );
      expect(second.status, 409);
      expect(second.json['error'], 'already_scheduled');

      final cancelled = _call('DELETE', '/api/boost/schedule');
      expect(cancelled.status, 200);
      expect(cancelled.json['data'], {'scheduled_at': null});
      expect(_info().scheduledAt, isNull);
    });

    test('a time in the past or beyond 7 days is invalid_time', () {
      for (final at in [
        DateTime.now().subtract(const Duration(hours: 1)),
        DateTime.now().add(const Duration(days: 8)),
      ]) {
        final reply = _call(
          'POST',
          '/api/boost/schedule',
          body: {'at': at.toUtc().toIso8601String()},
        );
        expect(reply.status, 400);
        expect(reply.json['error'], 'invalid_time');
      }
      expect(_call('POST', '/api/boost/schedule').status, 400);
    });

    test('no Boost left: 402 boosts_exhausted', () {
      while (DemoStore.spendBoost()) {}
      final reply = _call(
        'POST',
        '/api/boost/schedule',
        body: {'at': _info().bestTime!.startsAt.toIso8601String()},
      );
      expect(reply.status, 402);
      expect(reply.json['error'], 'boosts_exhausted');
    });

    test('a new session forgets the schedule', () {
      _call(
        'POST',
        '/api/boost/schedule',
        body: {'at': _info().bestTime!.startsAt.toIso8601String()},
      );
      DemoStore.reset();
      expect(_info().scheduledAt, isNull);
    });
  });

  group('events', () {
    test('two paying events carry a member rate lower than their price', () {
      final events = [
        for (final e in (_call('GET', '/api/events').json['events'] as List))
          Event.fromJson(e as Map<String, dynamic>),
      ];
      final withRate = events.where((e) => e.memberPriceCents != null).toList();
      expect(withRate, hasLength(2));
      for (final event in withRate) {
        expect(event.price, greaterThan(0));
        expect(event.memberPriceCents, lessThan(event.price * 100));
      }
      expect(events.any((e) => e.memberPriceCents == null), isTrue);
    });
  });
}
