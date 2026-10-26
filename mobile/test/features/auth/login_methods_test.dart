import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/dev_login.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';

import '../../helpers/l10n_helpers.dart';

const _locales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

/// The label of every button on the screen, in reading order.
List<String> _buttonLabels(WidgetTester tester) => [
  for (final button in tester.widgetList<ButtonStyleButton>(
    find.bySubtype<ButtonStyleButton>(),
  ))
    tester
        .widgetList<Text>(
          find.descendant(
            of: find.byWidget(button),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .join(),
];

void main() {
  // v1 decision (2026-10-25): the server has no e-mail sign-in route, so the
  // app offers Sign in with Apple (iOS) and Google, and nothing else — except
  // the plain link to the App Store review's identifier + password sign-in
  // (docs/launch/REVIEW-LOGIN-CONTRAT.md).
  for (final locale in _locales) {
    group('login methods, ${locale.languageCode}', () {
      testWidgets('on iOS: Apple and Google, no e-mail form', (tester) async {
        await pumpLocalized(
          tester,
          const LoginScreen(showApple: true),
          locale: locale,
        );
        final l10n = lookupAppLocalizations(locale);
        expect(_buttonLabels(tester), [
          l10n.authLoginApple,
          l10n.authLoginGoogle,
          l10n.authLoginReviewLink,
          if (kDevLoginAvailable) l10n.authLoginDev,
        ]);
      });

      testWidgets('elsewhere: Google alone, no Apple, no e-mail', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const LoginScreen(showApple: false),
          locale: locale,
        );
        final l10n = lookupAppLocalizations(locale);
        expect(_buttonLabels(tester), [
          l10n.authLoginGoogle,
          l10n.authLoginReviewLink,
          if (kDevLoginAvailable) l10n.authLoginDev,
        ]);
      });
    });
  }
}
