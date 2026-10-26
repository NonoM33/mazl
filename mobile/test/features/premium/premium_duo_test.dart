import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_cut.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/screens/plus_welcome_screen.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The mazl+ offer and its welcome page on the foldable iPhone (iPhone Duo)
// held like a book: the promise and what it brings on the page where reading
// starts, the plans and the purchase on the other.

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose,
  Widget home, {
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

Widget _offer() => PremiumScreen(loadPlans: () async => const []);

Widget _welcome() =>
    PlusWelcomeScreen(planMonths: 3, loadLikesCount: () async => 3);

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

void main() {
  setUpAll(loadAppFonts);

  group('offer', () {
    testWidgets('book: promise and perks left of the fold, plans and purchase '
        'right', (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, _offer());
      final fold = DuoPose.halfOpenBook.fold!;
      final l10n = _l10n();
      expect(
        tester.getRect(find.text(l10n.plusOfferTagline)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.text(l10n.plusFeatureUnlimitedLikesTitle)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.text(l10n.plusYourPlan.toUpperCase())).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        tester.getRect(find.text(l10n.plusMonths(3))).left,
        greaterThanOrEqualTo(fold.right),
      );
      final buy = find.byType(ElevatedButton);
      expect(tester.getRect(buy).left, greaterThanOrEqualTo(fold.right));
      expect(buy.hitTestable(), findsOneWidget);
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });

    testWidgets('opened flat sideways: the same two pages, around the middle '
        'of the screen', (tester) async {
      await _pump(tester, DuoPose.openLandscape, _offer());
      // No fold: the room left by the side column (951 - 84) is cut in two
      // with a gutter between the pages.
      const gutter = Rect.fromLTWH(
        (867 - kSpreadGutter) / 2,
        0,
        kSpreadGutter,
        669,
      );
      final l10n = _l10n();
      expect(
        tester.getRect(find.text(l10n.plusOfferTagline)).right,
        lessThanOrEqualTo(gutter.left),
      );
      expect(
        tester.getRect(find.text(l10n.plusMonths(3))).left,
        greaterThanOrEqualTo(gutter.right),
      );
      expect(
        tester.getRect(find.byType(ElevatedButton)).left,
        greaterThanOrEqualTo(gutter.right),
      );
    });

    testWidgets('book in Hebrew: the promise is right of the fold, the '
        'purchase left', (tester) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        _offer(),
        locale: const Locale('he'),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.text(_l10n('he').plusOfferTagline)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        tester.getRect(find.byType(ElevatedButton)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });

    testWidgets('the chosen plan survives folding', (tester) async {
      final pose = await _pump(tester, DuoPose.openLandscape, _offer());
      final l10n = _l10n();
      await tester.tap(find.text(l10n.plusMonths(12)));
      await tester.pump();
      String buyLabel() => tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ElevatedButton),
              matching: find.byType(Text),
            ),
          )
          .data!;
      final chosen = buyLabel();
      expect(chosen, contains('99'));
      await pose.moveTo(tester, DuoPose.halfOpenBook);
      expect(buyLabel(), chosen);
      await pose.moveTo(tester, DuoPose.openLandscape);
      expect(buyLabel(), chosen);
    });

    testWidgets('open portrait: one column, the purchase spans the page', (
      tester,
    ) async {
      await _pump(tester, DuoPose.openPortrait, _offer());
      final l10n = _l10n();
      expect(
        tester.getRect(find.text(l10n.plusMonths(3))).top,
        greaterThan(tester.getRect(find.text(l10n.plusOfferTagline)).bottom),
        reason: 'the plans stay under the perks, in the same column',
      );
      expect(
        tester.getRect(find.byType(ElevatedButton)).width,
        greaterThan(500),
      );
    });
  });

  group('welcome', () {
    testWidgets('book: greeting left of the fold, ways to begin and "later" '
        'right', (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, _welcome());
      final fold = DuoPose.halfOpenBook.fold!;
      final l10n = _l10n();
      expect(
        tester.getRect(find.text(l10n.plusWelcomeSubtitle)).right,
        lessThanOrEqualTo(fold.left),
      );
      for (final title in [
        l10n.plusWelcomeLikesCount(3),
        l10n.plusWelcomeBoostTitle,
        l10n.plusWelcomeFiltersTitle,
        l10n.commonLater,
      ]) {
        expect(
          tester.getRect(find.text(title)).left,
          greaterThanOrEqualTo(fold.right),
          reason: title,
        );
      }
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });

    testWidgets('book in Hebrew: the greeting is right of the fold', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        _welcome(),
        locale: const Locale('he'),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      final l10n = _l10n('he');
      expect(
        tester.getRect(find.text(l10n.plusWelcomeSubtitle)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        tester.getRect(find.text(l10n.plusWelcomeBoostTitle)).right,
        lessThanOrEqualTo(fold.left),
      );
    });

    testWidgets('open portrait: greeting and ways to begin in one column', (
      tester,
    ) async {
      await _pump(tester, DuoPose.openPortrait, _welcome());
      final l10n = _l10n();
      final subtitle = tester.getRect(find.text(l10n.plusWelcomeSubtitle));
      final likes = tester.getRect(find.text(l10n.plusWelcomeLikesCount(3)));
      expect(likes.top, greaterThan(subtitle.bottom));
    });
  });
}
