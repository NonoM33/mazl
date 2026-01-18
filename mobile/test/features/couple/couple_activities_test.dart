import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_activity.dart';

import '../../mocks/mock_data.dart';
import '../../mocks/mock_couple_api_service.dart';

void main() {
  group('CoupleActivities - Unit Tests', () {
    group('MockData.activities', () {
      test('returns list of activities', () {
        final activities = MockData.activities;

        expect(activities, isNotEmpty);
        expect(activities.length, equals(5));
      });

      test('first activity has correct structure', () {
        final activity = MockData.singleActivity;

        expect(activity.id, equals(1));
        expect(activity.title, equals('Spa en duo'));
        expect(activity.category, equals('wellness'));
        expect(activity.priceCents, equals(12000));
        expect(activity.isKosher, isTrue);
      });

      test('activities have different categories', () {
        final activities = MockData.activities;
        final categories = activities.map((a) => a.category).toSet();

        expect(categories, contains('wellness'));
        expect(categories, contains('gastronomy'));
        expect(categories, contains('culture'));
        expect(categories, contains('sport'));
        expect(categories, contains('travel'));
      });

      test('activities can be filtered by category', () {
        final activities = MockData.activities;
        final wellnessActivities =
            activities.where((a) => a.category == 'wellness').toList();

        expect(wellnessActivities.length, equals(1));
        expect(wellnessActivities.first.title, equals('Spa en duo'));
      });
    });

    group('MockData.savedActivities', () {
      test('returns list of saved activities', () {
        final savedActivities = MockData.savedActivities;

        expect(savedActivities, isNotEmpty);
        expect(savedActivities.length, equals(2));
      });

      test('saved activities have savedAt timestamp', () {
        final savedActivities = MockData.savedActivities;

        for (final activity in savedActivities) {
          expect(activity.savedAt, isNotNull);
        }
      });
    });

    group('CoupleActivity model properties', () {
      test('formattedPrice returns Gratuit for free activities', () {
        final freeActivity = MockData.activities
            .firstWhere((a) => a.priceCents == 0 || a.priceCents == null);

        expect(freeActivity.formattedPrice, equals('Gratuit'));
      });

      test('formattedPrice returns price in euros', () {
        final paidActivity =
            MockData.activities.firstWhere((a) => a.priceCents == 12000);

        expect(paidActivity.formattedPrice, equals('120€'));
      });

      test('categoryEmoji returns correct emoji', () {
        final activities = MockData.activities;

        final wellnessActivity =
            activities.firstWhere((a) => a.category == 'wellness');
        expect(wellnessActivity.categoryEmoji, equals('🧖‍♀️'));

        final gastronomyActivity =
            activities.firstWhere((a) => a.category == 'gastronomy');
        expect(gastronomyActivity.categoryEmoji, equals('🍷'));

        final cultureActivity =
            activities.firstWhere((a) => a.category == 'culture');
        expect(cultureActivity.categoryEmoji, equals('🎭'));
      });

      test('formattedDuration returns correct format', () {
        final activity =
            MockData.activities.firstWhere((a) => a.durationMinutes == 120);
        expect(activity.formattedDuration, equals('2h'));

        final activity2 =
            MockData.activities.firstWhere((a) => a.durationMinutes == 180);
        expect(activity2.formattedDuration, equals('3h'));

        final activity3 =
            MockData.activities.firstWhere((a) => a.durationMinutes == 90);
        expect(activity3.formattedDuration, equals('1h30min'));
      });
    });

    group('MockCoupleApiService', () {
      late MockCoupleApiService service;

      setUp(() {
        service = MockCoupleApiService();
      });

      test('getActivities returns list of activities', () async {
        final activities = await service.getActivities();

        expect(activities, isNotEmpty);
        expect(service.methodCalls, contains('getActivities'));
      });

      test('getActivities supports pagination', () async {
        final activities = await service.getActivities(limit: 2, offset: 0);

        expect(activities.length, lessThanOrEqualTo(2));
      });

      test('getActivities supports category filter', () async {
        final activities = await service.getActivities(category: 'wellness');

        for (final activity in activities) {
          expect(activity.category, equals('wellness'));
        }
      });

      test('getActivity returns single activity', () async {
        final activity = await service.getActivity(1);

        expect(activity, isNotNull);
        expect(activity!.id, equals(1));
        expect(service.methodCalls, contains('getActivity:1'));
      });

      test('saveActivity returns true on success', () async {
        final result = await service.saveActivity(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('saveActivity:1'));
      });

      test('passActivity returns true on success', () async {
        final result = await service.passActivity(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('passActivity:1'));
      });

      test('getSavedActivities returns saved list', () async {
        final savedActivities = await service.getSavedActivities();

        expect(savedActivities, isNotEmpty);
        expect(service.methodCalls, contains('getSavedActivities'));
      });

      test('removeSavedActivity returns true on success', () async {
        final result = await service.removeSavedActivity(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('removeSavedActivity:1'));
      });

      test('shouldFail flag causes methods to return empty/false', () async {
        service.shouldFail = true;

        final activities = await service.getActivities();
        expect(activities, isEmpty);

        final activity = await service.getActivity(1);
        expect(activity, isNull);

        final saveResult = await service.saveActivity(1);
        expect(saveResult, isFalse);
      });

      test('reset clears call history and shouldFail', () {
        service.shouldFail = true;
        service.callCount = 5;
        service.methodCalls.add('test');

        service.reset();

        expect(service.shouldFail, isFalse);
        expect(service.callCount, equals(0));
        expect(service.methodCalls, isEmpty);
      });
    });
  });
}
