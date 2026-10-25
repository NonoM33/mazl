import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/session_end.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';

import '../../helpers/l10n_helpers.dart';

/// V1-CONTRAT §5: the member whose session the app ended comes back to the
/// login screen, which says why.
void main() {
  Future<void> openLogin(
    WidgetTester tester,
    SessionEndReason? reason, {
    Locale locale = kTestLocale,
  }) => pumpLocalized(
    tester,
    const LoginScreen(showApple: true),
    locale: locale,
    overrides: [
      sessionEndReasonReaderProvider.overrideWithValue(() => reason),
    ],
  );

  testWidgets('an expired session is told', (tester) async {
    await openLogin(tester, SessionEndReason.expired);
    expect(find.text('Session expirée. Reconnectez-vous.'), findsOneWidget);
  });

  testWidgets('a disabled account is told, with where to write', (
    tester,
  ) async {
    await openLogin(tester, SessionEndReason.accountDisabled);
    expect(
      find.text('Votre compte est désactivé. Écrivez-nous à hello@mazl.app.'),
      findsOneWidget,
    );
  });

  testWidgets('a visitor, or a member who signed out, sees no notice', (
    tester,
  ) async {
    await openLogin(tester, null);
    expect(find.textContaining('Session expirée'), findsNothing);
    expect(find.textContaining('désactivé'), findsNothing);
  });

  testWidgets('both notices exist in every language', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final reason in SessionEndReason.values) {
        // A new screen each time: the reason is read when the login opens.
        await tester.pumpWidget(const SizedBox());
        await openLogin(tester, reason, locale: locale);
        final text = switch (reason) {
          SessionEndReason.expired => l10n.errorSessionExpired,
          SessionEndReason.accountDisabled => l10n.authErrorAccountDisabled('hello@mazl.app'),
        };
        expect(find.text(text), findsOneWidget, reason: '${locale.languageCode} $reason');
        expect(tester.takeException(), isNull);
      }
    }
  });
}
