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
  RoutePaths.filters,
  RoutePaths.dailyPicks,
];

/// Where the places of the couple space before the five tabs lead now
/// (docs/couple/ESPACE-COUPLE.md §0.3). Exact paths: the pages opened from
/// them (an activity, an event, the settings) keep their own routes.
const legacyCoupleRedirects = <String, String>{
  RoutePaths.legacyCoupleActivities: RoutePaths.coupleOutings,
  RoutePaths.legacyCoupleCalendar: RoutePaths.coupleAgenda,
  RoutePaths.legacyCoupleEvents: RoutePaths.coupleOutings,
  RoutePaths.legacyCoupleSpace: RoutePaths.coupleUs,
  RoutePaths.legacyCoupleSpaceSettings: RoutePaths.coupleUsSettings,
};

bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// Where the router must send [location], or null to let it through.
///
/// - in a couple: dating routes and the activation screen go to
///   `/couple/today`, and the places the couple space had before its five
///   tabs go to where their content lives now ([legacyCoupleRedirects]);
/// - not in a couple: every `/couple/*` route except `/couple/setup` goes to
///   `/discover`.
String _withoutTrailingSlash(String location) =>
    location.length > 1 && location.endsWith('/')
    ? location.substring(0, location.length - 1)
    : location;

String? coupleRedirect({required String location, required bool inCouple}) {
  if (inCouple) {
    final isDating = _datingRoots.any((root) => _isUnder(location, root));
    if (isDating || location == RoutePaths.coupleSetup) {
      return RoutePaths.coupleToday;
    }
    return legacyCoupleRedirects[_withoutTrailingSlash(location)];
  }
  if (_isUnder(location, '/couple') && location != RoutePaths.coupleSetup) {
    return RoutePaths.discover;
  }
  return null;
}
