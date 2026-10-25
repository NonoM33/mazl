import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// The sign-in screen on the foldable iPhone (iPhone Duo), in the six postures:
// the brand and the tagline are read away from the fold, the sign-in buttons
// and the legal links are in the lower half (laptop) or on the other side of
// the fold (book), and nothing is cut in a short window.

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: duoAppBuilder(controller),
        home: const ContentMaxWidth(child: LoginScreen(showApple: true)),
      ),
    ),
  );
  await settleFold(tester);
  return controller;
}

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

/// The legal sentence under the buttons.
Finder _legal(AppLocalizations l10n) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText() ==
          l10n.authLegal(l10n.authLegalTermsLink, l10n.authLegalPrivacyLink),
);

void _expectWithinSafeArea(WidgetTester tester, DuoPose pose, Finder finder) {
  expect(finder, findsOneWidget, reason: pose.name);
  final rect = tester.getRect(finder);
  expect(
    pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
        pose.safeRect.inflate(0.5).contains(rect.bottomRight),
    isTrue,
    reason: '${pose.name}: $rect leaves ${pose.safeRect}',
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final pose in DuoPose.values) {
    testWidgets('${pose.name}: fits, both sign-in buttons are whole', (
      tester,
    ) async {
      await _pump(tester, pose);
      final l10n = _l10n();
      expect(find.text(l10n.authLoginTagline), findsOneWidget);
      expectFitsDuoPose(tester, pose, 'sign-in');
      for (final button in [
        find.byType(ElevatedButton),
        find.byType(OutlinedButton),
      ]) {
        expect(button.hitTestable(), findsOneWidget, reason: pose.name);
        _expectWithinSafeArea(tester, pose, button);
      }
      _expectWithinSafeArea(tester, pose, _legal(l10n));
    });
  }

  testWidgets('laptop: the brand is above the fold, buttons and links below', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.authLoginTagline)).bottom,
      lessThanOrEqualTo(fold.top),
    );
    expect(
      tester.getRect(find.byType(ElevatedButton)).top,
      greaterThanOrEqualTo(fold.bottom),
    );
    expect(
      tester.getRect(find.byType(OutlinedButton)).top,
      greaterThanOrEqualTo(fold.bottom),
    );
    expect(tester.getRect(_legal(l10n)).top, greaterThanOrEqualTo(fold.bottom));
  });

  testWidgets('book: the brand is left of the fold, buttons and links right', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.authLoginTagline)).right,
      lessThanOrEqualTo(fold.left),
    );
    for (final part in [
      find.byType(ElevatedButton),
      find.byType(OutlinedButton),
      _legal(l10n),
    ]) {
      expect(
        tester.getRect(part).left,
        greaterThanOrEqualTo(fold.right),
        reason: part.toString(),
      );
    }
  });

  testWidgets('book in Hebrew: the brand is right of the fold, buttons left', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n('he');
    expect(
      tester.getRect(find.text(l10n.authLoginTagline)).left,
      greaterThanOrEqualTo(fold.right),
    );
    for (final part in [
      find.byType(ElevatedButton),
      find.byType(OutlinedButton),
      _legal(l10n),
    ]) {
      expect(
        tester.getRect(part).right,
        lessThanOrEqualTo(fold.left),
        reason: part.toString(),
      );
    }
    expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'sign-in (he)');
  });

  testWidgets('folding and unfolding keep the screen whole', (tester) async {
    final pose = await _pump(tester, DuoPose.openPortrait);
    final l10n = _l10n();
    for (final next in [
      DuoPose.halfOpenLaptop,
      DuoPose.openPortrait,
      DuoPose.halfOpenBook,
      DuoPose.closed,
      DuoPose.openLandscape,
    ]) {
      await pose.moveTo(tester, next);
      await tester.pumpAndSettle();
      expect(find.text(l10n.authLoginTagline), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expectFitsDuoPose(tester, next, 'sign-in');
    }
  });
}
