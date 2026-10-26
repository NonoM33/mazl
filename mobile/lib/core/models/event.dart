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

  /// Whether registrations are open, or the event is announced « Bientôt
  /// disponible » and every registration is refused.
  final EventAvailability availability;

  /// The member asked to be told when this coming soon event opens.
  final bool notifyRequested;

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
    this.availability = EventAvailability.open,
    this.notifyRequested = false,
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
      availability: EventAvailability.fromApi(json['availability']),
      notifyRequested: json['notify_requested'] == true,
    );
  }

  /// The kind of event, normalised from the API's `event_type`.
  EventKind get kind => EventKind.fromApi(eventType);

  /// Registrations are not open yet (« Bientôt disponible »).
  bool get isComingSoon => availability == EventAvailability.comingSoon;

  /// The same event with the member's registration or alert changed.
  Event copyWith({
    int? attendeeCount,
    String? Function()? userRsvpStatus,
    bool? notifyRequested,
  }) => Event(
    id: id,
    title: title,
    description: description,
    eventType: eventType,
    location: location,
    address: address,
    latitude: latitude,
    longitude: longitude,
    date: date,
    time: time,
    endTime: endTime,
    price: price,
    currency: currency,
    maxAttendees: maxAttendees,
    attendeeCount: attendeeCount ?? this.attendeeCount,
    imageUrl: imageUrl,
    isPublished: isPublished,
    userRsvpStatus: userRsvpStatus == null
        ? this.userRsvpStatus
        : userRsvpStatus(),
    availability: availability,
    notifyRequested: notifyRequested ?? this.notifyRequested,
  );
}

/// The API's `availability`. Anything unknown is read as open: the server
/// stays the one that refuses a registration.
enum EventAvailability {
  open('open'),
  comingSoon('coming_soon');

  const EventAvailability(this.apiValue);

  final String apiValue;

  static EventAvailability fromApi(Object? value) => values.firstWhere(
    (availability) => availability.apiValue == value,
    orElse: () => open,
  );
}

/// What an event is. The screens write the kind in the member's language;
/// the core only knows the stable identifiers the API sends.
enum EventKind {
  shabbatDinner('shabbat_dinner'),
  speedDating('speed_dating'),
  holiday('holiday'),
  lecture('lecture'),
  social('social'),
  other('');

  const EventKind(this.apiValue);

  /// The `event_type` the API uses for this kind (also its filter value).
  final String apiValue;

  static EventKind fromApi(String? value) => values.firstWhere(
    (kind) => kind != other && kind.apiValue == value,
    orElse: () => other,
  );
}
