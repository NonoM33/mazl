import 'route_names.dart';

/// Roots of the dating-mode screens (contract §4.4). In a couple they are not
/// reachable any more.
const _datingRoots = <String>[
  RoutePaths.discover,
  RoutePaths.matches,
  RoutePaths.chat,
  RoutePaths.events,
  RoutePaths.profile,
  RoutePaths.likes,
  RoutePaths.boost,
  RoutePaths.visitors,
  RoutePaths.filters,
  RoutePaths.dailyPicks,
];

bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// Where the router must send [location], or null to let it through.
///
/// - in a couple: dating routes and the activation screen go to
///   `/couple/activities`;
/// - not in a couple: every `/couple/*` route except `/couple/setup` goes to
///   `/discover`.
String? coupleRedirect({required String location, required bool inCouple}) {
  if (inCouple) {
    final isDating = _datingRoots.any((root) => _isUnder(location, root));
    if (isDating || location == RoutePaths.coupleSetup) {
      return RoutePaths.coupleActivities;
    }
    return null;
  }
  if (_isUnder(location, '/couple') && location != RoutePaths.coupleSetup) {
    return RoutePaths.discover;
  }
  return null;
}
