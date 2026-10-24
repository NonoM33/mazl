import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/l10n/generated/app_localizations_fr.dart';
import 'package:mazl/presentation/features/couple/l10n/couple_feed_labels.dart';
import 'package:mazl/core/models/couple_event.dart';

import '../../mocks/mock_data.dart';
import '../../mocks/mock_couple_api_service.dart';

final _fr = AppLocalizationsFr();

void main() {
  setUpAll(initializeDateFormatting);

  group('CoupleEvents - Unit Tests', () {
    group('MockData.events', () {
      test('returns list of events', () {
        final events = MockData.events;

        expect(events, isNotEmpty);
        expect(events.length, equals(3));
      });

      test('first event has correct structure', () {
        final event = MockData.singleEvent;

        expect(event.id, equals(1));
        expect(event.title, equals('Dîner Shabbat Couples'));
        expect(event.category, equals('dinner'));
        expect(event.priceCents, equals(7500));
        expect(event.isKosher, isTrue);
        expect(event.isFeatured, isTrue);
      });

      test('events have different categories', () {
        final events = MockData.events;
        final categories = events.map((e) => e.category).toSet();

        expect(categories, contains('dinner'));
        expect(categories, contains('brunch'));
        expect(categories, contains('game'));
      });

      test('events can be filtered by category', () {
        final events = MockData.events;
        final dinnerEvents =
            events.where((e) => e.category == 'dinner').toList();

        expect(dinnerEvents.length, equals(1));
        expect(dinnerEvents.first.title, equals('Dîner Shabbat Couples'));
      });
    });

    group('MockData.registeredEvents', () {
      test('returns list of registered events', () {
        final registeredEvents = MockData.registeredEvents;

        expect(registeredEvents, isNotEmpty);
        expect(registeredEvents.length, equals(1));
      });

      test('registered events have registeredAt timestamp', () {
        final registeredEvents = MockData.registeredEvents;

        for (final event in registeredEvents) {
          expect(event.registeredAt, isNotNull);
          expect(event.registrationStatus, equals('registered'));
        }
      });
    });

    group('CoupleEvent model properties', () {
      test('priceEuros is null for free events', () {
        final freeEvent = MockData.events
            .firstWhere((e) => e.priceCents == 0 || e.priceCents == null);

        expect(freeEvent.priceEuros, isNull);
      });

      test('priceEuros is the price in whole euros', () {
        final paidEvent =
            MockData.events.firstWhere((e) => e.priceCents == 7500);

        expect(paidEvent.priceEuros, equals(75));
      });

      test('spotsLeft calculates correctly', () {
        final event = MockData.events.firstWhere(
            (e) => e.maxCouples != null);

        final expected = event.maxCouples! - event.currentCouples;
        expect(event.spotsLeft, equals(expected));
      });

      test('spotsLeft returns -1 for unlimited events', () {
        final event = CoupleEvent(
          id: 99,
          title: 'Unlimited Event',
          description: '',
          eventDate: DateTime.now(),
          maxCouples: null,
        );

        expect(event.spotsLeft, equals(-1));
      });

      test('isFull returns true when no spots left', () {
        final fullEvent = CoupleEvent(
          id: 99,
          title: 'Full Event',
          description: '',
          eventDate: DateTime.now(),
          maxCouples: 10,
          currentCouples: 10,
        );

        expect(fullEvent.isFull, isTrue);
      });

      test('isFull returns false when spots available', () {
        final event = MockData.singleEvent;

        expect(event.isFull, isFalse);
      });

      test('categoryEmoji returns correct emoji', () {
        final dinnerEvent =
            MockData.events.firstWhere((e) => e.category == 'dinner');
        expect(dinnerEvent.categoryEmoji, equals('🍽️'));

        final gameEvent =
            MockData.events.firstWhere((e) => e.category == 'game');
        expect(gameEvent.categoryEmoji, equals('🎮'));
      });

      test('timeLabel writes the time of the language', () {
        final event =
            MockData.events.firstWhere((e) => e.eventTime == '19:00');

        expect(event.timeLabel(_fr), equals('19:00'));
      });

      test('timeLabel is empty for a null time', () {
        final event = CoupleEvent(
          id: 99,
          title: 'No time event',
          description: '',
          eventDate: DateTime.now(),
          eventTime: null,
        );

        expect(event.timeLabel(_fr), isEmpty);
      });

      test('dateLabel contains day and month', () {
        final event = MockData.singleEvent;
        final formatted = event.dateLabel(_fr);

        // Should contain a day number
        expect(formatted, matches(RegExp(r'\d+')));
      });
    });

    group('MockCoupleApiService - Events', () {
      late MockCoupleApiService service;

      setUp(() {
        service = MockCoupleApiService();
      });

      test('getEvents returns list of events', () async {
        final events = await service.getEvents();

        expect(events, isNotEmpty);
        expect(service.methodCalls, contains('getEvents'));
      });

      test('getEvents supports pagination', () async {
        final events = await service.getEvents(limit: 2, offset: 0);

        expect(events.length, lessThanOrEqualTo(2));
      });

      test('getEvents supports category filter', () async {
        final events = await service.getEvents(category: 'dinner');

        for (final event in events) {
          expect(event.category, equals('dinner'));
        }
      });

      test('getEvent returns single event', () async {
        final event = await service.getEvent(1);

        expect(event, isNotNull);
        expect(event!.id, equals(1));
        expect(service.methodCalls, contains('getEvent:1'));
      });

      test('registerForEvent returns true on success', () async {
        final result = await service.registerForEvent(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('registerForEvent:1'));
      });

      test('cancelEventRegistration returns true on success', () async {
        final result = await service.cancelEventRegistration(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('cancelEventRegistration:1'));
      });

      test('getRegisteredEvents returns registered list', () async {
        final registeredEvents = await service.getRegisteredEvents();

        expect(registeredEvents, isNotEmpty);
        expect(service.methodCalls, contains('getRegisteredEvents'));
      });

      test('shouldFail flag causes methods to return empty/false', () async {
        service.shouldFail = true;

        final events = await service.getEvents();
        expect(events, isEmpty);

        final event = await service.getEvent(1);
        expect(event, isNull);

        final registerResult = await service.registerForEvent(1);
        expect(registerResult, isFalse);
      });

      test('callCount tracks method invocations', () async {
        expect(service.callCount, equals(0));

        await service.getEvents();
        expect(service.callCount, equals(1));

        await service.getEvent(1);
        expect(service.callCount, equals(2));

        await service.registerForEvent(1);
        expect(service.callCount, equals(3));
      });
    });
  });
}
