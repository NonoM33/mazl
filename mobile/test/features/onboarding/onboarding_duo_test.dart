import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/onboarding/screens/onboarding_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// The first screen of the sign-up path on the foldable iPhone (iPhone Duo):
// the presentation must be right in the six postures (Apple's guidance:
// nothing interactive in the fold or under the status column, text away from
// the curve, buttons in the lower half when set like a laptop and on the
// other side of the fold when held like a book).

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
        home: const ContentMaxWidth(child: OnboardingScreen()),
      ),
    ),
  );
  await settleFold(tester);
  return controller;
}

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

/// The main button, « Continuer »: whole on screen, inside the safe area.
void _expectContinueReachable(WidgetTester tester, DuoPose pose) {
  final button = find.byType(ElevatedButton);
  expect(button, findsOneWidget, reason: pose.name);
  expect(button.hitTestable(), findsOneWidget, reason: pose.name);
  final rect = tester.getRect(button);
  expect(
    pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
        pose.safeRect.inflate(0.5).contains(rect.bottomRight),
    isTrue,
    reason: '${pose.name}: the button $rect leaves ${pose.safeRect}',
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final pose in DuoPose.values) {
    testWidgets('${pose.name}: fits, the main button is whole and reachable', (
      tester,
    ) async {
      await _pump(tester, pose);
      expect(find.text(_l10n().onboardingPage1Title), findsOneWidget);
      expect(find.text(_l10n().commonSkip), findsOneWidget);
      expectFitsDuoPose(tester, pose, 'presentation');
      _expectContinueReachable(tester, pose);
    });
  }

  testWidgets('laptop: the title is above the fold, the buttons below it', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.onboardingPage1Title)).bottom,
      lessThanOrEqualTo(fold.top),
    );
    expect(
      tester.getRect(find.byType(ElevatedButton)).top,
      greaterThanOrEqualTo(fold.bottom),
    );
    expect(
      tester.getRect(find.text(l10n.commonSkip)).top,
      greaterThanOrEqualTo(fold.bottom),
    );
  });

  testWidgets('book: the title is left of the fold, the buttons right of it', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n();
    expect(
      tester.getRect(find.text(l10n.onboardingPage1Title)).right,
      lessThanOrEqualTo(fold.left),
    );
    expect(
      tester.getRect(find.byType(ElevatedButton)).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(
      tester.getRect(find.text(l10n.commonSkip)).left,
      greaterThanOrEqualTo(fold.right),
    );
  });

  testWidgets('book in Hebrew: the title is right of the fold, buttons left', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final fold = DuoPose.halfOpenBook.fold!;
    final l10n = _l10n('he');
    expect(
      tester.getRect(find.text(l10n.onboardingPage1Title)).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(
      tester.getRect(find.byType(ElevatedButton)).right,
      lessThanOrEqualTo(fold.left),
    );
    expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'presentation (he)');
  });

  testWidgets('folding and unfolding keep the page the member reached', (
    tester,
  ) async {
    final pose = await _pump(tester, DuoPose.openPortrait);
    final l10n = _l10n();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }
    expect(find.text(l10n.onboardingPage3Title), findsOneWidget);

    for (final next in [
      DuoPose.halfOpenLaptop,
      DuoPose.openPortrait,
      DuoPose.halfOpenBook,
      DuoPose.closed,
      DuoPose.halfOpenBook,
      DuoPose.openLandscape,
      DuoPose.halfOpenLaptop,
      DuoPose.splitView,
    ]) {
      await pose.moveTo(tester, next);
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.onboardingPage3Title),
        findsOneWidget,
        reason: 'page 3 after ${next.name}',
      );
      expect(find.text(l10n.onboardingPage1Title), findsNothing);
      expectFitsDuoPose(tester, next, 'page 3');
      _expectContinueReachable(tester, next);
    }
  });
}
