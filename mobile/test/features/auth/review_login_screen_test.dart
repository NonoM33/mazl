import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/auth/screens/review_login_screen.dart';

import '../../helpers/l10n_helpers.dart';

const _password = 'exemple-motdepasse';
const _locales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

/// An auth service that answers what the test says, without any network.
class _FakeAuthService extends ChangeNotifier implements AuthService {
  _FakeAuthService(this._answer);

  final Future<AuthResult> Function(String username, String password) _answer;
  final List<({String username, String password})> calls = [];

  @override
  Future<AuthResult> signInWithReviewCredentials(
    String username,
    String password,
  ) {
    calls.add((username: username, password: password));
    return _answer(username, password);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthResult _signedIn() => AuthResult.success(
  AuthUser(
    id: '42',
    email: 'app-review@mazl.app',
    provider: AuthProvider.review,
  ),
);

class _Harness {
  _Harness(this.auth);
  final _FakeAuthService auth;
  late final GoRouter router;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Future<AuthResult> Function(String, String)? answer,
  Locale locale = const Locale('fr'),
}) async {
  final harness = _Harness(
    _FakeAuthService(answer ?? (_, __) async => _signedIn()),
  );
  harness.router = GoRouter(
    initialLocation: RoutePaths.login,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => context.push(RoutePaths.reviewLogin),
                child: const Text('to-review'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.reviewLogin,
        builder: (_, __) => const ReviewLoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.discover,
        builder: (_, __) => const Scaffold(body: Text('discover')),
      ),
    ],
  );
  addTearDown(harness.router.dispose);
  tester.view.physicalSize = kSmallPhone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => harness.auth)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: harness.router,
      ),
    ),
  );
  await tester.tap(find.text('to-review'));
  await tester.pumpAndSettle();
  return harness;
}

Finder get _usernameField => find.byType(TextField).first;
Finder get _passwordField => find.byType(TextField).last;

/// The only full button of the screen (its label is a wheel while it waits).
Finder _submit(AppLocalizations l10n) => find.byType(ElevatedButton);

/// A label on the screen, not what is typed in a field.
Finder _label(String text) =>
    find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(text));

bool _submitEnabled(WidgetTester tester, AppLocalizations l10n) =>
    tester.widget<ElevatedButton>(_submit(l10n)).onPressed != null;

AppLocalizations get _fr => lookupAppLocalizations(const Locale('fr'));

void main() {
  setUpAll(loadAppFonts);

  group('the fields', () {
    testWidgets('the username: no autocorrect, no capital, username hint', (
      tester,
    ) async {
      await _pump(tester);
      final field = tester.widget<TextField>(_usernameField);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autofillHints, [AutofillHints.username]);
      expect(field.obscureText, isFalse);
    });

    testWidgets('the password: hidden, no suggestion, password hint', (
      tester,
    ) async {
      await _pump(tester);
      final field = tester.widget<TextField>(_passwordField);
      expect(field.obscureText, isTrue);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.autofillHints, [AutofillHints.password]);
    });

    testWidgets('the eye shows then hides the password', (tester) async {
      await _pump(tester);
      await tester.enterText(_passwordField, _password);
      await tester.tap(find.byTooltip(_fr.authReviewShowPassword));
      await tester.pump();
      expect(tester.widget<TextField>(_passwordField).obscureText, isFalse);
      await tester.tap(find.byTooltip(_fr.authReviewHidePassword));
      await tester.pump();
      expect(tester.widget<TextField>(_passwordField).obscureText, isTrue);
      expect(_label(_password), findsNothing);
    });

    testWidgets('the fields are labelled in French', (tester) async {
      await _pump(tester);
      expect(find.text(_fr.authReviewUsernameLabel), findsOneWidget);
      expect(find.text(_fr.authReviewPasswordLabel), findsOneWidget);
    });
  });

  group('the button', () {
    testWidgets('is disabled until both fields are filled', (tester) async {
      await _pump(tester);
      expect(_submitEnabled(tester, _fr), isFalse);

      await tester.enterText(_usernameField, 'revue-apple');
      await tester.pump();
      expect(_submitEnabled(tester, _fr), isFalse, reason: 'no password');

      await tester.enterText(_usernameField, '');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      expect(_submitEnabled(tester, _fr), isFalse, reason: 'no username');

      await tester.enterText(_usernameField, 'revue-apple');
      await tester.pump();
      expect(_submitEnabled(tester, _fr), isTrue);
    });

    testWidgets('a username of spaces does not count', (tester) async {
      await _pump(tester);
      await tester.enterText(_usernameField, '   ');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      expect(_submitEnabled(tester, _fr), isFalse);
    });

    testWidgets('sends the trimmed username and the password as typed', (
      tester,
    ) async {
      final harness = await _pump(tester);
      await tester.enterText(_usernameField, '  revue-apple ');
      await tester.enterText(_passwordField, ' $_password');
      await tester.pump();
      await tester.tap(_submit(_fr));
      await tester.pumpAndSettle();
      expect(harness.auth.calls, [
        (username: 'revue-apple', password: ' $_password'),
      ]);
    });

    testWidgets('« done » on the keyboard submits too', (tester) async {
      final harness = await _pump(tester);
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(harness.auth.calls, hasLength(1));
    });

    testWidgets('« done » with a field empty submits nothing', (tester) async {
      final harness = await _pump(tester);
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(harness.auth.calls, isEmpty);
    });

    testWidgets('shows a wheel and refuses a second tap while it waits', (
      tester,
    ) async {
      final pending = Completer<AuthResult>();
      final harness = await _pump(tester, answer: (_, __) => pending.future);
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      await tester.tap(_submit(_fr));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_submitEnabled(tester, _fr), isFalse);
      await tester.tap(_submit(_fr), warnIfMissed: false);
      await tester.pump();
      expect(harness.auth.calls, hasLength(1));

      pending.complete(_signedIn());
      await tester.pumpAndSettle();
      expect(find.text('discover'), findsOneWidget);
    });
  });

  group('the outcome', () {
    testWidgets('a success goes where Apple goes: Discover', (tester) async {
      final harness = await _pump(tester);
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      await tester.tap(_submit(_fr));
      await tester.pumpAndSettle();
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        RoutePaths.discover,
      );
    });

    Future<void> submitRefused(
      WidgetTester tester,
      AuthFailure failure, {
      Locale locale = const Locale('fr'),
    }) async {
      await _pump(
        tester,
        answer: (_, __) async => AuthResult.failure(failure),
        locale: locale,
      );
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      await tester.tap(_submit(lookupAppLocalizations(locale)));
      await tester.pumpAndSettle();
    }

    for (final locale in _locales) {
      testWidgets(
        '401 says the credentials are wrong (${locale.languageCode})',
        (tester) async {
          await submitRefused(
            tester,
            AuthFailure.invalidCredentials,
            locale: locale,
          );
          final l10n = lookupAppLocalizations(locale);
          expect(find.text(l10n.authErrorInvalidCredentials), findsOneWidget);
          expect(find.text(l10n.authErrorGeneric), findsNothing);
        },
      );
    }

    testWidgets('401 keeps the screen, the username and the password', (
      tester,
    ) async {
      await submitRefused(tester, AuthFailure.invalidCredentials);
      expect(find.byType(ReviewLoginScreen), findsOneWidget);
      expect(find.text('revue-apple'), findsOneWidget);
      expect(_submitEnabled(tester, _fr), isTrue);
    });

    testWidgets('the sentence never repeats the password', (tester) async {
      await submitRefused(tester, AuthFailure.invalidCredentials);
      expect(_label(_password), findsNothing);
    });

    testWidgets('429 says there were too many attempts', (tester) async {
      await submitRefused(tester, AuthFailure.rateLimited);
      expect(find.text(_fr.errorRateLimited), findsOneWidget);
    });

    testWidgets('a network error says there is no connection', (tester) async {
      await submitRefused(tester, AuthFailure.network);
      expect(find.text(_fr.errorNetwork), findsOneWidget);
    });

    testWidgets('anything else is the generic sentence', (tester) async {
      await submitRefused(tester, AuthFailure.unknown);
      expect(find.text(_fr.authErrorGeneric), findsOneWidget);
    });

    testWidgets('an exception from the service is the generic sentence', (
      tester,
    ) async {
      await _pump(tester, answer: (_, __) async => throw StateError('boom'));
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      await tester.tap(_submit(_fr));
      await tester.pumpAndSettle();
      expect(find.text(_fr.authErrorGeneric), findsOneWidget);
    });

    testWidgets('the sentence goes away when the member tries again', (
      tester,
    ) async {
      var first = true;
      await _pump(
        tester,
        answer: (_, __) async => first
            ? AuthResult.failure(AuthFailure.invalidCredentials)
            : _signedIn(),
      );
      await tester.enterText(_usernameField, 'revue-apple');
      await tester.enterText(_passwordField, _password);
      await tester.pump();
      await tester.tap(_submit(_fr));
      await tester.pumpAndSettle();
      expect(find.text(_fr.authErrorInvalidCredentials), findsOneWidget);
      first = false;
      await tester.tap(_submit(_fr));
      await tester.pumpAndSettle();
      expect(find.text(_fr.authErrorInvalidCredentials), findsNothing);
    });
  });

  group('the way out', () {
    testWidgets('a back button goes back to the sign-in', (tester) async {
      await _pump(tester);
      expect(find.byTooltip(_fr.commonBack), findsOneWidget);
      await tester.tap(find.byTooltip(_fr.commonBack));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewLoginScreen), findsNothing);
      expect(find.text('to-review'), findsOneWidget);
    });

    testWidgets('opened with nothing behind it, back goes to the login', (
      tester,
    ) async {
      final auth = _FakeAuthService((_, __) async => _signedIn());
      final router = GoRouter(
        initialLocation: RoutePaths.reviewLogin,
        routes: [
          GoRoute(
            path: RoutePaths.reviewLogin,
            builder: (_, __) => const ReviewLoginScreen(),
          ),
          GoRoute(
            path: RoutePaths.login,
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = kSmallPhone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((ref) => auth)],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_fr.commonBack));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });

  group('every language', () {
    for (final locale in _locales) {
      testWidgets(
        '${locale.languageCode}: no overflow, texts from the catalog',
        (tester) async {
          await _pump(tester, locale: locale);
          final l10n = lookupAppLocalizations(locale);
          expect(tester.takeException(), isNull);
          expect(find.text(l10n.authReviewTitle), findsOneWidget);
          expect(find.text(l10n.authReviewIntro), findsOneWidget);
          expect(find.text(l10n.authReviewUsernameLabel), findsOneWidget);
          expect(find.text(l10n.authReviewPasswordLabel), findsOneWidget);
          expect(find.text(l10n.authReviewSubmit), findsOneWidget);
          expect(find.byTooltip(l10n.authReviewShowPassword), findsOneWidget);
          expect(find.byTooltip(l10n.commonBack), findsOneWidget);
        },
      );
    }
  });
}
