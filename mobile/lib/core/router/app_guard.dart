import 'couple_guard.dart';
import 'profile_guard.dart';
import 'route_names.dart';

/// Routes an unauthenticated visitor may open.
const _publicRoutes = [
  RoutePaths.splash,
  RoutePaths.onboarding,
  RoutePaths.login,
];

/// The router's single redirect, free of any screen so it can be tested.
///
/// 1. the splash routes by itself;
/// 2. a visitor who is not signed in only gets the public routes;
/// 3. a signed-in member whose profile lacks gender / looking-for goes to the
///    profile setup, from any protected route;
/// 4. one navigation at a time: dating or couple, never both.
String? appRedirect({
  required String location,
  required bool isAuthenticated,
  required bool profileIncomplete,
  required bool inCouple,
}) {
  if (location == RoutePaths.splash) return null;

  if (!isAuthenticated) {
    return _publicRoutes.contains(location) ? null : RoutePaths.onboarding;
  }

  final setup = profileSetupRedirect(
    location: location,
    profileIncomplete: profileIncomplete,
  );
  if (setup != null) return setup;

  return coupleRedirect(location: location, inCouple: inCouple);
}
