import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_activity.dart';
import 'package:mazl/core/models/couple_event.dart';

void main() {
  group('CoupleActivity', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 1,
          'title': 'Spa en duo',
          'description': 'Relaxation pour deux',
          'category': 'wellness',
          'subcategory': 'massage',
          'image_url': 'https://example.com/spa.jpg',
          'price_cents': 12000,
          'location': 'Paris',
          'address': '123 Rue de Rivoli',
          'city': 'Paris',
          'rating': 4.8,
          'review_count': 124,
          'is_kosher': true,
          'is_partner': true,
          'partner_name': 'Spa Partner',
          'discount_percent': 15,
          'discount_code': 'COUPLE15',
          'booking_url': 'https://book.example.com',
          'phone': '+33123456789',
          'website': 'https://spa.example.com',
          'duration_minutes': 120,
          'tags': ['relaxation', 'massage'],
        };

        final activity = CoupleActivity.fromJson(json);

        expect(activity.id, equals(1));
        expect(activity.title, equals('Spa en duo'));
        expect(activity.description, equals('Relaxation pour deux'));
        expect(activity.category, equals('wellness'));
        expect(activity.subcategory, equals('massage'));
        expect(activity.imageUrl, equals('https://example.com/spa.jpg'));
        expect(activity.priceCents, equals(12000));
        expect(activity.location, equals('Paris'));
        expect(activity.rating, equals(4.8));
        expect(activity.isKosher, isTrue);
        expect(activity.isPartner, isTrue);
        expect(activity.discountPercent, equals(15));
        expect(activity.durationMinutes, equals(120));
        expect(activity.tags, contains('relaxation'));
      });

      test('handles null optional fields', () {
        final json = {
          'id': 1,
          'title': 'Simple Activity',
          'category': 'culture',
        };

        final activity = CoupleActivity.fromJson(json);

        expect(activity.id, equals(1));
        expect(activity.title, equals('Simple Activity'));
        expect(activity.description, isEmpty);
        expect(activity.imageUrl, isNull);
        expect(activity.priceCents, isNull);
        expect(activity.isKosher, isFalse);
      });

      test('parses saved_at correctly', () {
        final json = {
          'id': 1,
          'title': 'Saved Activity',
          'category': 'wellness',
          'saved_at': '2024-06-15T12:00:00Z',
          'user_notes': 'Test note',
        };

        final activity = CoupleActivity.fromJson(json);

        expect(activity.savedAt, isNotNull);
        expect(activity.savedAt!.year, equals(2024));
        expect(activity.userNotes, equals('Test note'));
      });
    });

    group('formattedPrice', () {
      test('returns Gratuit for null price', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Free Activity',
          description: '',
          category: 'culture',
        );

        expect(activity.formattedPrice, equals('Gratuit'));
      });

      test('returns Gratuit for zero price', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Free Activity',
          description: '',
          category: 'culture',
          priceCents: 0,
        );

        expect(activity.formattedPrice, equals('Gratuit'));
      });

      test('formats price in euros correctly', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Paid Activity',
          description: '',
          category: 'wellness',
          priceCents: 12500,
        );

        expect(activity.formattedPrice, equals('125€'));
      });
    });

    group('formattedDuration', () {
      test('returns empty string for null duration', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Activity',
          description: '',
          category: 'culture',
        );

        expect(activity.formattedDuration, isEmpty);
      });

      test('formats minutes only correctly', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Activity',
          description: '',
          category: 'culture',
          durationMinutes: 45,
        );

        expect(activity.formattedDuration, equals('45min'));
      });

      test('formats hours only correctly', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Activity',
          description: '',
          category: 'culture',
          durationMinutes: 120,
        );

        expect(activity.formattedDuration, equals('2h'));
      });

      test('formats hours and minutes correctly', () {
        final activity = CoupleActivity(
          id: 1,
          title: 'Activity',
          description: '',
          category: 'culture',
          durationMinutes: 150,
        );

        expect(activity.formattedDuration, equals('2h30min'));
      });
    });

    group('categoryEmoji', () {
      test('returns correct emoji for each category', () {
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'wellness')
              .categoryEmoji,
          equals('🧖‍♀️'),
        );
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'gastronomy')
              .categoryEmoji,
          equals('🍷'),
        );
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'culture')
              .categoryEmoji,
          equals('🎭'),
        );
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'romantic')
              .categoryEmoji,
          equals('💕'),
        );
      });

      test('returns default emoji for unknown category', () {
        final activity = CoupleActivity(
          id: 1,
          title: '',
          description: '',
          category: 'unknown',
        );

        expect(activity.categoryEmoji, equals('✨'));
      });
    });

    group('categoryLabel', () {
      test('returns correct French label for each category', () {
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'wellness')
              .categoryLabel,
          equals('Bien-être'),
        );
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'gastronomy')
              .categoryLabel,
          equals('Gastronomie'),
        );
        expect(
          CoupleActivity(id: 1, title: '', description: '', category: 'spiritual')
              .categoryLabel,
          equals('Spirituel'),
        );
      });
    });
  });

  group('CoupleEvent', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 1,
          'title': 'Dîner Shabbat',
          'description': 'Soirée exclusive',
          'category': 'dinner',
          'image_url': 'https://example.com/event.jpg',
          'event_date': '2024-06-15',
          'event_time': '19:00',
          'end_time': '23:00',
          'location': 'Paris',
          'address': '123 Rue de Rivoli',
          'city': 'Paris',
          'price_cents': 7500,
          'max_couples': 20,
          'current_couples': 12,
          'is_kosher': true,
          'dress_code': 'Chic',
          'what_included': 'Repas complet',
          'organizer_name': 'MAZL Events',
          'is_featured': true,
        };

        final event = CoupleEvent.fromJson(json);

        expect(event.id, equals(1));
        expect(event.title, equals('Dîner Shabbat'));
        expect(event.description, equals('Soirée exclusive'));
        expect(event.category, equals('dinner'));
        expect(event.eventDate.year, equals(2024));
        expect(event.eventTime, equals('19:00'));
        expect(event.priceCents, equals(7500));
        expect(event.maxCouples, equals(20));
        expect(event.currentCouples, equals(12));
        expect(event.isKosher, isTrue);
        expect(event.isFeatured, isTrue);
      });

      test('parses registration fields', () {
        final json = {
          'id': 1,
          'title': 'Event',
          'description': '',
          'event_date': '2024-06-15',
          'registered_at': '2024-06-01T10:00:00Z',
          'registration_status': 'registered',
        };

        final event = CoupleEvent.fromJson(json);

        expect(event.registeredAt, isNotNull);
        expect(event.registrationStatus, equals('registered'));
      });
    });

    group('formattedPrice', () {
      test('returns Gratuit for null price', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Free Event',
          description: '',
          eventDate: DateTime.now(),
        );

        expect(event.formattedPrice, equals('Gratuit'));
      });

      test('formats price with /couple suffix', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Paid Event',
          description: '',
          eventDate: DateTime.now(),
          priceCents: 7500,
        );

        expect(event.formattedPrice, equals('75€/couple'));
      });
    });

    group('spotsLeft', () {
      test('returns -1 for unlimited events', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
        );

        expect(event.spotsLeft, equals(-1));
      });

      test('calculates spots correctly', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
          maxCouples: 20,
          currentCouples: 12,
        );

        expect(event.spotsLeft, equals(8));
      });
    });

    group('isFull', () {
      test('returns false for unlimited events', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
          currentCouples: 100,
        );

        expect(event.isFull, isFalse);
      });

      test('returns true when full', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
          maxCouples: 20,
          currentCouples: 20,
        );

        expect(event.isFull, isTrue);
      });

      test('returns false when spots available', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
          maxCouples: 20,
          currentCouples: 10,
        );

        expect(event.isFull, isFalse);
      });
    });

    group('formattedDate', () {
      test('formats date in French', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime(2024, 6, 15), // Saturday June 15
        );

        expect(event.formattedDate, contains('15'));
        expect(event.formattedDate, contains('Juin'));
      });
    });

    group('formattedTime', () {
      test('returns empty string for null time', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
        );

        expect(event.formattedTime, isEmpty);
      });

      test('formats time correctly', () {
        final event = CoupleEvent(
          id: 1,
          title: 'Event',
          description: '',
          eventDate: DateTime.now(),
          eventTime: '19:30',
        );

        expect(event.formattedTime, equals('19h30'));
      });
    });

    group('categoryEmoji', () {
      test('returns correct emoji for each category', () {
        expect(
          CoupleEvent(
            id: 1,
            title: '',
            description: '',
            eventDate: DateTime.now(),
            category: 'dinner',
          ).categoryEmoji,
          equals('🍽️'),
        );
        expect(
          CoupleEvent(
            id: 1,
            title: '',
            description: '',
            eventDate: DateTime.now(),
            category: 'party',
          ).categoryEmoji,
          equals('🎉'),
        );
        expect(
          CoupleEvent(
            id: 1,
            title: '',
            description: '',
            eventDate: DateTime.now(),
            category: 'spiritual',
          ).categoryEmoji,
          equals('✡️'),
        );
      });
    });
  });
}
