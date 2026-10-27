import 'package:flutter/foundation.dart';

/// The city a mazl+ member chose to discover instead of their own
/// (`passport` of `GET /api/premium/settings`).
@immutable
class Passport {
  const Passport({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;

  /// Null when [json] is not a complete passport.
  static Passport? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final city = json['city'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (city is! String || city.trim().isEmpty) return null;
    if (latitude is! num || longitude is! num) return null;
    return Passport(
      city: city,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  /// The body of `PUT /api/discover/passport`.
  Map<String, Object> toJson() => {
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is Passport &&
      other.city == city &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(city, latitude, longitude);
}

/// What the server says about the member's mazl+ settings. The app shows
/// these values and never guesses them: an unreadable answer is an error, not
/// « off ».
@immutable
class PremiumSettings {
  const PremiumSettings({
    required this.isPlus,
    required this.passport,
    required this.incognito,
    required this.sendReadReceipts,
  });

  final bool isPlus;
  final Passport? passport;
  final bool incognito;
  final bool sendReadReceipts;

  /// The `data` of `GET /api/premium/settings`; null when it is malformed.
  static PremiumSettings? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final isPlus = json['is_plus'];
    final incognito = json['incognito'];
    final receipts = json['send_read_receipts'];
    if (isPlus is! bool || incognito is! bool || receipts is! bool) return null;
    final rawPassport = json['passport'];
    final passport = Passport.tryParse(rawPassport);
    // A passport that is present but unreadable is not « no passport ».
    if (rawPassport != null && passport == null) return null;
    return PremiumSettings(
      isPlus: isPlus,
      passport: passport,
      incognito: incognito,
      sendReadReceipts: receipts,
    );
  }

  PremiumSettings copyWith({
    Passport? passport,
    bool clearPassport = false,
    bool? incognito,
    bool? sendReadReceipts,
  }) => PremiumSettings(
    isPlus: isPlus,
    passport: clearPassport ? null : (passport ?? this.passport),
    incognito: incognito ?? this.incognito,
    sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
  );
}
