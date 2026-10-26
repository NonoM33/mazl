import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';

import '../../helpers/l10n_helpers.dart';

const _locales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

/// App Store review (docs/launch/REVIEW-LOGIN-CONTRAT.md): a plain link under
/// the Apple and Google buttons, visible to everyone (rule 2.3.1: no hidden
/// gesture), opens the identifier + password sign-in.
void main() {
  setUpAll(loadAppFonts);

  for (final locale in _locales) {
    group('the review link, ${locale.languageCode}', () {
      for (final showApple in [true, false]) {
        testWidgets('is on the screen (Apple: $showApple), under Google', (
          tester,
        ) async {
          await pumpLocalized(
            tester,
            LoginScreen(showApple: showApple),
            locale: locale,
          );
          final l10n = lookupAppLocalizations(locale);
          final link = find.widgetWithText(
            TextButton,
            l10n.authLoginReviewLink,
          );
          expect(link, findsOneWidget);
          expect(
            link.hitTestable(),
            findsOneWidget,
            reason: 'visible, not hidden',
          );
          final google = find.widgetWithText(
            OutlinedButton,
            l10n.authLoginGoogle,
          );
          expect(
            tester.getTopLeft(link).dy,
            greaterThan(tester.getBottomLeft(google).dy),
          );
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  testWidgets('the link is a real 44 x 44 pt target', (tester) async {
    await pumpLocalized(tester, const LoginScreen(showApple: true));
    final size = tester.getSize(
      find.widgetWithText(
        TextButton,
        lookupAppLocalizations(kTestLocale).authLoginReviewLink,
      ),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('tapping it opens /login/review on top of the login', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.login,
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (_, __) => const LoginScreen(showApple: true),
        ),
        GoRoute(
          path: RoutePaths.reviewLogin,
          builder: (_, __) => const Scaffold(body: Text('review-screen')),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = kSmallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(lookupAppLocalizations(kTestLocale).authLoginReviewLink),
    );
    await tester.pumpAndSettle();
    expect(find.text('review-screen'), findsOneWidget);
    expect(
      router.canPop(),
      isTrue,
      reason: 'pushed: back returns to the login',
    );
  });
}
