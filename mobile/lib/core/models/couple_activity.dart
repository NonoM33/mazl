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
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['image_url'] as String?,
      priceCents: json['price_cents'] as int?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      isKosher: json['is_kosher'] as bool? ?? false,
      isPartner: json['is_partner'] as bool? ?? false,
      partnerName: json['partner_name'] as String?,
      discountPercent: json['discount_percent'] as int?,
      discountCode: json['discount_code'] as String?,
      bookingUrl: json['booking_url'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      savedAt: json['saved_at'] != null ? DateTime.parse(json['saved_at']) : null,
      userNotes: json['user_notes'] as String?,
    );
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
