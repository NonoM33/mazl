import 'package:mazl/core/models/couple_activity.dart';
import 'package:mazl/core/models/couple_event.dart';
import 'package:mazl/core/services/couple_service.dart';

/// Mock data factory for testing
class MockData {
  // ============ COUPLE ACTIVITIES ============

  static List<CoupleActivity> get activities => [
        CoupleActivity(
          id: 1,
          title: 'Spa en duo',
          description: 'Relaxation et bien-être pour deux',
          category: 'wellness',
          imageUrl: 'https://example.com/spa.jpg',
          priceCents: 12000,
          location: 'Paris',
          city: 'Paris',
          rating: 4.8,
          reviewCount: 124,
          isKosher: true,
          durationMinutes: 120,
          tags: ['relaxation', 'massage', 'sauna'],
        ),
        CoupleActivity(
          id: 2,
          title: 'Cours de cuisine',
          description: 'Apprenez à cuisiner ensemble',
          category: 'gastronomy',
          imageUrl: 'https://example.com/cooking.jpg',
          priceCents: 8500,
          location: 'Lyon',
          city: 'Lyon',
          rating: 4.5,
          isKosher: true,
          durationMinutes: 180,
          tags: ['cuisine', 'atelier'],
        ),
        CoupleActivity(
          id: 3,
          title: 'Visite musée',
          description: 'Découvrez l\'art ensemble',
          category: 'culture',
          priceCents: 0,
          location: 'Paris',
          rating: 4.2,
        ),
        CoupleActivity(
          id: 4,
          title: 'Cours de danse',
          description: 'Apprenez la salsa en couple',
          category: 'sport',
          priceCents: 4500,
          location: 'Marseille',
          durationMinutes: 90,
        ),
        CoupleActivity(
          id: 5,
          title: 'Weekend romantique',
          description: 'Escapade en amoureux',
          category: 'travel',
          priceCents: 25000,
          location: 'Nice',
        ),
      ];

  static CoupleActivity get singleActivity => activities.first;

  static List<CoupleActivity> get savedActivities => [
        activities[0].copyWith(savedAt: DateTime.now()),
        activities[1].copyWith(savedAt: DateTime.now().subtract(const Duration(days: 1))),
      ];

  // ============ COUPLE EVENTS ============

  static List<CoupleEvent> get events => [
        CoupleEvent(
          id: 1,
          title: 'Dîner Shabbat Couples',
          description: 'Soirée exclusive pour couples',
          category: 'dinner',
          imageUrl: 'https://example.com/shabbat.jpg',
          eventDate: DateTime.now().add(const Duration(days: 7)),
          eventTime: '19:00',
          location: 'Paris',
          address: '123 Rue de Rivoli',
          city: 'Paris',
          priceCents: 7500,
          maxCouples: 20,
          currentCouples: 12,
          isKosher: true,
          dressCode: 'Chic décontracté',
          organizerName: 'MAZL Events',
          isFeatured: true,
        ),
        CoupleEvent(
          id: 2,
          title: 'Brunch dominical',
          description: 'Brunch casher pour couples',
          category: 'brunch',
          eventDate: DateTime.now().add(const Duration(days: 3)),
          eventTime: '11:00',
          location: 'Paris',
          priceCents: 4500,
          maxCouples: 30,
          currentCouples: 8,
          isKosher: true,
        ),
        CoupleEvent(
          id: 3,
          title: 'Soirée jeux',
          description: 'Jeux de société entre couples',
          category: 'game',
          eventDate: DateTime.now().add(const Duration(days: 14)),
          eventTime: '20:00',
          location: 'Lyon',
          priceCents: 0,
          maxCouples: 15,
          currentCouples: 5,
        ),
      ];

  static CoupleEvent get singleEvent => events.first;

  static List<CoupleEvent> get registeredEvents => [
        events[0].copyWith(
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
          registrationStatus: 'registered',
        ),
      ];

  // ============ COUPLE DATA ============

  static CoupleData get coupleData => CoupleData(
        partnerId: 42,
        partnerName: 'Sarah',
        partnerPicture: 'https://example.com/sarah.jpg',
        relationshipStartDate: DateTime.now().subtract(const Duration(days: 100)),
        metOnMazlDate: DateTime.now().subtract(const Duration(days: 120)),
        status: RelationshipStatus.inRelationship,
        daysTogetherStreak: 30,
      );

  // ============ DATES ============

  static List<Map<String, dynamic>> get dates => [
        {
          'id': 1,
          'title': 'Notre anniversaire',
          'date': '2024-06-15',
          'type': 'anniversary',
          'is_recurring': true,
          'remind_days_before': 7,
        },
        {
          'id': 2,
          'title': 'Premier rendez-vous',
          'date': '2024-01-20',
          'type': 'memory',
          'is_recurring': true,
          'remind_days_before': 3,
        },
      ];

  // ============ BUCKET LIST ============

  static List<Map<String, dynamic>> get bucketList => [
        {
          'id': 1,
          'title': 'Voir les aurores boréales',
          'description': 'Voyage en Norvège ou Islande',
          'category': 'travel',
          'is_completed': false,
        },
        {
          'id': 2,
          'title': 'Apprendre à danser',
          'description': 'Cours de salsa ensemble',
          'category': 'experience',
          'is_completed': true,
          'completed_at': '2024-03-15',
        },
      ];

  // ============ MEMORIES ============

  static List<Map<String, dynamic>> get memories => [
        {
          'id': 1,
          'type': 'note',
          'title': 'Notre premier rendez-vous',
          'content': 'On s\'est rencontrés au café...',
          'memory_date': '2024-01-15',
          'created_at': '2024-02-01',
        },
        {
          'id': 2,
          'type': 'photo',
          'title': 'Vacances à Nice',
          'image_url': 'https://example.com/nice.jpg',
          'memory_date': '2024-07-20',
          'location': 'Nice',
          'created_at': '2024-07-21',
        },
      ];

  // ============ STATS ============

  static Map<String, dynamic> get stats => {
        'stats': {
          'days_together': 100,
          'activities_done': 15,
          'events_attended': 5,
          'memories_count': 25,
          'bucket_list_completed': 3,
        },
        'achievements': [
          {'id': 'first_week', 'title': 'Première semaine', 'achieved': true},
          {'id': 'first_month', 'title': 'Premier mois', 'achieved': true},
          {'id': 'three_months', 'title': 'Trimestre', 'achieved': true},
        ],
      };
}

// Extension to copy CoupleActivity with new values
extension CoupleActivityCopy on CoupleActivity {
  CoupleActivity copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    DateTime? savedAt,
    String? userNotes,
  }) {
    return CoupleActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory,
      imageUrl: imageUrl,
      priceCents: priceCents,
      location: location,
      address: address,
      city: city,
      rating: rating,
      reviewCount: reviewCount,
      isKosher: isKosher,
      isPartner: isPartner,
      partnerName: partnerName,
      discountPercent: discountPercent,
      discountCode: discountCode,
      bookingUrl: bookingUrl,
      phone: phone,
      website: website,
      durationMinutes: durationMinutes,
      tags: tags,
      savedAt: savedAt ?? this.savedAt,
      userNotes: userNotes ?? this.userNotes,
    );
  }
}

// Extension to copy CoupleEvent with new values
extension CoupleEventCopy on CoupleEvent {
  CoupleEvent copyWith({
    int? id,
    String? title,
    DateTime? registeredAt,
    String? registrationStatus,
  }) {
    return CoupleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description,
      category: category,
      imageUrl: imageUrl,
      eventDate: eventDate,
      eventTime: eventTime,
      endTime: endTime,
      location: location,
      address: address,
      city: city,
      priceCents: priceCents,
      maxCouples: maxCouples,
      currentCouples: currentCouples,
      isKosher: isKosher,
      dressCode: dressCode,
      whatIncluded: whatIncluded,
      organizerName: organizerName,
      isFeatured: isFeatured,
      registeredAt: registeredAt ?? this.registeredAt,
      registrationStatus: registrationStatus ?? this.registrationStatus,
    );
  }
}
