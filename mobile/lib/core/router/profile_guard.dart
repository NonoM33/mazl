import 'route_names.dart';

bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// Where the router must send an authenticated member whose profile lacks
/// gender or looking-for, or null to let [location] through.
///
/// Let through: the setup itself, and the settings tree (sign out, delete the
/// account) so nobody is locked inside the setup.
String? profileSetupRedirect({
  required String location,
  required bool profileIncomplete,
}) {
  if (!profileIncomplete) return null;
  if (_isUnder(location, RoutePaths.profileSetup)) return null;
  if (_isUnder(location, RoutePaths.settings)) return null;
  return RoutePaths.profileSetup;
}
