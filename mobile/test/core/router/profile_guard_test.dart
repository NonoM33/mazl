import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/app_guard.dart';
import 'package:mazl/core/router/profile_guard.dart';

void main() {
  const protectedRoutes = [
    '/discover',
    '/discover/profile/12',
    '/matches',
    '/chat',
    '/chat/3',
    '/events',
    '/profile',
    '/profile/edit',
    '/likes',
    '/boost',
    '/filters',
    '/premium',
    '/couple/activities',
  ];
  const stayReachable = [
    '/profile/setup',
    '/profile/settings',
    '/profile/settings/shabbat',
    '/profile/settings/shabbat/display',
  ];

  group('profileSetupRedirect, profile incomplete', () {
    for (final route in protectedRoutes) {
      test('$route -> /profile/setup', () {
        expect(
          profileSetupRedirect(location: route, profileIncomplete: true),
          '/profile/setup',
        );
      });
    }

    for (final route in stayReachable) {
      test('$route reste accessible (configuration, déconnexion)', () {
        expect(profileSetupRedirect(location: route, profileIncomplete: true), isNull);
      });
    }
  });

  group('profileSetupRedirect, profile complete or unknown', () {
    for (final route in [...protectedRoutes, ...stayReachable]) {
      test('$route passe', () {
        expect(profileSetupRedirect(location: route, profileIncomplete: false), isNull);
      });
    }
  });

  group('appRedirect', () {
    String? redirect(
      String location, {
      bool authenticated = true,
      bool incomplete = false,
      bool inCouple = false,
    }) =>
        appRedirect(
          location: location,
          isAuthenticated: authenticated,
          profileIncomplete: incomplete,
          inCouple: inCouple,
        );

    test('the splash always routes by itself', () {
      expect(redirect('/', incomplete: true), isNull);
      expect(redirect('/', authenticated: false), isNull);
    });

    test('a visitor who is not signed in is sent to the onboarding', () {
      expect(redirect('/discover', authenticated: false), '/onboarding');
      expect(redirect('/login', authenticated: false), isNull);
      expect(redirect('/onboarding', authenticated: false), isNull);
    });

    test('a signed-in member with a missing gender goes to the setup', () {
      expect(redirect('/discover', incomplete: true), '/profile/setup');
    });

    test('a signed-in member with a complete profile reaches Discover', () {
      expect(redirect('/discover'), isNull);
    });

    test('the profile guard comes before the couple guard', () {
      expect(redirect('/discover', incomplete: true, inCouple: true), '/profile/setup');
      expect(redirect('/discover', inCouple: true), '/couple/activities');
    });
  });
}
