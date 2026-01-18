import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';

import '../../mocks/mock_data.dart';
import '../../mocks/mock_couple_api_service.dart';

void main() {
  group('CoupleSpace - Unit Tests', () {
    group('MockData.dates', () {
      test('returns list of dates', () {
        final dates = MockData.dates;

        expect(dates, isNotEmpty);
        expect(dates.length, equals(2));
      });

      test('first date has correct structure', () {
        final date = MockData.dates.first;

        expect(date['id'], equals(1));
        expect(date['title'], equals('Notre anniversaire'));
        expect(date['type'], equals('anniversary'));
        expect(date['is_recurring'], isTrue);
        expect(date['remind_days_before'], equals(7));
      });

      test('dates have different types', () {
        final dates = MockData.dates;
        final types = dates.map((d) => d['type']).toSet();

        expect(types, contains('anniversary'));
        expect(types, contains('memory'));
      });
    });

    group('MockData.bucketList', () {
      test('returns list of bucket list items', () {
        final bucketList = MockData.bucketList;

        expect(bucketList, isNotEmpty);
        expect(bucketList.length, equals(2));
      });

      test('first item has correct structure', () {
        final item = MockData.bucketList.first;

        expect(item['id'], equals(1));
        expect(item['title'], equals('Voir les aurores boréales'));
        expect(item['category'], equals('travel'));
        expect(item['is_completed'], isFalse);
      });

      test('can have completed items', () {
        final completedItems =
            MockData.bucketList.where((b) => b['is_completed'] == true).toList();

        expect(completedItems.length, equals(1));
        expect(completedItems.first['completed_at'], isNotNull);
      });

      test('can have pending items', () {
        final pendingItems =
            MockData.bucketList.where((b) => b['is_completed'] == false).toList();

        expect(pendingItems.length, equals(1));
        expect(pendingItems.first['completed_at'], isNull);
      });
    });

    group('MockData.memories', () {
      test('returns list of memories', () {
        final memories = MockData.memories;

        expect(memories, isNotEmpty);
        expect(memories.length, equals(2));
      });

      test('first memory has correct structure', () {
        final memory = MockData.memories.first;

        expect(memory['id'], equals(1));
        expect(memory['type'], equals('note'));
        expect(memory['title'], equals('Notre premier rendez-vous'));
        expect(memory['content'], isNotEmpty);
      });

      test('memories have different types', () {
        final memories = MockData.memories;
        final types = memories.map((m) => m['type']).toSet();

        expect(types, contains('note'));
        expect(types, contains('photo'));
      });

      test('photo memories have image_url', () {
        final photoMemory =
            MockData.memories.firstWhere((m) => m['type'] == 'photo');

        expect(photoMemory['image_url'], isNotNull);
        expect(photoMemory['image_url'], contains('http'));
      });
    });

    group('MockData.coupleData', () {
      test('returns couple data', () {
        final coupleData = MockData.coupleData;

        expect(coupleData, isNotNull);
        expect(coupleData.partnerId, equals(42));
        expect(coupleData.partnerName, equals('Sarah'));
      });

      test('has relationship status', () {
        final coupleData = MockData.coupleData;

        expect(coupleData.status, equals(RelationshipStatus.inRelationship));
        expect(coupleData.status.isInCouple, isTrue);
      });

      test('calculates days together', () {
        final coupleData = MockData.coupleData;

        expect(coupleData.daysTogether, greaterThan(0));
        expect(coupleData.daysTogether, equals(100));
      });

      test('has partner picture', () {
        final coupleData = MockData.coupleData;

        expect(coupleData.partnerPicture, isNotNull);
        expect(coupleData.partnerPicture, contains('http'));
      });
    });

    group('MockData.stats', () {
      test('returns stats map', () {
        final stats = MockData.stats;

        expect(stats, isNotNull);
        expect(stats['stats'], isNotNull);
      });

      test('stats has correct keys', () {
        final statsData = MockData.stats['stats'] as Map<String, dynamic>;

        expect(statsData['days_together'], equals(100));
        expect(statsData['activities_done'], equals(15));
        expect(statsData['events_attended'], equals(5));
        expect(statsData['memories_count'], equals(25));
        expect(statsData['bucket_list_completed'], equals(3));
      });

      test('achievements list exists', () {
        final achievements = MockData.stats['achievements'] as List;

        expect(achievements, isNotEmpty);
        expect(achievements.length, equals(3));
      });

      test('achievements have correct structure', () {
        final achievements = MockData.stats['achievements'] as List;
        final firstAchievement = achievements.first as Map<String, dynamic>;

        expect(firstAchievement['id'], isNotNull);
        expect(firstAchievement['title'], isNotNull);
        expect(firstAchievement['achieved'], isTrue);
      });
    });

    group('MockCoupleApiService - CoupleSpace', () {
      late MockCoupleApiService service;

      setUp(() {
        service = MockCoupleApiService();
      });

      test('getDates returns list of dates', () async {
        final dates = await service.getDates();

        expect(dates, isNotEmpty);
        expect(service.methodCalls, contains('getDates'));
      });

      test('addDate returns true on success', () async {
        final result = await service.addDate(
          title: 'Test Date',
          date: '2024-12-25',
          type: 'holiday',
        );

        expect(result, isTrue);
        expect(service.methodCalls, contains('addDate:Test Date'));
      });

      test('getBucketList returns list of items', () async {
        final bucketList = await service.getBucketList();

        expect(bucketList, isNotEmpty);
        expect(service.methodCalls, contains('getBucketList'));
      });

      test('addBucketListItem returns true on success', () async {
        final result = await service.addBucketListItem(
          title: 'Visit Japan',
          category: 'travel',
        );

        expect(result, isTrue);
        expect(service.methodCalls, contains('addBucketListItem:Visit Japan'));
      });

      test('completeBucketListItem returns true on success', () async {
        final result = await service.completeBucketListItem(1);

        expect(result, isTrue);
        expect(service.methodCalls, contains('completeBucketListItem:1'));
      });

      test('getMemories returns list of memories', () async {
        final memories = await service.getMemories();

        expect(memories, isNotEmpty);
        expect(service.methodCalls, contains('getMemories'));
      });

      test('addMemory returns true on success', () async {
        final result = await service.addMemory(
          type: 'note',
          title: 'Test Memory',
          content: 'This is a test memory',
        );

        expect(result, isTrue);
        expect(service.methodCalls, contains('addMemory:note'));
      });

      test('getStats returns stats map', () async {
        final stats = await service.getStats();

        expect(stats, isNotNull);
        expect(service.methodCalls, contains('getStats'));
      });

      test('shouldFail flag causes methods to return empty/null', () async {
        service.shouldFail = true;

        final dates = await service.getDates();
        expect(dates, isEmpty);

        final bucketList = await service.getBucketList();
        expect(bucketList, isEmpty);

        final memories = await service.getMemories();
        expect(memories, isEmpty);

        final stats = await service.getStats();
        expect(stats, isNull);

        final addResult = await service.addDate(
          title: 'Test',
          date: '2024-01-01',
          type: 'test',
        );
        expect(addResult, isFalse);
      });
    });

    group('CoupleService - local data', () {
      late CoupleService coupleService;

      setUp(() {
        coupleService = CoupleService();
      });

      test('getDailyQuestions returns questions', () {
        final questions = coupleService.getDailyQuestions();

        expect(questions, isNotEmpty);
        expect(questions.first.question, isNotEmpty);
        expect(questions.first.category, isNotEmpty);
      });

      test('getMilestones returns milestones', () {
        final milestones = coupleService.getMilestones();

        expect(milestones, isNotEmpty);
        expect(milestones.first.title, isNotEmpty);
        expect(milestones.first.description, isNotEmpty);
      });

      test('getCoupleActivities returns activities', () {
        final activities = coupleService.getCoupleActivities();

        expect(activities, isNotEmpty);
        expect(activities.first['title'], isNotEmpty);
      });
    });

    group('RelationshipStatus', () {
      test('displayName returns French labels', () {
        expect(RelationshipStatus.single.displayName, equals('Celibataire'));
        expect(RelationshipStatus.dating.displayName, equals('En train de dater'));
        expect(RelationshipStatus.inRelationship.displayName, equals('En couple'));
        expect(RelationshipStatus.engaged.displayName, equals('Fiance(e)'));
        expect(RelationshipStatus.married.displayName, equals('Marie(e)'));
      });

      test('isInCouple returns correct values', () {
        expect(RelationshipStatus.single.isInCouple, isFalse);
        expect(RelationshipStatus.dating.isInCouple, isFalse);
        expect(RelationshipStatus.inRelationship.isInCouple, isTrue);
        expect(RelationshipStatus.engaged.isInCouple, isTrue);
        expect(RelationshipStatus.married.isInCouple, isTrue);
      });
    });
  });
}
