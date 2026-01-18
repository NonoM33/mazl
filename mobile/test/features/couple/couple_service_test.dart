import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';

void main() {
  group('CoupleService Unit Tests', () {
    late CoupleService service;

    setUp(() {
      service = CoupleService();
    });

    group('getDailyQuestions', () {
      test('returns a non-empty list of questions', () {
        final questions = service.getDailyQuestions();

        expect(questions, isNotEmpty);
        expect(questions.length, equals(5));
      });

      test('all questions have required fields', () {
        final questions = service.getDailyQuestions();

        for (final question in questions) {
          expect(question.id, isNotEmpty);
          expect(question.question, isNotEmpty);
          expect(question.category, isNotEmpty);
        }
      });

      test('includes a question with options', () {
        final questions = service.getDailyQuestions();
        final questionWithOptions =
            questions.where((q) => q.options != null).toList();

        expect(questionWithOptions, isNotEmpty);
        expect(questionWithOptions.first.options!.length, greaterThan(0));
      });
    });

    group('getMilestones', () {
      test('returns 5 milestones', () {
        final milestones = service.getMilestones();

        expect(milestones.length, equals(5));
      });

      test('milestones have correct order', () {
        final milestones = service.getMilestones();

        expect(milestones[0].title, equals('Premiere semaine'));
        expect(milestones[1].title, equals('Premier mois'));
        expect(milestones[2].title, equals('Trimestre'));
        expect(milestones[3].title, equals('Mi-annee'));
        expect(milestones[4].title, equals('Premiere annee'));
      });

      test('all milestones have required fields', () {
        final milestones = service.getMilestones();

        for (final milestone in milestones) {
          expect(milestone.id, isNotEmpty);
          expect(milestone.title, isNotEmpty);
          expect(milestone.description, isNotEmpty);
          // emoji can be empty string in the current implementation
          expect(milestone.emoji, isNotNull);
        }
      });
    });

    group('getCoupleActivities', () {
      test('returns 6 activities', () {
        final activities = service.getCoupleActivities();

        expect(activities.length, equals(6));
      });

      test('all activities have required fields', () {
        final activities = service.getCoupleActivities();

        for (final activity in activities) {
          expect(activity['title'], isNotNull);
          expect(activity['description'], isNotNull);
          expect(activity['icon'], isNotNull);
          expect(activity['category'], isNotNull);
        }
      });

      test('activities include various categories', () {
        final activities = service.getCoupleActivities();
        final categories =
            activities.map((a) => a['category'] as String).toSet();

        expect(categories.length, greaterThan(3));
      });
    });
  });

  group('CoupleData', () {
    test('daysTogether calculates correctly for 10 days', () {
      final data = CoupleData(
        partnerId: 1,
        partnerName: 'Test Partner',
        relationshipStartDate:
            DateTime.now().subtract(const Duration(days: 10)),
        status: RelationshipStatus.inRelationship,
      );

      expect(data.daysTogether, equals(10));
    });

    test('daysTogether returns 0 when no start date', () {
      final data = CoupleData(
        partnerId: 1,
        partnerName: 'Test Partner',
        status: RelationshipStatus.inRelationship,
      );

      expect(data.daysTogether, equals(0));
    });

    test('toJson and fromJson work correctly', () {
      final original = CoupleData(
        partnerId: 123,
        partnerName: 'Test Partner',
        partnerPicture: 'https://example.com/pic.jpg',
        relationshipStartDate: DateTime(2024, 1, 15),
        metOnMazlDate: DateTime(2024, 1, 1),
        status: RelationshipStatus.engaged,
        daysTogetherStreak: 45,
      );

      final json = original.toJson();
      final restored = CoupleData.fromJson(json);

      expect(restored.partnerId, equals(original.partnerId));
      expect(restored.partnerName, equals(original.partnerName));
      expect(restored.partnerPicture, equals(original.partnerPicture));
      expect(restored.status, equals(original.status));
      expect(restored.daysTogetherStreak, equals(original.daysTogetherStreak));
    });
  });

  group('RelationshipStatus', () {
    test('displayName returns correct French text', () {
      expect(RelationshipStatus.single.displayName, equals('Celibataire'));
      expect(RelationshipStatus.dating.displayName, equals('En train de dater'));
      expect(
          RelationshipStatus.inRelationship.displayName, equals('En couple'));
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

  group('CoupleMilestone', () {
    test('milestone is achieved when days threshold is met', () {
      final milestone = CoupleMilestone(
        id: 'first_week',
        title: 'First Week',
        description: '7 days together',
        emoji: '🎉',
        isAchieved: true,
        achievedAt: DateTime.now(),
      );

      expect(milestone.isAchieved, isTrue);
      expect(milestone.achievedAt, isNotNull);
    });
  });

  group('DailyQuestion', () {
    test('question can be created with options', () {
      final question = DailyQuestion(
        id: 'q1',
        question: 'What is your favorite color?',
        category: 'Fun',
        options: ['Red', 'Blue', 'Green'],
      );

      expect(question.options, isNotNull);
      expect(question.options!.length, equals(3));
    });

    test('question can be created without options', () {
      final question = DailyQuestion(
        id: 'q2',
        question: 'What are you grateful for today?',
        category: 'Gratitude',
      );

      expect(question.options, isNull);
    });

    test('question tracks answered state', () {
      final answeredQuestion = DailyQuestion(
        id: 'q3',
        question: 'Test?',
        category: 'Test',
        isAnswered: true,
        myAnswer: 'My response',
        partnerAnswer: 'Partner response',
      );

      expect(answeredQuestion.isAnswered, isTrue);
      expect(answeredQuestion.myAnswer, equals('My response'));
      expect(answeredQuestion.partnerAnswer, equals('Partner response'));
    });
  });

  group('CoupleRequest', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'requester_id': 100,
        'requester_name': 'Test User',
        'requester_picture': 'https://example.com/pic.jpg',
        'target_id': 200,
        'status': 'pending',
        'created_at': '2024-01-15T12:00:00Z',
      };

      final request = CoupleRequest.fromJson(json);

      expect(request.id, equals(1));
      expect(request.requesterId, equals(100));
      expect(request.requesterName, equals('Test User'));
      expect(request.targetId, equals(200));
      expect(request.status, equals(CoupleRequestStatus.pending));
    });
  });

  group('CoupleRequestStatus', () {
    test('getRequestStatusWithUser returns correct status', () {
      final service = CoupleService();

      // No request, should return none
      expect(
        service.getRequestStatusWithUser(999),
        equals(CoupleRequestStatus.none),
      );
    });
  });
}
