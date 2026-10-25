import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/app_guard.dart';

/// V1-CONTRAT §5: when the app ends the session itself, the member comes back
/// to the LOGIN screen (a visitor who simply is not signed in lands on the
/// onboarding).
void main() {
  String? redirect(String location, {required bool sessionEnded}) =>
      appRedirect(
        location: location,
        isAuthenticated: false,
        profileIncomplete: false,
        inCouple: false,
        sessionEnded: sessionEnded,
      );

  test('after a session ended, any protected screen goes to the login', () {
    for (final location in ['/discover', '/chat/3', '/profile/settings']) {
      expect(redirect(location, sessionEnded: true), '/login', reason: location);
    }
  });

  test('after a session ended, the onboarding gives way to the login too', () {
    expect(redirect('/onboarding', sessionEnded: true), '/login');
  });

  test('the login itself stays where it is', () {
    expect(redirect('/login', sessionEnded: true), isNull);
  });

  test('without a session ended, nothing changes for a visitor', () {
    expect(redirect('/discover', sessionEnded: false), '/onboarding');
    expect(redirect('/login', sessionEnded: false), isNull);
  });

  test('the splash still routes by itself', () {
    expect(redirect('/', sessionEnded: true), isNull);
  });
}
