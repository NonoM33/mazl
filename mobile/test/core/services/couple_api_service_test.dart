import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_api_service.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

void main() {
  late FakeCoupleTransport transport;
  late CoupleApiService service;

  setUp(() {
    transport = FakeCoupleTransport();
    service = CoupleApiService(transport: transport);
  });

  group('activities', () {
    test(
      'decodes the rows of the feed, DECIMAL columns sent as strings',
      () async {
        transport.reply(
          'GET /api/couple/activities?limit=20&offset=0',
          ok({
            'activities': [activityRow(id: 7, title: 'Spa en duo')],
          }),
        );

        final result = await service.getActivities();

        final activities = result.valueOrNull!;
        expect(activities, hasLength(1));
        expect(activities.single.id, 7);
        expect(activities.single.title, 'Spa en duo');
        expect(activities.single.rating, 4.8);
        expect(activities.single.priceCents, 12000);
        expect(activities.single.tags, ['spa', 'duo']);
      },
    );

    test('an empty feed is an empty success, never invented content', () async {
      transport.reply(
        'GET /api/couple/activities?limit=20&offset=0',
        ok({'activities': []}),
      );

      final result = await service.getActivities();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('sends the category and the paging in the query', () async {
      transport.reply(
        'GET /api/couple/activities?limit=50&offset=10&category=romantic',
        ok({'activities': []}),
      );

      final result = await service.getActivities(
        limit: 50,
        offset: 10,
        category: 'romantic',
      );

      expect(result.isOk, isTrue);
    });

    test('"Not in a couple" is reported as such', () async {
      transport.reply(
        'GET /api/couple/activities?limit=20&offset=0',
        error('Not in a couple'),
      );

      final failure = (await service.getActivities()).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.notInCouple);
    });

    test('a missing activity is notFound', () async {
      transport.reply(
        'GET /api/couple/activities/99',
        error('Activity not found'),
      );

      final failure = (await service.getActivity(99)).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.notFound);
    });

    test(
      'an answer without the list is malformed, not an empty feed',
      () async {
        transport.reply('GET /api/couple/activities?limit=20&offset=0', ok({}));

        final failure = (await service.getActivities()).failureOrNull!;

        expect(failure.kind, CoupleFailureKind.malformed);
      },
    );

    test('pass, save and unsave use the documented routes', () async {
      transport
        ..reply('POST /api/couple/activities/4/pass', ok({}))
        ..reply('POST /api/couple/activities/4/save', ok({}))
        ..reply('DELETE /api/couple/saved/4', ok({}));

      expect((await service.passActivity(4)).isOk, isTrue);
      expect((await service.saveActivity(4)).isOk, isTrue);
      expect((await service.removeSavedActivity(4)).isOk, isTrue);
      expect(transport.calls, [
        'POST /api/couple/activities/4/pass',
        'POST /api/couple/activities/4/save',
        'DELETE /api/couple/saved/4',
      ]);
    });

    test('the saved list carries saved_at', () async {
      transport.reply(
        'GET /api/couple/saved',
        ok({
          'activities': [savedActivityRow(id: 5)],
        }),
      );

      final saved = (await service.getSavedActivities()).valueOrNull!;

      expect(saved.single.id, 5);
      expect(saved.single.savedAt, DateTime.utc(2026, 10, 20, 18, 30));
    });
  });

  group('network failures are reported, not swallowed', () {
    test('no connection', () async {
      transport.fail('GET /api/couple/saved', const SocketException('down'));

      final failure = (await service.getSavedActivities()).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.network);
      expect(failure.message, isNotEmpty);
    });

    test('timeout', () async {
      transport.fail(
        'POST /api/couple/activities/1/pass',
        TimeoutException('slow'),
      );

      final failure = (await service.passActivity(1)).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.network);
    });

    test('a body that is not JSON', () async {
      transport.fail('GET /api/couple/dates', const FormatException('<html>'));

      final failure = (await service.getDates()).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.malformed);
    });

    test('a 500 from the server', () async {
      transport.reply('GET /api/couple/dates', error('connection terminated'));

      final failure = (await service.getDates()).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.server);
    });
  });

  group('events', () {
    test('decodes the rows, DATE columns as ISO strings', () async {
      transport.reply(
        'GET /api/couple/events?limit=20&offset=0',
        ok({
          'events': [eventRow(id: 3, currentCouples: 3, maxCouples: 20)],
        }),
      );

      final event = (await service.getEvents()).valueOrNull!.single;

      expect(event.id, 3);
      expect(event.eventDate, DateTime.utc(2026, 11, 12));
      expect(event.eventTime, '19:30:00');
      expect(event.spotsLeft, 17);
    });

    test('registered events carry the registration status', () async {
      transport.reply(
        'GET /api/couple/events/registered',
        ok({
          'events': [registeredEventRow(id: 3)],
        }),
      );

      final event = (await service.getRegisteredEvents()).valueOrNull!.single;

      expect(event.registrationStatus, 'registered');
    });

    test('register and cancel use the documented routes', () async {
      transport
        ..reply('POST /api/couple/events/3/register', ok({'registration': {}}))
        ..reply('DELETE /api/couple/events/3/register', ok({}));

      expect((await service.registerForEvent(3)).isOk, isTrue);
      expect((await service.cancelEventRegistration(3)).isOk, isTrue);
    });

    test('a full event is reported as full', () async {
      transport.reply(
        'POST /api/couple/events/3/register',
        error('Event is full'),
      );

      final failure = (await service.registerForEvent(3)).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.full);
    });

    test('a missing event is notFound', () async {
      transport.reply('GET /api/couple/events/9', error('Event not found'));

      final failure = (await service.getEvent(9)).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.notFound);
    });
  });

  group('couple space', () {
    test('counters sent as strings (COUNT bigint) become numbers', () async {
      transport.reply(
        'GET /api/couple/stats',
        ok({
          'stats': statsRow(saved: '3', events: '1', memories: '5'),
          'achievements': [achievementRow()],
        }),
      );

      final snapshot = (await service.getStats()).valueOrNull!;

      expect(snapshot.stats.savedActivities, 3);
      expect(snapshot.stats.eventsRegistered, 1);
      expect(snapshot.stats.memoriesCount, 5);
      expect(snapshot.stats.bucketCompleted, 1);
      expect(snapshot.stats.bucketTotal, 4);
      expect(snapshot.stats.totalBookings, 2);
      expect(snapshot.achievements.single.name, 'Première activité');
      expect(snapshot.achievements.single.type, 'first_activity');
    });

    test('counters sent as real numbers work too', () async {
      transport.reply(
        'GET /api/couple/stats',
        ok({
          'stats': {
            'total_bookings': 0,
            'saved_activities': 2,
            'events_registered': 0,
            'memories_count': 7,
            'bucket_completed': 0,
            'bucket_total': 0,
          },
          'achievements': [],
        }),
      );

      final snapshot = (await service.getStats()).valueOrNull!;

      expect(snapshot.stats.savedActivities, 2);
      expect(snapshot.stats.memoriesCount, 7);
      expect(snapshot.achievements, isEmpty);
    });

    test('a stats answer without the stats object is malformed', () async {
      transport.reply('GET /api/couple/stats', ok({'achievements': []}));

      final failure = (await service.getStats()).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.malformed);
    });

    test('dates, bucket list and memories decode their rows', () async {
      transport
        ..reply(
          'GET /api/couple/dates',
          ok({
            'dates': [dateRow(id: 1)],
          }),
        )
        ..reply(
          'GET /api/couple/bucket-list',
          ok({
            'items': [bucketRow(id: 1), bucketRow(id: 2, completed: true)],
          }),
        )
        ..reply(
          'GET /api/couple/memories',
          ok({
            'memories': [memoryRow(id: 1)],
          }),
        );

      final dates = (await service.getDates()).valueOrNull!;
      final bucket = (await service.getBucketList()).valueOrNull!;
      final memories = (await service.getMemories()).valueOrNull!;

      expect(dates.single.title, 'Notre anniversaire');
      expect(dates.single.date, DateTime.utc(2026, 12, 1));
      expect(dates.single.type, 'anniversary');
      expect(bucket.map((i) => i.isCompleted), [false, true]);
      expect(memories.single.title, 'Notre premier voyage');
      expect(memories.single.type, 'note');
    });

    test('adding sends the body the routes read', () async {
      transport
        ..reply('POST /api/couple/dates', ok({'date': []}))
        ..reply('POST /api/couple/bucket-list', ok({'item': []}))
        ..reply('POST /api/couple/memories', ok({'memory': []}))
        ..reply('POST /api/couple/bucket-list/2/complete', ok({'item': []}));

      await service.addDate(
        title: 'Notre anniversaire',
        date: '2026-12-01',
        type: 'anniversary',
      );
      await service.addBucketListItem(title: 'Rome');
      await service.addMemory(type: 'note', title: 'Rome', content: 'En avril');
      final done = await service.completeBucketListItem(2);

      expect(transport.bodies['POST /api/couple/dates'], {
        'title': 'Notre anniversaire',
        'date': '2026-12-01',
        'type': 'anniversary',
        'isRecurring': true,
        'remindDaysBefore': 7,
      });
      expect(transport.bodies['POST /api/couple/bucket-list'], {
        'title': 'Rome',
      });
      expect(transport.bodies['POST /api/couple/memories'], {
        'type': 'note',
        'title': 'Rome',
        'content': 'En avril',
      });
      expect(done.isOk, isTrue);
    });

    test('a refused add is a failure the sheet can show', () async {
      transport.reply(
        'POST /api/couple/bucket-list',
        error('null value in column "title"'),
      );

      final failure = (await service.addBucketListItem(
        title: 'x',
      )).failureOrNull!;

      expect(failure.kind, CoupleFailureKind.server);
      expect(failure.message, isNot(contains('column')));
    });
  });
}
