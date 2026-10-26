import '../../../core/services/api_service.dart';
import '../../../core/services/jewish_calendar_service.dart';

/// Le lieu pour lequel les horaires de Shabbat sont calculés.
class ShabbatPlace {
  const ShabbatPlace({required this.location, required this.isDefault});

  final ShabbatLocation location;

  /// Vrai quand le lieu du membre n'est pas connu : ce sont les horaires de
  /// Paris, et l'écran doit le dire.
  final bool isDefault;
}

/// Le lieu du profil (coordonnées de la ville) ; Paris sans coordonnées ni
/// nom de ville, ou si le profil ne peut pas être lu.
Future<ShabbatPlace> loadShabbatPlace(ApiService api) async {
  final response = await api.getCurrentUser();
  final profile = response.success ? response.data?.profile : null;
  final latitude = profile?.latitude;
  final longitude = profile?.longitude;
  final name = shabbatPlaceName(profile?.location);
  // Des coordonnées sans nom de ville ne peuvent pas être dites au membre :
  // Paris.
  if (latitude == null || longitude == null || name == null) {
    return const ShabbatPlace(location: ShabbatLocation.paris, isDefault: true);
  }
  return ShabbatPlace(
    location: ShabbatLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
    ),
    isDefault: false,
  );
}

/// Le nom de la ville d'un profil, sans son code postal (« Paris 75001 » ->
/// « Paris ») ; null quand le profil n'en a pas.
String? shabbatPlaceName(String? profileLocation) {
  final name = profileLocation?.replaceFirst(RegExp(r'\s+\d{4,6}$'), '').trim();
  return name == null || name.isEmpty ? null : name;
}
