import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/storefront/storefront_models.dart';
import 'package:mazl/core/storefront/storefront_themes.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/storefront/storefront_fixtures.dart';
import 'duo_geometry.dart';

// The mazl+ page with a campaign, on the foldable iPhone (iPhone Duo): every
// theme of the template, in the seven postures, light and dark. The crawl of
// all_screens_duo_test.dart opens two of them through the router; here each
// theme is measured, and what the member does with the button is checked.

const _cta = ValueKey('campaign-cta');

Future<(DuoPoseController, List<Uri>)> _pump(
  WidgetTester tester,
  DuoPose pose,
  Storefront storefront, {
  ThemeData? theme,
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  final opened = <Uri>[];
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: (theme ?? AppTheme.lightTheme).copyWith(
        platform: TargetPlatform.iOS,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: PremiumScreen(
        loadPlans: () async => const [],
        storefront: storefront,
        assetBundle: GlyphBundle({for (final t in kStorefrontThemes) t.glyph}),
        openUrl: (uri) async => opened.add(uri),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await settleFold(tester);
  return (controller, opened);
}

List<String> _problems(WidgetTester tester, DuoPose pose) => [
  ...?tester.takeException() == null ? null : ['an exception was thrown'],
  ...tappableProblems(tester, pose),
  ...foldCrossingProblems(tester, pose),
  ...navigationOutsideColumnProblems(tester, pose),
];

void main() {
  setUpAll(loadAppFonts);

  for (final pose in DuoPose.values) {
    group(pose.name, () {
      for (final theme in kStorefrontThemes) {
        testWidgets('${theme.id}, light', (tester) async {
          await _pump(tester, pose, storefrontWithCampaign(theme.id));
          expect(find.byKey(const ValueKey('campaign-hero')), findsOneWidget);
          expect(_problems(tester, pose), isEmpty);
        });
      }

      for (final id in ['valentine', 'black_friday', 'hanukkah']) {
        testWidgets('$id, dark', (tester) async {
          await _pump(
            tester,
            pose,
            storefrontWithCampaign(id),
            theme: AppTheme.darkTheme,
          );
          expect(_problems(tester, pose), isEmpty);
        });
      }

      testWidgets('no campaign', (tester) async {
        await _pump(tester, pose, Storefront.empty);
        expect(find.byKey(const ValueKey('campaign-hero')), findsNothing);
        expect(_problems(tester, pose), isEmpty);
      });

      testWidgets('the button is a 44 pt target on its whole width, tapped '
          'near its edge', (tester) async {
        final (_, opened) = await _pump(
          tester,
          pose,
          storefrontWithCampaign('valentine'),
        );
        await tester.ensureVisible(find.byKey(_cta));
        await tester.pump();
        final rect = tester.getRect(find.byKey(_cta));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(rect.width, greaterThanOrEqualTo(200));
        // Near the bottom-left corner, far from the label.
        await tester.tapAt(rect.bottomLeft + const Offset(4, -4));
        await tester.pump();
        expect(opened, hasLength(1));
        expect(opened.single.queryParameters['code'], 'VALENTIN27');
      });
    });
  }

  testWidgets('held like a book the campaign is on the reading page, left of '
      'the fold, and the plans are right of it', (tester) async {
    await _pump(
      tester,
      DuoPose.halfOpenBook,
      storefrontWithCampaign('valentine'),
    );
    final fold = DuoPose.halfOpenBook.fold!;
    expect(
      tester.getRect(find.byKey(const ValueKey('campaign-hero'))).right,
      lessThanOrEqualTo(fold.left),
    );
    final l10n = lookupAppLocalizations(const Locale('fr'));
    expect(
      tester.getRect(find.text(l10n.plusMonths(3))).left,
      greaterThanOrEqualTo(fold.right),
    );
  });

  testWidgets('held like a book in Hebrew the campaign is right of the fold', (
    tester,
  ) async {
    await _pump(
      tester,
      DuoPose.halfOpenBook,
      storefrontWithCampaign('valentine'),
      locale: const Locale('he'),
    );
    final fold = DuoPose.halfOpenBook.fold!;
    expect(
      tester.getRect(find.byKey(const ValueKey('campaign-hero'))).left,
      greaterThanOrEqualTo(fold.right),
    );
    expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
  });

  testWidgets('the campaign and the chosen plan survive folding and '
      'unfolding', (tester) async {
    final (pose, _) = await _pump(
      tester,
      DuoPose.openLandscape,
      storefrontWithCampaign('valentine'),
    );
    final l10n = lookupAppLocalizations(const Locale('fr'));
    await tester.tap(find.text(l10n.plusMonths(12)));
    await tester.pump();
    String buyLabel() => tester
        .widget<Text>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is ElevatedButton && w.key != _cta,
            ),
            matching: find.byType(Text),
          ),
        )
        .data!;
    final chosen = buyLabel();
    expect(chosen, contains('99'));
    for (final next in [
      DuoPose.halfOpenBook,
      DuoPose.closed,
      DuoPose.halfOpenLaptop,
      DuoPose.openLandscape,
    ]) {
      await pose.moveTo(tester, next);
      expect(find.text('La Saint-Valentin approche'), findsOneWidget);
      expect(buyLabel(), chosen, reason: 'after ${next.name}');
    }
  });
}
