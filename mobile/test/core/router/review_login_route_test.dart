import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/app_guard.dart';
import 'package:mazl/core/router/route_names.dart';

/// The identifier + password screen of the App Store review must open for
/// someone who is not signed in (that is the whole point of it), also after
/// the app ended a session by itself.
void main() {
  String? redirect(
    String location, {
    bool isAuthenticated = false,
    bool sessionEnded = false,
  }) => appRedirect(
    location: location,
    isAuthenticated: isAuthenticated,
    profileIncomplete: false,
    inCouple: false,
    sessionEnded: sessionEnded,
  );

  test('the route is /login/review, named reviewLogin', () {
    expect(RoutePaths.reviewLogin, '/login/review');
    expect(RouteNames.reviewLogin, 'reviewLogin');
  });

  test('a visitor who is not signed in may open it', () {
    expect(redirect(RoutePaths.reviewLogin), isNull);
  });

  test('after a session ended it is not thrown back to the login', () {
    expect(redirect(RoutePaths.reviewLogin, sessionEnded: true), isNull);
  });

  test('other routes are still protected', () {
    expect(redirect('/login/other'), RoutePaths.onboarding);
    expect(redirect('/discover'), RoutePaths.onboarding);
  });
}
