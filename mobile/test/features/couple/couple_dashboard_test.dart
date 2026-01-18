import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';

void main() {
  group('CoupleDashboard - CoupleService Tests', () {
    late CoupleService service;

    setUp(() {
      service = CoupleService();
    });

    test('getDailyQuestions returns list of questions', () {
      final questions = service.getDailyQuestions();

      expect(questions, isNotEmpty);
      expect(questions.length, greaterThan(0));
      expect(questions.first.question, isNotEmpty);
      expect(questions.first.category, isNotEmpty);
    });

    test('getMilestones returns list of milestones', () {
      final milestones = service.getMilestones();

      expect(milestones, isNotEmpty);
      expect(milestones.length, equals(5));
      expect(milestones.first.title, equals('Premiere semaine'));
    });

    test('getCoupleActivities returns list of activities', () {
      final activities = service.getCoupleActivities();

      expect(activities, isNotEmpty);
      expect(activities.length, equals(6));
      expect(activities.first['title'], isNotEmpty);
    });

    test('CoupleData calculates daysTogether correctly', () {
      final data = CoupleData(
        partnerId: 1,
        partnerName: 'Test Partner',
        relationshipStartDate: DateTime.now().subtract(const Duration(days: 10)),
        status: RelationshipStatus.inRelationship,
      );

      expect(data.daysTogether, equals(10));
    });

    test('RelationshipStatus has correct display names', () {
      expect(RelationshipStatus.single.displayName, equals('Celibataire'));
      expect(RelationshipStatus.dating.displayName, equals('En train de dater'));
      expect(RelationshipStatus.inRelationship.displayName, equals('En couple'));
      expect(RelationshipStatus.engaged.displayName, equals('Fiance(e)'));
      expect(RelationshipStatus.married.displayName, equals('Marie(e)'));
    });

    test('RelationshipStatus.isInCouple returns correct values', () {
      expect(RelationshipStatus.single.isInCouple, isFalse);
      expect(RelationshipStatus.dating.isInCouple, isFalse);
      expect(RelationshipStatus.inRelationship.isInCouple, isTrue);
      expect(RelationshipStatus.engaged.isInCouple, isTrue);
      expect(RelationshipStatus.married.isInCouple, isTrue);
    });

    test('DailyQuestion can be created with category', () {
      final question = DailyQuestion(
        id: 'q1',
        question: 'Test question?',
        category: 'Test',
      );

      expect(question.id, equals('q1'));
      expect(question.question, equals('Test question?'));
      expect(question.category, equals('Test'));
      expect(question.isAnswered, isFalse);
    });

    test('CoupleMilestone tracks achievement status', () {
      final achieved = CoupleMilestone(
        id: 'test',
        title: 'Test Milestone',
        description: 'Test description',
        emoji: '🎉',
        isAchieved: true,
        achievedAt: DateTime.now(),
      );

      final notAchieved = CoupleMilestone(
        id: 'test2',
        title: 'Test Milestone 2',
        description: 'Test description 2',
        emoji: '⭐',
        isAchieved: false,
      );

      expect(achieved.isAchieved, isTrue);
      expect(achieved.achievedAt, isNotNull);
      expect(notAchieved.isAchieved, isFalse);
      expect(notAchieved.achievedAt, isNull);
    });
  });
}
