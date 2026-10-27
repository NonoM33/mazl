import 'premium_settings.dart';

/// The cities the Passeport suggests, with the coordinates sent to the
/// server. [serverName] is what the server stores and what other members
/// read in « De passage à X »; the screen shows the name in the member's
/// language (`passportCity*` in the translations).
enum PassportCity {
  telAviv('Tel Aviv', 32.0853, 34.7818),
  jerusalem('Jerusalem', 31.7683, 35.2137),
  newYork('New York', 40.7128, -74.0060),
  london('London', 51.5074, -0.1278),
  montreal('Montreal', 45.5017, -73.5673),
  paris('Paris', 48.8566, 2.3522),
  marseille('Marseille', 43.2965, 5.3698),
  lyon('Lyon', 45.7640, 4.8357),
  nice('Nice', 43.7102, 7.2620);

  const PassportCity(this.serverName, this.latitude, this.longitude);

  final String serverName;
  final double latitude;
  final double longitude;

  Passport get passport =>
      Passport(city: serverName, latitude: latitude, longitude: longitude);

  /// The suggested city the server's [name] stands for, if any.
  static PassportCity? named(String name) {
    final wanted = name.trim().toLowerCase();
    for (final city in values) {
      if (city.serverName.toLowerCase() == wanted) return city;
    }
    return null;
  }
}
