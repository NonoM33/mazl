import 'couple_guard.dart';
import 'profile_guard.dart';
import 'route_names.dart';

/// Routes an unauthenticated visitor may open.
const _publicRoutes = [
  RoutePaths.splash,
  RoutePaths.onboarding,
  RoutePaths.login,
  RoutePaths.reviewLogin,
];

/// The router's single redirect, free of any screen so it can be tested.
///
/// 0. the iPhone Duo tutorial opens for anyone, signed in or not: it runs at
///    the very first launch, before the rest of the journey;
/// 1. the splash routes by itself;
/// 2. a visitor who is not signed in only gets the public routes, and lands on
///    the onboarding; a member whose session the app just ended
///    ([sessionEnded]) lands on the login instead;
/// 3. a signed-in member whose profile lacks gender / looking-for goes to the
///    profile setup, from any protected route;
/// 4. one navigation at a time: dating or couple, never both.
String? appRedirect({
  required String location,
  required bool isAuthenticated,
  required bool profileIncomplete,
  required bool inCouple,
  bool sessionEnded = false,
}) {
  if (location == RoutePaths.splash || location == RoutePaths.duoTutorial) {
    return null;
  }

  if (!isAuthenticated) {
    if (sessionEnded) {
      return location == RoutePaths.login || location == RoutePaths.reviewLogin
          ? null
          : RoutePaths.login;
    }
    return _publicRoutes.contains(location) ? null : RoutePaths.onboarding;
  }

  final setup = profileSetupRedirect(
    location: location,
    profileIncomplete: profileIncomplete,
  );
  if (setup != null) return setup;

  return coupleRedirect(location: location, inCouple: inCouple);
}
