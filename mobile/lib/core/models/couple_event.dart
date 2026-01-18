class CoupleEvent {
  final int id;
  final String title;
  final String description;
  final String? category;
  final String? imageUrl;
  final DateTime eventDate;
  final String? eventTime;
  final String? endTime;
  final String? location;
  final String? address;
  final String? city;
  final int? priceCents;
  final int? maxCouples;
  final int currentCouples;
  final bool isKosher;
  final String? dressCode;
  final String? whatIncluded;
  final String? organizerName;
  final bool isFeatured;
  final DateTime? registeredAt;
  final String? registrationStatus;

  CoupleEvent({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.imageUrl,
    required this.eventDate,
    this.eventTime,
    this.endTime,
    this.location,
    this.address,
    this.city,
    this.priceCents,
    this.maxCouples,
    this.currentCouples = 0,
    this.isKosher = false,
    this.dressCode,
    this.whatIncluded,
    this.organizerName,
    this.isFeatured = false,
    this.registeredAt,
    this.registrationStatus,
  });

  factory CoupleEvent.fromJson(Map<String, dynamic> json) {
    return CoupleEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      eventDate: DateTime.parse(json['event_date']),
      eventTime: json['event_time'] as String?,
      endTime: json['end_time'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      priceCents: json['price_cents'] as int?,
      maxCouples: json['max_couples'] as int?,
      currentCouples: json['current_couples'] as int? ?? 0,
      isKosher: json['is_kosher'] as bool? ?? false,
      dressCode: json['dress_code'] as String?,
      whatIncluded: json['what_included'] as String?,
      organizerName: json['organizer_name'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      registeredAt: json['registered_at'] != null ? DateTime.parse(json['registered_at']) : null,
      registrationStatus: json['registration_status'] as String?,
    );
  }

  String get formattedPrice {
    if (priceCents == null || priceCents == 0) return 'Gratuit';
    final euros = priceCents! ~/ 100;
    return '${euros}€/couple';
  }

  String get formattedDate {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[eventDate.weekday - 1]} ${eventDate.day} ${months[eventDate.month - 1]}';
  }

  String get formattedTime {
    if (eventTime == null) return '';
    final parts = eventTime!.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}h${parts[1]}';
    }
    return eventTime!;
  }

  int get spotsLeft {
    if (maxCouples == null) return -1; // Unlimited
    return maxCouples! - currentCouples;
  }

  bool get isFull {
    if (maxCouples == null) return false;
    return currentCouples >= maxCouples!;
  }

  String get categoryEmoji {
    switch (category) {
      case 'dinner':
        return '🍽️';
      case 'tasting':
        return '🍷';
      case 'party':
        return '🎉';
      case 'travel':
        return '✈️';
      case 'workshop':
        return '🎨';
      case 'brunch':
        return '🥐';
      case 'spiritual':
        return '✡️';
      case 'concert':
        return '🎵';
      case 'game':
        return '🎮';
      default:
        return '📅';
    }
  }
}
