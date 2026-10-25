import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/presentation/features/auth/l10n/auth_failure_text.dart';
import 'package:mazl/presentation/features/auth/l10n/linked_text.dart';
import 'package:mazl/presentation/features/auth/screens/email_auth_screen.dart';
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
  Future<AuthResult> signInWithEmail(String email, String password) async =>
      result!;

  @override
  Future<AuthResult> registerWithEmail(
    String email,
    String password,
    String name,
  ) async => result!;

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async => result!;

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
      expect(find.widgetWithText(TextButton, 'Use my email'), findsOneWidget);
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

  group('the e-mail screen', () {
    testWidgets('in English: login mode, then validation and sign-up mode', (
      tester,
    ) async {
      await pumpLocalized(tester, const EmailAuthScreen(), locale: _en);
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsNWidgets(2));
      expect(find.text('Good to see you again'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Email required'), findsOneWidget);
      expect(find.text('Password required'), findsOneWidget);

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Create your MAZL account'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(
        find.text('I accept the Terms of Use and the Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('a wrong password is told in the language of the member', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const EmailAuthScreen(),
        locale: _en,
        overrides: _auth(AuthResult.failure(AuthFailure.invalidCredentials)),
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'jeanne@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password1');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect email or password'), findsOneWidget);
    });

    testWidgets('sign-up refused because the address is taken', (tester) async {
      await pumpLocalized(
        tester,
        const EmailAuthScreen(isLogin: false),
        locale: _en,
        overrides: _auth(AuthResult.failure(AuthFailure.emailTaken)),
        size: const Size(360, 1100),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jeanne');
      await tester.enterText(fields.at(1), 'jeanne@example.com');
      await tester.enterText(fields.at(2), 'Password1');
      await tester.enterText(fields.at(3), 'Password1');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Create my account'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('This email address is already in use.'),
        findsOneWidget,
      );
    });

    testWidgets('sign-up without the terms box asks for them', (tester) async {
      await pumpLocalized(
        tester,
        const EmailAuthScreen(isLogin: false),
        locale: _en,
        size: const Size(360, 1100),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jeanne');
      await tester.enterText(fields.at(1), 'jeanne@example.com');
      await tester.enterText(fields.at(2), 'Password1');
      await tester.enterText(fields.at(3), 'Password1');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Create my account'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Please accept the terms of use'), findsOneWidget);
    });

    testWidgets('the password strength reads in the language of the member', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const EmailAuthScreen(isLogin: false),
        locale: _en,
        size: const Size(360, 1100),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'abc');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), 'Abcdefghijk1!');
      await tester.pump();
      expect(find.text('Excellent'), findsOneWidget);
    });

    testWidgets('the forgot-password dialog, in English', (tester) async {
      await pumpLocalized(
        tester,
        const EmailAuthScreen(),
        locale: _en,
        overrides: _auth(AuthResult(success: true)),
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password'), findsOneWidget);
      expect(
        find.text('Enter your email to receive a reset link.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'jeanne@example.com',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Reset email sent'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Hebrew: right to left, the back arrow is on the START side', (
      tester,
    ) async {
      await pumpLocalized(tester, const EmailAuthScreen(), locale: _he);
      await tester.pumpAndSettle();
      expect(
        textDirectionAt(tester, find.text('התחברות').first),
        TextDirection.rtl,
      );
      final back = tester.getCenter(find.byTooltip('חזרה'));
      expect(
        back.dx,
        greaterThan(180),
        reason: 'the back button sits at the right in Hebrew',
      );
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
      expect(find.text('Daily questions'), findsOneWidget);
      expect(find.text('Shared Jewish calendar'), findsOneWidget);
    });

    testWidgets('the last page offers « Get started »', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen(), locale: _en);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('AI Shadchan'), findsOneWidget);
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
        testWidgets('e-mail, sign-up $label', (tester) async {
          await pumpLocalized(
            tester,
            const EmailAuthScreen(isLogin: false),
            locale: locale,
            brightness: brightness,
          );
          await tester.enterText(
            find.byType(TextFormField).at(2),
            'Abcdefghijk1!',
          );
          await tester.pump();
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pumpAndSettle();
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
