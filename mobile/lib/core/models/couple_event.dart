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
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString(),
      imageUrl: json['image_url']?.toString(),
      eventDate: _parseDate(json['event_date']) ?? DateTime.now(),
      eventTime: json['event_time']?.toString(),
      endTime: json['end_time']?.toString(),
      location: json['location']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      priceCents: _parseInt(json['price_cents']),
      maxCouples: _parseInt(json['max_couples']),
      currentCouples: _parseInt(json['current_couples']) ?? 0,
      isKosher: json['is_kosher'] == true || json['is_kosher'] == 'true',
      dressCode: json['dress_code']?.toString(),
      whatIncluded: json['what_included']?.toString(),
      organizerName: json['organizer_name']?.toString(),
      isFeatured: json['is_featured'] == true || json['is_featured'] == 'true',
      registeredAt: _parseDate(json['registered_at']),
      registrationStatus: json['registration_status']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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
