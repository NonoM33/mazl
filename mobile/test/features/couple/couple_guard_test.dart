import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/couple_guard.dart';

void main() {
  const datingRoutes = [
    '/discover',
    '/discover/profile/12',
    '/matches',
    '/matches/profile/12',
    '/chat',
    '/chat/3',
    '/events',
    '/events/8',
    '/profile',
    '/profile/edit',
    '/profile/settings',
    '/likes',
    '/boost',
    '/filters',
    '/daily-picks',
  ];
  const coupleRoutes = [
    '/couple/activities',
    '/couple/activities/saved',
    '/couple/activities/4',
    '/couple/calendar',
    '/couple/events',
    '/couple/events/2',
    '/couple/space',
    '/couple/space/settings',
    '/couple/mazel-tov',
  ];

  group('en couple', () {
    for (final route in datingRoutes) {
      test('$route -> /couple/activities', () {
        expect(coupleRedirect(location: route, inCouple: true), '/couple/activities');
      });
    }

    for (final route in coupleRoutes) {
      test('$route reste accessible', () {
        expect(coupleRedirect(location: route, inCouple: true), isNull);
      });
    }

    test('l\'écran d\'activation n\'a plus lieu d\'être', () {
      expect(coupleRedirect(location: '/couple/setup', inCouple: true), '/couple/activities');
    });

    test('les écrans communs restent accessibles', () {
      for (final route in ['/premium', '/subscription', '/success-stories', '/verification/identity']) {
        expect(coupleRedirect(location: route, inCouple: true), isNull, reason: route);
      }
    });
  });

  group('hors couple', () {
    for (final route in coupleRoutes) {
      test('$route -> /discover', () {
        expect(coupleRedirect(location: route, inCouple: false), '/discover');
      });
    }

    test('/couple/setup reste accessible', () {
      expect(coupleRedirect(location: '/couple/setup', inCouple: false), isNull);
    });

    for (final route in datingRoutes) {
      test('$route reste accessible', () {
        expect(coupleRedirect(location: route, inCouple: false), isNull);
      });
    }
  });

  test('un préfixe ressemblant n\'est pas pris pour une route de rencontre', () {
    expect(coupleRedirect(location: '/eventsfoo', inCouple: true), isNull);
    expect(coupleRedirect(location: '/couples', inCouple: false), isNull);
  });
}
