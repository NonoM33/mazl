import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';
import 'package:mazl/presentation/features/onboarding/screens/onboarding_screen.dart';
import '../../helpers/l10n_helpers.dart';

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: kTestLocale, theme: AppTheme.lightTheme, home: home),
    );

/// Parcourt les Container et DecoratedBox montés à la recherche d'un dégradé.
bool _hasLinearGradient(WidgetTester tester) {
  bool isGradient(Decoration? d) => d is BoxDecoration && d.gradient is LinearGradient;
  final containers = tester.widgetList<Container>(find.byType(Container));
  final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  return containers.any((c) => isGradient(c.decoration)) ||
      boxes.any((b) => isGradient(b.decoration));
}

void main() {
  group('écran de connexion Encre & Tekhelet', () {
    testWidgets('propose Apple et Google, pas d\'e-mail (v1)', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(showApple: true)));

      expect(find.widgetWithText(ElevatedButton, 'Continuer avec Apple'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Continuer avec Google'), findsOneWidget);
      expect(find.textContaining('e-mail'), findsNothing);
    });

    testWidgets("n'affiche pas Apple quand la plateforme ne le propose pas", (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(showApple: false)));

      expect(find.text('Continuer avec Apple'), findsNothing);
      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('affiche le mot-symbole, la promesse et la mention légale', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(showApple: true)));

      expect(find.byType(MazlWordmark), findsOneWidget);
      expect(find.text('RENCONTRES · COMMUNAUTÉ JUIVE'), findsOneWidget);
      expect(
        find.text('Des rencontres sérieuses, entre personnes qui partagent vos valeurs.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'En continuant, vous acceptez les Conditions et la Confidentialité.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('les deux liens légaux sont cliquables', (tester) async {
      var terms = 0;
      var privacy = 0;
      await tester.pumpWidget(_app(LoginScreen(
        showApple: true,
        onOpenTerms: () => terms++,
        onOpenPrivacy: () => privacy++,
      )));

      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('En continuant'),
        ),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan) spans.add(span);
        return true;
      });
      TapGestureRecognizer recognizerOf(String word) =>
          spans.firstWhere((s) => s.text == word).recognizer! as TapGestureRecognizer;

      recognizerOf('Conditions').onTap!();
      recognizerOf('Confidentialité').onTap!();

      expect([terms, privacy], [1, 1]);
    });

    testWidgets('tient sans débordement sur 390x844 et sur un petit écran', (tester) async {
      addTearDown(tester.view.reset);
      for (final size in const [Size(390, 844), Size(320, 480)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(_app(const LoginScreen(showApple: true)));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'débordement à $size');
      }
    });

    testWidgets("n'utilise aucun dégradé", (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(showApple: true)));
      expect(_hasLinearGradient(tester), isFalse);
    });
  });

  group('connexion fictive (dev, debug uniquement)', () {
    // Le ProviderScope dispose le singleton AuthService en fin de test : on
    // ne peut donc que fermer la session fictive, pas appeler signOut().
    // A real phone always has local storage; the demo sign-in clears the
    // couple cache in it.
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(DevSession.stop);

    testWidgets('le bouton « Connexion fictive (dev) » est présent et actif', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(showApple: false)));

      final button = find.widgetWithText(TextButton, 'Connexion fictive (dev)');
      expect(button, findsOneWidget);
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    });

    testWidgets('un appui ouvre une session fictive et va à la découverte', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const LoginScreen(showApple: false)),
          GoRoute(
            path: RoutePaths.discover,
            builder: (_, __) => const Scaffold(body: Text('Découverte')),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: kTestLocale, theme: AppTheme.lightTheme, routerConfig: router),
      ));

      await tester.tap(find.widgetWithText(TextButton, 'Connexion fictive (dev)'));
      await tester.pumpAndSettle();

      expect(find.text('Découverte'), findsOneWidget);
      expect(AuthService().isAuthenticated, isTrue);
      expect(DevSession.isActive, isTrue);
    });
  });

  group('onboarding Encre & Tekhelet', () {
    testWidgets('étape « 01 / 05 », Continuer et Passer, sans dégradé', (tester) async {
      await tester.pumpWidget(_app(const OnboardingScreen()));

      expect(find.text('01 / 05'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continuer'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Passer'), findsOneWidget);
      expect(_hasLinearGradient(tester), isFalse);
    });

    testWidgets('Continuer passe à la page suivante', (tester) async {
      await tester.pumpWidget(_app(const OnboardingScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuer'));
      await tester.pumpAndSettle();

      expect(find.text('02 / 05'), findsOneWidget);
    });
  });
}
