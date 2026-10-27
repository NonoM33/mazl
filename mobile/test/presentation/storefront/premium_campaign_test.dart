import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/storefront/storefront_models.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';

import '../../helpers/l10n_helpers.dart';
import 'storefront_fixtures.dart';

// The mazl+ page with what the server says: order, hidden plans, hooks,
// featuring, and the campaign template. The prices are the fallback plans
// (the store has no product here): 19,99 / 44,99 / 69,99 / 99,99 EUR.

const _3m = 'com.mazl.app.plus.3m';
const _12m = 'com.mazl.app.plus.12m';

Future<List<Uri>> _pump(
  WidgetTester tester, {
  Storefront? storefront,
  Locale locale = const Locale('fr'),
  ThemeData? theme,
  AssetBundle? bundle,
  Size size = const Size(390, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final opened = <Uri>[];
  await tester.pumpWidget(
    MaterialApp(
      theme:
          theme ?? AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: PremiumScreen(
        loadPlans: () async => const [],
        storefront: storefront,
        assetBundle: bundle ?? GlyphBundle({'heart'}),
        openUrl: (uri) async => opened.add(uri),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return opened;
}

/// The label of the purchase button (the one that is not the campaign's).
String _buyLabel(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ElevatedButton && w.key != const ValueKey('campaign-cta'),
        ),
        matching: find.byType(Text),
      ),
    )
    .data!;

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  setUpAll(loadAppFonts);

  group('without a campaign', () {
    testWidgets('the page is the one it always was', (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('campaign-hero')), findsNothing);
      expect(find.text('1 mois'), findsOneWidget);
      expect(_buyLabel(tester), contains('44'), reason: '3 months by default');
    });

    testWidgets('an empty storefront changes nothing', (tester) async {
      await _pump(tester, storefront: Storefront.empty);
      expect(_buyLabel(tester), contains('44'));
      expect(_top(tester, '1 mois'), lessThan(_top(tester, '12 mois')));
    });
  });

  group('the plans as the server arranges them', () {
    Storefront arranged() => Storefront.tryParse({
      'success': true,
      'data': {
        'products': [
          {
            'productId': _12m,
            'visible': true,
            'sortOrder': 0,
            'featured': true,
            'highlight': 'Le plus choisi',
          },
          {
            'productId': _3m,
            'visible': true,
            'sortOrder': 1,
            'featured': false,
            'highlight': null,
          },
          {
            'productId': 'com.mazl.app.plus.1m',
            'visible': false,
            'sortOrder': 2,
            'featured': false,
            'highlight': null,
          },
        ],
        'campaign': null,
        'appIcon': null,
        'nextChangeAt': null,
      },
    })!;

    testWidgets('order, hidden plan and hook', (tester) async {
      await _pump(tester, storefront: arranged());
      expect(find.text('1 mois'), findsNothing, reason: 'hidden by the server');
      expect(_top(tester, '12 mois'), lessThan(_top(tester, '3 mois')));
      expect(
        _top(tester, '3 mois'),
        lessThan(_top(tester, '6 mois')),
        reason: 'a plan the server does not list comes after the listed ones',
      );
      expect(find.text('Le plus choisi'), findsOneWidget);
    });

    testWidgets('the featured plan is the one ticked at first', (tester) async {
      await _pump(tester, storefront: arranged());
      expect(_buyLabel(tester), contains('99'));
    });

    testWidgets('the member keeps his choice when the server speaks again', (
      tester,
    ) async {
      await _pump(tester, storefront: arranged());
      await tester.tap(find.text('3 mois'));
      await tester.pump();
      expect(_buyLabel(tester), contains('44'));
      final screen = tester.widget<PremiumScreen>(find.byType(PremiumScreen));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: PremiumScreen(
            loadPlans: screen.loadPlans,
            storefront: Storefront.empty,
          ),
        ),
      );
      await tester.pump();
      expect(_buyLabel(tester), contains('44'));
    });

    testWidgets('a server that hides everything hides nothing', (tester) async {
      final all = Storefront.tryParse({
        'success': true,
        'data': {
          'products': [
            for (final id in [
              'com.mazl.app.plus.1m',
              _3m,
              'com.mazl.app.plus.6m',
              _12m,
            ])
              {'productId': id, 'visible': false},
          ],
        },
      })!;
      await _pump(tester, storefront: all);
      expect(find.text('3 mois'), findsOneWidget);
    });
  });

  group('a campaign', () {
    testWidgets('title, subtitle, last day, badge and button', (tester) async {
      await _pump(tester, storefront: storefrontWithCampaign('valentine'));
      expect(find.byKey(const ValueKey('campaign-hero')), findsOneWidget);
      expect(find.text('La Saint-Valentin approche'), findsOneWidget);
      expect(
        find.text('Offrez-vous mazl+ avec 30 % de réduction.'),
        findsOneWidget,
      );
      // endsAt is 15 February 00:00: the last day is the 14th.
      expect(find.text("Jusqu'au 14 février 2099"), findsOneWidget);
      expect(find.text('Profiter de -30 %'), findsOneWidget);
    });

    testWidgets('the badge is on the targeted plan only', (tester) async {
      await _pump(tester, storefront: storefrontWithCampaign('valentine'));
      expect(find.text('-30 %'), findsOneWidget);
      final badge = tester.getCenter(find.text('-30 %')).dy;
      final row = tester.getRect(
        find.ancestor(of: find.text('3 mois'), matching: find.byType(InkWell)),
      );
      expect(row.top < badge && badge < row.bottom, isTrue);
    });

    testWidgets('the button opens the offer code page with the exact code', (
      tester,
    ) async {
      final opened = await _pump(
        tester,
        storefront: storefrontWithCampaign('valentine'),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('campaign-cta')));
      await tester.tap(find.byKey(const ValueKey('campaign-cta')));
      await tester.pump();
      expect(opened.map((u) => u.toString()), [
        'https://apps.apple.com/redeem?ctx=offercodes&id=6758543555'
            '&code=VALENTIN27',
      ]);
    });

    testWidgets('the code of the chosen plan wins over the first code', (
      tester,
    ) async {
      final opened = await _pump(
        tester,
        storefront: storefrontWithCampaign(
          'valentine',
          targets: [
            {
              'productId': _3m,
              'discountPercent': 30,
              'iosOfferCode': 'TROISMOIS',
            },
            {
              'productId': _12m,
              'discountPercent': 20,
              'iosOfferCode': 'DOUZEMOIS',
            },
          ],
        ),
      );
      await tester.tap(find.text('12 mois'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('campaign-cta')));
      await tester.pump();
      expect(opened.single.queryParameters['code'], 'DOUZEMOIS');
      expect(opened.single.queryParameters['id'], '6758543555');
      expect(opened.single.queryParameters['ctx'], 'offercodes');
    });

    testWidgets('without an Apple code the button is the ordinary purchase', (
      tester,
    ) async {
      final opened = await _pump(
        tester,
        storefront: storefrontWithCampaign(
          'valentine',
          targets: [
            {'productId': _3m, 'discountPercent': 30},
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('campaign-cta')));
      await tester.pump();
      expect(opened, isEmpty);
      // The fallback plans have no store product: the page says so.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('no button text from the server: the default one', (
      tester,
    ) async {
      await _pump(
        tester,
        storefront: storefrontWithCampaign('valentine', cta: ''),
      );
      expect(find.text("Profiter de l'offre"), findsOneWidget);
    });

    for (final code in ['fr', 'en', 'he', 'es', 'ru']) {
      testWidgets('the last day is said in $code', (tester) async {
        await _pump(
          tester,
          storefront: storefrontWithCampaign('valentine'),
          locale: Locale(code),
        );
        final l10n = lookupAppLocalizations(Locale(code));
        final until = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '').contains('2099') &&
              (w.data ?? '').contains('14'),
        );
        expect(until, findsOneWidget);
        expect(l10n.storefrontDiscountBadge(30), contains('30'));
        expect(find.text(l10n.storefrontDiscountBadge(30)), findsOneWidget);
      });
    }

    testWidgets('the drawing of the theme is read from the bundle', (
      tester,
    ) async {
      final bundle = GlyphBundle({'heart'});
      await _pump(
        tester,
        storefront: storefrontWithCampaign('valentine'),
        bundle: bundle,
      );
      expect(bundle.asked, contains('assets/storefront/glyphs/heart.svg'));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsNothing);
    });

    testWidgets('a drawing missing from the bundle gives a plain sparkle, '
        'not a broken page', (tester) async {
      await _pump(
        tester,
        storefront: storefrontWithCampaign('valentine'),
        bundle: GlyphBundle({}),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      expect(find.text('La Saint-Valentin approche'), findsOneWidget);
    });

    testWidgets('dark: the page holds and the ink of black Friday shows', (
      tester,
    ) async {
      await _pump(
        tester,
        storefront: storefrontWithCampaign('black_friday'),
        theme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.iOS),
        bundle: GlyphBundle({'bolt'}),
      );
      expect(tester.takeException(), isNull);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('campaign-cta')),
      );
      final fill = button.style!.backgroundColor!.resolve({})!;
      expect(
        fill.computeLuminance(),
        greaterThan(0.1),
        reason: 'ink on a dark page would be invisible',
      );
    });

    testWidgets('the campaign button fills the width and is 44 pt tall', (
      tester,
    ) async {
      await _pump(tester, storefront: storefrontWithCampaign('valentine'));
      expect(
        tester.getSize(find.byKey(const ValueKey('campaign-cta'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('campaign-cta'))).width,
        greaterThan(290),
        reason: 'the whole width is the button, not just the text',
      );
    });
  });
}
