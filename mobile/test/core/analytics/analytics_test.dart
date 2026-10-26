import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/analytics/analytics_event.dart';
import 'package:mazl/core/analytics/analytics_transport.dart';

import 'analytics_fakes.dart';

class _Rig {
  _Rig() {
    analytics = Analytics(
      transport: transport,
      clock: clock.call,
      periodicTimer: timers.call,
    );
  }

  final transport = FakeAnalyticsTransport();
  final clock = FakeClock();
  final timers = FakeTimers();
  late final Analytics analytics;

  void track(AnalyticsEvent? event) => analytics.track(event);
  void screen(String name) => track(AnalyticsEvent.screenViewed(name));
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('without consent nothing is sent', () {
    test('unknown consent: events wait in memory, nothing leaves', () async {
      final rig = _Rig();
      rig.analytics.signedIn();
      rig.screen('discover');
      rig.timers.fire();
      await rig.analytics.flush();
      await rig.analytics.onBackground();
      expect(rig.transport.batches, isEmpty);
      expect(rig.analytics.pendingCount, 1);
    });

    test('denied consent: nothing is kept and nothing leaves', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: false);
      rig.screen('discover');
      await rig.analytics.flush();
      expect(rig.transport.batches, isEmpty);
      expect(rig.analytics.pendingCount, 0);
    });

    test('granted but not signed in: nothing leaves', () async {
      final rig = _Rig();
      rig.analytics.consentLoaded(granted: true);
      rig.screen('discover');
      await rig.analytics.flush();
      expect(rig.transport.batches, isEmpty);
    });

    test('a missing (invalid) event is ignored', () async {
      final rig = _Rig();
      rig.track(null);
      rig.track(AnalyticsEvent.screenViewed('/chat/42'));
      expect(rig.analytics.pendingCount, 0);
    });
  });

  group('after the agreement', () {
    test('the events held before go out with their original time, '
        'after analytics_consent_granted', () async {
      final rig = _Rig();
      rig.analytics.signedIn();
      rig.screen('login');
      final first = rig.clock.now;
      rig.clock.advance(const Duration(minutes: 2));
      rig.screen('discover');

      rig.clock.advance(const Duration(minutes: 1));
      rig.analytics.consentDecided(granted: true);
      await _settle();

      final batch = rig.transport.batches.single;
      expect(batch.map((e) => e.event.name), [
        'analytics_consent_granted',
        'screen_viewed',
        'screen_viewed',
      ]);
      expect(batch[1].at, first);
      expect(batch[2].at, first.add(const Duration(minutes: 2)));
      expect(batch[0].at, rig.clock.now);
      expect(rig.analytics.pendingCount, 0);
    });

    test('a consent already on file is not announced again', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      await rig.analytics.flush();
      expect(rig.transport.sentNames, ['screen_viewed']);
    });

    test('events go out at the next cycle of the timer', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      expect(rig.transport.batches, isEmpty);
      rig.timers.fire();
      await _settle();
      expect(rig.transport.sentNames, ['screen_viewed']);
    });

    test(
      'twenty waiting events go out without waiting for the timer',
      () async {
        final rig = _Rig();
        rig.analytics
          ..signedIn()
          ..consentLoaded(granted: true);
        for (var i = 0; i < 19; i++) {
          rig.screen('discover');
        }
        await _settle();
        expect(rig.transport.batches, isEmpty);
        rig.screen('discover');
        await _settle();
        expect(rig.transport.batches.single, hasLength(20));
      },
    );

    test('going to the background flushes', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      await rig.analytics.onBackground();
      expect(rig.transport.sentNames, ['screen_viewed']);
    });

    test('a batch holds 50 events at most', () async {
      final rig = _Rig();
      rig.analytics.signedIn();
      for (var i = 0; i < 70; i++) {
        rig.screen('discover');
      }
      rig.analytics.consentLoaded(granted: true);
      await rig.analytics.flush();
      expect(
        rig.transport.batches.map((b) => b.length),
        everyElement(lessThanOrEqualTo(50)),
      );
      expect(rig.analytics.pendingCount, 0);
    });
  });

  group('refusal and withdrawal', () {
    test('a refusal loses what was held', () async {
      final rig = _Rig();
      rig.analytics.signedIn();
      rig.screen('login');
      rig.analytics.consentDecided(granted: false);
      await rig.analytics.flush();
      expect(rig.analytics.pendingCount, 0);
      expect(rig.transport.batches, isEmpty);
    });

    test(
      'a withdrawal empties the queue and stops the sending at once',
      () async {
        final rig = _Rig();
        rig.analytics
          ..signedIn()
          ..consentLoaded(granted: true);
        rig.screen('discover');
        rig.analytics.consentDecided(granted: false);
        rig.timers.fire();
        rig.screen('chat');
        await rig.analytics.flush();
        await rig.analytics.onBackground();
        expect(rig.transport.batches, isEmpty);
        expect(rig.analytics.pendingCount, 0);
        expect(rig.timers.active, isEmpty);
      },
    );

    test(
      'a withdrawal while a batch is in flight keeps what came after out',
      () async {
        final rig = _Rig();
        rig.transport.gate = Completer<AnalyticsSendResult>();
        rig.analytics
          ..signedIn()
          ..consentLoaded(granted: true);
        rig.screen('discover');
        final flushing = rig.analytics.flush();
        await _settle();
        rig.analytics.consentDecided(granted: false);
        rig.transport.gate!.complete(AnalyticsSendResult.retry);
        await flushing;
        expect(rig.analytics.pendingCount, 0);
      },
    );

    test('signing out empties the queue and forgets the consent', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      rig.analytics.signedOut();
      expect(rig.analytics.pendingCount, 0);
      expect(rig.analytics.consent, AnalyticsConsentState.unknown);
      rig.screen('login');
      await rig.analytics.flush();
      expect(rig.transport.batches, isEmpty);
      expect(rig.timers.active, isEmpty);
    });
  });

  group('the memory is bounded', () {
    test(
      '100 events at most while the consent is unknown, the oldest fall',
      () async {
        final rig = _Rig();
        rig.analytics.signedIn();
        for (var i = 0; i < 130; i++) {
          rig.clock.advance(const Duration(seconds: 1));
          rig.screen('discover');
        }
        expect(rig.analytics.pendingCount, 100);
        rig.analytics.consentLoaded(granted: true);
        await rig.analytics.flush();
        final sent = [for (final b in rig.transport.batches) ...b];
        expect(sent, hasLength(100));
        expect(
          sent.first.at,
          DateTime.utc(2026, 10, 26, 10).add(const Duration(seconds: 31)),
        );
      },
    );
  });

  group('network failures', () {
    test('a failed batch is kept and sent again at the next cycle', () async {
      final rig = _Rig();
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      rig.transport.result = AnalyticsSendResult.retry;
      rig.timers.fire();
      await _settle();
      expect(rig.transport.batches, hasLength(1));
      expect(rig.analytics.pendingCount, 1);

      rig.transport.result = AnalyticsSendResult.sent;
      rig.timers.fire();
      await _settle();
      expect(rig.transport.batches, hasLength(2));
      expect(rig.analytics.pendingCount, 0);
    });

    test('a failure does not loop: one attempt per cycle', () async {
      final rig = _Rig();
      rig.transport.result = AnalyticsSendResult.retry;
      rig.analytics
        ..signedIn()
        ..consentLoaded(granted: true);
      rig.screen('discover');
      await rig.analytics.flush();
      await _settle();
      expect(rig.transport.batches, hasLength(1));
    });

    test(
      'while offline, 100 events at most are kept, the oldest fall',
      () async {
        final rig = _Rig();
        rig.transport.result = AnalyticsSendResult.retry;
        rig.analytics
          ..signedIn()
          ..consentLoaded(granted: true);
        for (var i = 0; i < 150; i++) {
          rig.screen('discover');
          await rig.analytics.flush();
        }
        expect(rig.analytics.pendingCount, 100);
      },
    );

    test(
      'a batch the server rejects is dropped, not retried forever',
      () async {
        final rig = _Rig();
        rig.transport.result = AnalyticsSendResult.rejected;
        rig.analytics
          ..signedIn()
          ..consentLoaded(granted: true);
        rig.screen('discover');
        await rig.analytics.flush();
        expect(rig.analytics.pendingCount, 0);
      },
    );

    test('a transport that throws keeps the batch', () async {
      final rig = _Rig();
      final analytics =
          Analytics(
              transport: _ThrowingTransport(),
              clock: rig.clock.call,
              periodicTimer: rig.timers.call,
            )
            ..signedIn()
            ..consentLoaded(granted: true)
            ..track(AnalyticsEvent.screenViewed('discover'));
      await analytics.flush();
      expect(analytics.pendingCount, 1);
    });
  });

  test('the timer runs only while granted and signed in', () {
    final rig = _Rig();
    expect(rig.timers.active, isEmpty);
    rig.analytics.signedIn();
    expect(rig.timers.active, isEmpty);
    rig.analytics.consentLoaded(granted: true);
    expect(rig.timers.active, hasLength(1));
    rig.analytics.consentLoaded(granted: true);
    expect(rig.timers.active, hasLength(1));
    rig.analytics.consentDecided(granted: false);
    expect(rig.timers.active, isEmpty);
  });

  test('a consent loaded as "never asked" keeps the state unknown', () {
    final rig = _Rig();
    rig.analytics
      ..signedIn()
      ..consentLoaded(granted: null);
    expect(rig.analytics.consent, AnalyticsConsentState.unknown);
  });
}

class _ThrowingTransport implements AnalyticsTransport {
  @override
  Future<AnalyticsSendResult> send(List<QueuedEvent> batch) =>
      throw StateError('boom');
}
