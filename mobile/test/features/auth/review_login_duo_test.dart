import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/auth/screens/review_login_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The identifier + password sign-in on the foldable iPhone (iPhone Duo), in
// every pose of the harness: the title is read away from the fold, the fields
// and the button are on the other side of it, a way out is always in view,
// and every button is a real 44 x 44 pt target (tapped near its edge, not at
// the centre of its icon).

const _password = 'exemple-motdepasse';

class _FakeAuthService extends ChangeNotifier implements AuthService {
  final List<String> usernames = [];

  @override
  Future<AuthResult> signInWithReviewCredentials(
    String username,
    String password,
  ) async {
    usernames.add(username);
    return AuthResult.failure(AuthFailure.invalidCredentials);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Screen {
  _Screen(this.pose, this.auth, this.router);
  final DuoPoseController pose;
  final _FakeAuthService auth;
  final GoRouter router;
}

Future<_Screen> _pump(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  final auth = _FakeAuthService();
  final router = GoRouter(
    initialLocation: RoutePaths.login,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.push(RoutePaths.reviewLogin),
              child: const Text('to-review'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.reviewLogin,
        builder: (_, __) => const ReviewLoginScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWith((ref) => auth)],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: router,
        builder: duoAppBuilder(controller),
      ),
    ),
  );
  await settleFold(tester);
  router.push(RoutePaths.reviewLogin);
  await tester.pumpAndSettle();
  await settleFold(tester);
  return _Screen(controller, auth, router);
}

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

Finder get _back => find.byTooltip(_l10n().commonBack);
Finder get _eye => find.byTooltip(_l10n().authReviewShowPassword);
Finder get _submit => find.byType(ElevatedButton);
Finder get _username => find.byType(TextField).first;
Finder get _passwordField => find.byType(TextField).last;

/// The 44 x 44 minimum, measured on the part of the control that reacts.
void _expectRealTarget(WidgetTester tester, Finder finder, String reason) {
  expect(finder, findsOneWidget, reason: reason);
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44), reason: '$reason width');
  expect(size.height, greaterThanOrEqualTo(44), reason: '$reason height');
}

void main() {
  setUpAll(loadAppFonts);

  for (final pose in DuoPose.values) {
    group(pose.name, () {
      testWidgets('fits: nothing under the system, nothing across the fold', (
        tester,
      ) async {
        await _pump(tester, pose);
        expectFitsDuoPose(tester, pose, 'review sign-in');
        expect(tappableProblems(tester, pose), isEmpty);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        final l10n = _l10n();
        for (final text in [
          l10n.authReviewTitle,
          l10n.authReviewIntro,
          l10n.authReviewUsernameLabel,
          l10n.authReviewPasswordLabel,
          l10n.authReviewSubmit,
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
      });

      testWidgets('a way out is in view and the form is whole', (tester) async {
        await _pump(tester, pose);
        for (final finder in [
          _back,
          _username,
          _passwordField,
          _submit,
          _eye,
        ]) {
          expect(finder.hitTestable(), findsOneWidget, reason: '$finder');
          final rect = tester.getRect(finder);
          expect(
            pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
                pose.safeRect.inflate(0.5).contains(rect.bottomRight),
            isTrue,
            reason: '$finder at $rect leaves ${pose.safeRect}',
          );
        }
      });

      testWidgets('every button is a real 44 x 44 pt target', (tester) async {
        await _pump(tester, pose);
        _expectRealTarget(tester, _back, 'back');
        _expectRealTarget(tester, _eye, 'eye');
        _expectRealTarget(tester, _submit, 'sign in');
      });

      testWidgets(
        'the back button reacts near its edge, not only at its centre',
        (tester) async {
          final screen = await _pump(tester, pose);
          final rect = tester.getRect(_back);
          await tester.tapAt(rect.topLeft + const Offset(2, 2));
          await tester.pumpAndSettle();
          expect(find.byType(ReviewLoginScreen), findsNothing);
          expect(screen.router.canPop(), isFalse);
        },
      );

      testWidgets('the eye reacts near its edge', (tester) async {
        await _pump(tester, pose);
        final rect = tester.getRect(_eye);
        await tester.tapAt(rect.bottomRight - const Offset(2, 2));
        await tester.pump();
        expect(tester.widget<TextField>(_passwordField).obscureText, isFalse);
      });

      testWidgets('the button reacts near its edge once the form is filled', (
        tester,
      ) async {
        final screen = await _pump(tester, pose);
        await tester.enterText(_username, 'revue-apple');
        await tester.enterText(_passwordField, _password);
        await tester.pump();
        final rect = tester.getRect(_submit);
        await tester.tapAt(rect.bottomLeft + const Offset(2, -2));
        await tester.pumpAndSettle();
        expect(screen.auth.usernames, ['revue-apple']);
      });
    });
  }

  testWidgets('laptop: the title is above the fold, the form below', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.authReviewTitle)).bottom,
      lessThanOrEqualTo(fold.top),
    );
    expect(
      tester.getRect(find.text(l10n.authReviewIntro)).bottom,
      lessThanOrEqualTo(fold.top),
    );
    for (final part in [_username, _passwordField, _submit]) {
      expect(tester.getRect(part).top, greaterThanOrEqualTo(fold.bottom));
    }
  });

  testWidgets('book: the title is left of the fold, the form right', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.authReviewTitle)).right,
      lessThanOrEqualTo(fold.left),
    );
    for (final part in [_username, _passwordField, _submit]) {
      expect(tester.getRect(part).left, greaterThanOrEqualTo(fold.right));
    }
    // The way out is on the reading side, next to the title.
    expect(tester.getRect(_back).right, lessThanOrEqualTo(fold.left));
  });

  testWidgets('book in Hebrew: mirrored, the form on the left', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n('he');
    expect(
      tester.getRect(find.text(l10n.authReviewTitle)).left,
      greaterThanOrEqualTo(fold.right),
    );
    for (final part in [_username, _passwordField, _submit]) {
      expect(tester.getRect(part).right, lessThanOrEqualTo(fold.left));
    }
    expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'review sign-in (he)');
    expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
  });

  for (final locale in const [
    Locale('en'),
    Locale('he'),
    Locale('es'),
    Locale('ru'),
  ]) {
    testWidgets('${locale.languageCode}: fits the two half-open poses', (
      tester,
    ) async {
      for (final pose in [DuoPose.halfOpenBook, DuoPose.halfOpenLaptop]) {
        await _pump(tester, pose, locale: locale);
        expectFitsDuoPose(
          tester,
          pose,
          'review sign-in ${locale.languageCode}',
        );
        expect(foldCrossingProblems(tester, pose), isEmpty, reason: pose.name);
      }
    });
  }

  testWidgets('folding and unfolding keeps what was typed', (tester) async {
    final screen = await _pump(tester, DuoPose.openPortrait);
    await tester.enterText(_username, 'revue-apple');
    await tester.enterText(_passwordField, _password);
    await tester.tap(_eye);
    await tester.pump();
    for (final next in [
      DuoPose.halfOpenLaptop,
      DuoPose.openPortrait,
      DuoPose.halfOpenBook,
      DuoPose.closed,
      DuoPose.openLandscape,
      DuoPose.tent,
      DuoPose.splitView,
    ]) {
      await screen.pose.moveTo(tester, next);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_username).controller!.text,
        'revue-apple',
        reason: next.name,
      );
      expect(
        tester.widget<TextField>(_passwordField).controller!.text,
        _password,
        reason: next.name,
      );
      expect(
        tester.widget<TextField>(_passwordField).obscureText,
        isFalse,
        reason: '${next.name}: the eye stays as it was left',
      );
      expectFitsDuoPose(tester, next, 'review sign-in');
    }
  });
}
