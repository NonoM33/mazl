class CoupleActivity {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final String? imageUrl;
  final int? priceCents;
  final String? location;
  final String? address;
  final String? city;
  final double? rating;
  final int? reviewCount;
  final bool isKosher;
  final bool isPartner;
  final String? partnerName;
  final int? discountPercent;
  final String? discountCode;
  final String? bookingUrl;
  final String? phone;
  final String? website;
  final int? durationMinutes;
  final List<String> tags;
  final DateTime? savedAt;
  final String? userNotes;

  CoupleActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    this.imageUrl,
    this.priceCents,
    this.location,
    this.address,
    this.city,
    this.rating,
    this.reviewCount,
    this.isKosher = false,
    this.isPartner = false,
    this.partnerName,
    this.discountPercent,
    this.discountCode,
    this.bookingUrl,
    this.phone,
    this.website,
    this.durationMinutes,
    this.tags = const [],
    this.savedAt,
    this.userNotes,
  });

  factory CoupleActivity.fromJson(Map<String, dynamic> json) {
    return CoupleActivity(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      subcategory: json['subcategory']?.toString(),
      imageUrl: json['image_url']?.toString(),
      priceCents: _parseInt(json['price_cents']),
      location: json['location']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      isKosher: json['is_kosher'] == true || json['is_kosher'] == 'true',
      isPartner: json['is_partner'] == true || json['is_partner'] == 'true',
      partnerName: json['partner_name']?.toString(),
      discountPercent: _parseInt(json['discount_percent']),
      discountCode: json['discount_code']?.toString(),
      bookingUrl: json['booking_url']?.toString(),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      durationMinutes: _parseInt(json['duration_minutes']),
      tags: _parseTags(json['tags']),
      savedAt: json['saved_at'] != null ? DateTime.tryParse(json['saved_at'].toString()) : null,
      userNotes: json['user_notes']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.isEmpty) return [];
      // Handle comma-separated or JSON-like strings
      if (value.startsWith('[')) {
        try {
          final decoded = value.substring(1, value.length - 1);
          return decoded.split(',').map((e) => e.trim().replaceAll('"', '')).where((e) => e.isNotEmpty).toList();
        } catch (_) {}
      }
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  String get formattedPrice {
    if (priceCents == null || priceCents == 0) return 'Gratuit';
    final euros = priceCents! ~/ 100;
    return '${euros}€';
  }

  String get formattedDuration {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 60) return '${durationMinutes}min';
    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h${mins}min';
  }

  String get categoryEmoji {
    switch (category) {
      case 'wellness':
        return '🧖‍♀️';
      case 'gastronomy':
        return '🍷';
      case 'culture':
        return '🎭';
      case 'sport':
        return '💃';
      case 'travel':
        return '✈️';
      case 'spiritual':
        return '📖';
      case 'diy':
        return '🎨';
      case 'romantic':
        return '💕';
      default:
        return '✨';
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'wellness':
        return 'Bien-être';
      case 'gastronomy':
        return 'Gastronomie';
      case 'culture':
        return 'Culture';
      case 'sport':
        return 'Sport';
      case 'travel':
        return 'Voyage';
      case 'spiritual':
        return 'Spirituel';
      case 'diy':
        return 'DIY';
      case 'romantic':
        return 'Romantique';
      default:
        return category;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'image_url': imageUrl,
      'price_cents': priceCents,
      'location': location,
      'address': address,
      'city': city,
      'rating': rating,
      'review_count': reviewCount,
      'is_kosher': isKosher,
      'is_partner': isPartner,
      'partner_name': partnerName,
      'discount_percent': discountPercent,
      'discount_code': discountCode,
      'booking_url': bookingUrl,
      'phone': phone,
      'website': website,
      'duration_minutes': durationMinutes,
      'tags': tags,
      'saved_at': savedAt?.toIso8601String(),
      'user_notes': userNotes,
    };
  }
}
