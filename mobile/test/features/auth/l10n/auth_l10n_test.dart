import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/presentation/features/auth/l10n/auth_failure_text.dart';
import 'package:mazl/presentation/features/auth/l10n/linked_text.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';
import 'package:mazl/presentation/features/auth/screens/route_error_screen.dart';
import 'package:mazl/presentation/features/onboarding/screens/onboarding_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../chat/chat_test_support.dart' show loadChatFonts;

const _en = Locale('en');
const _he = Locale('he');
const _locales = [Locale('fr'), _en, _he, Locale('es'), Locale('ru')];

/// An auth service that answers what the test says, without any network.
class _FakeAuthService extends ChangeNotifier implements AuthService {
  _FakeAuthService({this.result});

  AuthResult? result;

  @override
  Future<AuthResult> signInWithGoogle() async => result!;

  @override
  Future<AuthResult> signInWithApple() async => result!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Override> _auth(AuthResult? result) => [
  authServiceProvider.overrideWith((ref) => _FakeAuthService(result: result)),
];

void main() {
  setUpAll(() async {
    await loadChatFonts();
    await initializeDateFormatting();
  });

  group('the login screen', () {
    testWidgets('in English', (tester) async {
      await pumpLocalized(
        tester,
        const LoginScreen(showApple: true),
        locale: _en,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Continue with Apple'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Continue with Google'),
        findsOneWidget,
      );
      expect(find.text('DATING · JEWISH COMMUNITY'), findsOneWidget);
      expect(
        find.text('Serious dating between people who share your values.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'By continuing, you agree to the Terms and the Privacy Policy.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    for (final locale in [_he, const Locale('ru'), const Locale('es')]) {
      testWidgets(
        '${locale.languageCode}: both legal links stay tappable inside the translated sentence',
        (tester) async {
          var terms = 0;
          var privacy = 0;
          await pumpLocalized(
            tester,
            LoginScreen(
              showApple: true,
              onOpenTerms: () => terms++,
              onOpenPrivacy: () => privacy++,
            ),
            locale: locale,
          );
          final l10n = lookupAppLocalizations(locale);
          final rich = tester.widget<RichText>(
            find.byWidgetPredicate(
              (w) =>
                  w is RichText &&
                  w.text.toPlainText() ==
                      l10n.authLegal(
                        l10n.authLegalTermsLink,
                        l10n.authLegalPrivacyLink,
                      ),
            ),
          );
          final links = <TextSpan>[];
          rich.text.visitChildren((span) {
            if (span is TextSpan && span.recognizer != null) links.add(span);
            return true;
          });
          expect(links.map((s) => s.text), [
            l10n.authLegalTermsLink,
            l10n.authLegalPrivacyLink,
          ]);
          (links.first.recognizer! as dynamic).onTap();
          (links.last.recognizer! as dynamic).onTap();
          expect([terms, privacy], [1, 1]);
        },
      );
    }

    testWidgets(
      'a refused sign-in is told in English, never with the server text',
      (tester) async {
        await pumpLocalized(
          tester,
          const LoginScreen(showApple: false),
          locale: _en,
          overrides: _auth(AuthResult.failure(AuthFailure.network)),
        );
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();
        expect(
          find.text('No connection. Check your network and try again.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a cancelled sign-in has its own sentence', (tester) async {
      await pumpLocalized(
        tester,
        const LoginScreen(showApple: false),
        locale: _en,
        overrides: _auth(AuthResult.failure(AuthFailure.cancelled)),
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Sign-in cancelled.'), findsOneWidget);
    });
  });

  group('the failure sentences', () {
    test('every failure has a sentence in every language', () {
      for (final locale in _locales) {
        final l10n = lookupAppLocalizations(locale);
        for (final failure in [...AuthFailure.values, null]) {
          expect(
            authFailureText(l10n, failure, unknown: 'fallback').trim(),
            isNotEmpty,
          );
        }
      }
    });

    test('an unknown cause uses what the screen says', () {
      expect(
        authFailureText(
          lookupAppLocalizations(_en),
          AuthFailure.unknown,
          unknown: 'fallback',
        ),
        'fallback',
      );
      expect(
        authFailureText(lookupAppLocalizations(_en), null, unknown: 'fallback'),
        'fallback',
      );
    });

    test('links are found inside the sentence, whatever the word order', () {
      const style = TextStyle();
      final spans = spansWithLinks('B first, then A.', [
        (label: 'A', style: style, recognizer: null),
        (label: 'B', style: style, recognizer: null),
      ]);
      expect(spans.map((s) => (s as TextSpan).text), [
        'B',
        ' first, then ',
        'A',
        '.',
      ]);
      expect(
        spansWithLinks('no link here', [
          (label: 'A', style: style, recognizer: null),
        ]).map((s) => (s as TextSpan).text),
        ['no link here'],
      );
    });
  });

  group('onboarding', () {
    testWidgets('in English, page by page', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen(), locale: _en);
      expect(find.text('Welcome to MAZL'), findsOneWidget);
      expect(find.text('01 / 05'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Find your mazal'), findsOneWidget);
      expect(find.text('02 / 05'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Couple mode'), findsOneWidget);
      expect(find.text('Memories and important dates'), findsOneWidget);
      expect(find.text('Shared Jewish calendar'), findsOneWidget);
    });

    testWidgets('the last page offers « Get started »', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen(), locale: _en);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Daily picks'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets(
      'Hebrew: the page counter stays 01 / 05 and « Skip » is at the START',
      (tester) async {
        await pumpLocalized(tester, const OnboardingScreen(), locale: _he);
        // A left-to-right mark keeps « 01 / 05 » from reading « 05 / 01 ».
        expect(find.text('\u200e01 / 05'), findsOneWidget);
        expect(
          textDirectionAt(tester, find.text('\u200e01 / 05')),
          TextDirection.rtl,
        );
        final skip = tester.getCenter(find.text('דילוג'));
        expect(
          skip.dx,
          lessThan(180),
          reason: 'END of the screen is the left in Hebrew',
        );
      },
    );

    testWidgets(
      'the progress bars are read aloud in the language of the member',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpLocalized(tester, const OnboardingScreen(), locale: _en);
        expect(find.bySemanticsLabel('Page 1 of 5'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('no overflow at 360 px, in every language, light and dark', () {
    for (final locale in _locales) {
      for (final brightness in Brightness.values) {
        final label = '${locale.languageCode} ${brightness.name}';
        testWidgets('login $label', (tester) async {
          await pumpLocalized(
            tester,
            const LoginScreen(showApple: true),
            locale: locale,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
        });
        testWidgets('onboarding, every page $label', (tester) async {
          await pumpLocalized(
            tester,
            const OnboardingScreen(),
            locale: locale,
            brightness: brightness,
          );
          for (var i = 0; i < 4; i++) {
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(PageView),
              Offset(locale == _he ? 300 : -300, 0),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
        testWidgets('route error $label', (tester) async {
          await pumpLocalized(
            tester,
            const RouteErrorScreen(),
            locale: locale,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the other screens', () {
    testWidgets('route error, in Hebrew', (tester) async {
      await pumpLocalized(tester, const RouteErrorScreen(), locale: _he);
      expect(find.text('העמוד לא נמצא'), findsOneWidget);
      expect(find.text('חזרה לדף הבית'), findsOneWidget);
    });
  });
}
