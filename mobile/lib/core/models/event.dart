import '_json_parsing.dart';

/// Event model
class Event {
  final int id;
  final String title;
  final String? description;
  final String? eventType;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime date;
  final String? time;
  final String? endTime;
  final double price;
  final String currency;
  final int? maxAttendees;
  final int attendeeCount;
  final String? imageUrl;
  final bool isPublished;
  final String? userRsvpStatus;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.eventType,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.date,
    this.time,
    this.endTime,
    this.price = 0,
    this.currency = 'EUR',
    this.maxAttendees,
    this.attendeeCount = 0,
    this.imageUrl,
    this.isPublished = false,
    this.userRsvpStatus,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: parseIntSafe(json['id']) ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      latitude: parseDoubleSafe(json['latitude']),
      longitude: parseDoubleSafe(json['longitude']),
      date: DateTime.parse(json['date']),
      time: json['time'] as String?,
      endTime: json['end_time'] as String?,
      price: parseDoubleSafe(json['price']) ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      maxAttendees: parseIntSafe(json['max_attendees']),
      attendeeCount: parseIntSafe(json['attendee_count']) ?? 0,
      imageUrl: json['image_url'] as String?,
      isPublished: json['is_published'] == true,
      userRsvpStatus: json['user_rsvp_status'] as String?,
    );
  }

  String get formattedPrice {
    if (price == 0) return 'Gratuit';
    return '${price.toStringAsFixed(0)} $currency';
  }

  String get spotsLeft {
    if (maxAttendees == null) return 'Places illimitées';
    final left = maxAttendees! - attendeeCount;
    if (left <= 0) return 'Complet';
    return '$left places restantes';
  }
}
