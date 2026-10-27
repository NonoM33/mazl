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

  // The five tabs and the pages opened over them.
  const coupleRoutes = [
    '/couple/today',
    '/couple/agenda',
    '/couple/outings',
    '/couple/concierge',
    '/couple/concierge/4',
    '/couple/us',
    '/couple/us/settings',
    '/couple/question',
    '/couple/questions',
    '/couple/checkin',
    '/couple/premium',
    '/couple/activities/saved',
    '/couple/activities/4',
    '/couple/events/2',
    '/couple/mazel-tov',
  ];

  // The places of the couple space before the five tabs.
  const legacyRoutes = {
    '/couple/activities': '/couple/outings',
    '/couple/calendar': '/couple/agenda',
    '/couple/events': '/couple/outings',
    '/couple/space': '/couple/us',
    '/couple/space/settings': '/couple/us/settings',
  };

  group('en couple', () {
    for (final route in datingRoutes) {
      test('$route -> /couple/today', () {
        expect(
          coupleRedirect(location: route, inCouple: true),
          '/couple/today',
        );
      });
    }

    for (final route in coupleRoutes) {
      test('$route reste accessible', () {
        expect(coupleRedirect(location: route, inCouple: true), isNull);
      });
    }

    for (final entry in legacyRoutes.entries) {
      test('l\'ancienne route ${entry.key} -> ${entry.value}', () {
        expect(
          coupleRedirect(location: entry.key, inCouple: true),
          entry.value,
        );
      });

      test('${entry.key}/ (barre finale) mène au même endroit', () {
        expect(
          coupleRedirect(location: '${entry.key}/', inCouple: true),
          entry.value,
        );
      });
    }

    test('une page ouverte depuis une ancienne route garde la sienne', () {
      // « /couple/activities/4 » est une activité, pas l'ancienne liste.
      expect(
        coupleRedirect(location: '/couple/activities/4', inCouple: true),
        isNull,
      );
      expect(
        coupleRedirect(location: '/couple/events/2', inCouple: true),
        isNull,
      );
    });

    test('l\'écran d\'activation n\'a plus lieu d\'être', () {
      expect(
        coupleRedirect(location: '/couple/setup', inCouple: true),
        '/couple/today',
      );
    });

    test('les écrans communs restent accessibles', () {
      for (final route in [
        '/premium',
        '/subscription',
        '/success-stories',
        '/verification/identity',
      ]) {
        expect(
          coupleRedirect(location: route, inCouple: true),
          isNull,
          reason: route,
        );
      }
    });
  });

  group('hors couple', () {
    for (final route in [...coupleRoutes, ...legacyRoutes.keys]) {
      test('$route -> /discover', () {
        expect(
          coupleRedirect(location: route, inCouple: false),
          '/discover',
        );
      });
    }

    test('/couple/setup reste accessible', () {
      expect(
        coupleRedirect(location: '/couple/setup', inCouple: false),
        isNull,
      );
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
