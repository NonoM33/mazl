import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/app_guard.dart';

/// Le tutoriel de l'iPhone Duo s'ouvre au tout premier lancement : avant la
/// connexion, et avant la configuration du profil.
void main() {
  test('ouvert sans être connecté (premier lancement)', () {
    expect(
      appRedirect(
        location: '/duo-tutorial',
        isAuthenticated: false,
        profileIncomplete: false,
        inCouple: false,
      ),
      isNull,
    );
  });

  test(
    'ouvert avec un profil à compléter, sans être renvoyé à la configuration',
    () {
      expect(
        appRedirect(
          location: '/duo-tutorial',
          isAuthenticated: true,
          profileIncomplete: true,
          inCouple: false,
        ),
        isNull,
      );
    },
  );

  test('ouvert en couple (depuis les Réglages)', () {
    expect(
      appRedirect(
        location: '/duo-tutorial',
        isAuthenticated: true,
        profileIncomplete: false,
        inCouple: true,
      ),
      isNull,
    );
  });

  test('une autre route protégée reste protégée', () {
    expect(
      appRedirect(
        location: '/discover',
        isAuthenticated: false,
        profileIncomplete: false,
        inCouple: false,
      ),
      '/onboarding',
    );
  });
}
