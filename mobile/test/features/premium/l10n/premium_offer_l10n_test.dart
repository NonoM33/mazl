import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/subscription_models.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';

import 'premium_l10n_harness.dart';

/// The store has not answered: the offer shows its four default plans.
Future<void> _pumpDefaults(
  WidgetTester tester,
  L10nCase c, {
  TargetPlatform platform = TargetPlatform.iOS,
}) => pumpPlus(
  tester,
  PremiumScreen(loadPlans: () async => const []),
  locale: c.locale,
  brightness: c.brightness,
  platform: platform,
);

const _frenchOffer = [
  'Rencontrez sans compter.',
  'Likes illimités',
  'Voir qui vous a aimé',
  'Un Boost par jour',
  'Filtres avancés',
  'Restaurer',
  'Conditions',
  'Confidentialité',
  '1 mois',
  '3 mois',
  '6 mois',
  '12 mois',
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('English: tagline, perks, durations, prices and legal line', (
    tester,
  ) async {
    await _pumpDefaults(tester, l10nCases.first);
    expect(find.text('mazl+'), findsOneWidget);
    expect(find.text('Meet without counting.'), findsOneWidget);
    expect(find.text('Unlimited likes'), findsOneWidget);
    expect(find.text('5 Super Likes a day'), findsOneWidget);
    expect(find.text('YOUR PLAN'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
    expect(find.text('6 months'), findsOneWidget);
    expect(find.text('12 months'), findsOneWidget);
    // Prices are amounts in euros written the English way.
    expect(find.text('€19.99 per month'), findsOneWidget);
    expect(find.text('€15.00 per month'), findsOneWidget);
    expect(find.text('€11.67 per month'), findsOneWidget);
    expect(find.text('€8.33 per month'), findsOneWidget);
    expect(find.text('€44.99'), findsOneWidget);
    expect(find.text('Continue · €44.99'), findsOneWidget);
    expect(find.text('-25%'), findsOneWidget);
    expect(find.text('-42%'), findsOneWidget);
    expect(find.text('-58%'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(
      find.text(
        'Renews automatically. Cancel anytime in the App Store settings.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Mazl Pro'), findsNothing);
  });

  testWidgets('Android names Google Play in the legal line', (tester) async {
    await _pumpDefaults(
      tester,
      l10nCases.first,
      platform: TargetPlatform.android,
    );
    expect(
      find.text(
        'Renews automatically. Cancel anytime in the Google Play settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Coming soon on Android'), findsOneWidget);
  });

  testWidgets('French keeps the default prices and savings word for word', (
    tester,
  ) async {
    await pumpPlus(tester, PremiumScreen(loadPlans: () async => const []));
    for (final text in [
      '19,99 € par mois',
      '15,00 € par mois',
      '11,67 € par mois',
      '8,33 € par mois',
      '44,99 €',
      'Continuer · 44,99 €',
    ]) {
      expect(findPlain(text), findsOneWidget, reason: text);
    }
    for (final text in ['-25 %', '-42 %', '-58 %']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      find.text(
        'Renouvellement automatique, résiliable à tout moment dans les réglages de l’App Store.',
      ),
      findsOneWidget,
    );
    expect(find.text('VOTRE FORMULE'), findsOneWidget);
  });

  testWidgets('the choice of a plan changes the price of the button', (
    tester,
  ) async {
    await _pumpDefaults(tester, l10nCases.first);
    await tester.ensureVisible(find.text('12 months'));
    await tester.tap(find.text('12 months'));
    await tester.pump();
    expect(find.text('Continue · €99.99'), findsOneWidget);
    await tester.ensureVisible(find.text('1 month'));
    await tester.tap(find.text('1 month'));
    await tester.pump();
    expect(find.text('Continue · €19.99'), findsOneWidget);
  });

  testWidgets(
    'store plans are written in the language, in the store currency',
    (tester) async {
      await pumpPlus(
        tester,
        PremiumScreen(
          loadPlans: () async => [
            storePlan(months: 1, price: 9.99),
            storePlan(months: 3, price: 24.99),
          ],
        ),
        locale: const Locale('en'),
      );
      expect(find.text('\$9.99'), findsOneWidget);
      expect(find.text('\$9.99 per month'), findsOneWidget);
      expect(find.text('\$8.33 per month'), findsOneWidget);
      expect(find.text('-17%'), findsOneWidget);
      expect(find.text('Continue · \$24.99'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
    },
  );

  testWidgets('Russian store plans use the Russian plural of « month »', (
    tester,
  ) async {
    await pumpPlus(
      tester,
      PremiumScreen(
        loadPlans: () async => [
          storePlan(months: 1, price: 9.99, currency: 'EUR'),
          storePlan(months: 3, price: 24.99, currency: 'EUR'),
          storePlan(months: 6, price: 44.99, currency: 'EUR'),
          storePlan(months: 12, price: 79.99, currency: 'EUR'),
        ],
      ),
      locale: const Locale('ru'),
    );
    for (final label in ['1 месяц', '3 месяца', '6 месяцев', '12 месяцев']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('ВАШ ТАРИФ'), findsOneWidget);
  });

  testWidgets('Hebrew durations: « חודש אחד », « 3 חודשים »', (tester) async {
    await _pumpDefaults(tester, const L10nCase(Locale('he'), Brightness.light));
    expect(find.text('חודש אחד'), findsOneWidget);
    expect(find.text('3 חודשים'), findsOneWidget);
    expect(find.text('12 חודשים'), findsOneWidget);
  });

  testWidgets('Spanish durations: « 1 mes », « 3 meses »', (tester) async {
    await _pumpDefaults(tester, const L10nCase(Locale('es'), Brightness.light));
    expect(find.text('1 mes'), findsOneWidget);
    expect(find.text('3 meses'), findsOneWidget);
    expect(find.text('19,99 € al mes'.replaceAll(' €', ' €')), findsOneWidget);
  });

  testWidgets('the plan rows read as one sentence for a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpDefaults(tester, l10nCases.first);
    expect(
      find.bySemanticsLabel('3 months, €44.99, €15.00 per month, saves -25%'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('1 month, €19.99, €19.99 per month'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    semantics.dispose();
  });

  for (final c in l10nCases) {
    testWidgets(
      'the offer in ${c.name}: no French, right direction, no overflow',
      (tester) async {
        await _pumpDefaults(tester, c);
        expectNoFrench(_frenchOffer);
        expectDirection(tester, find.byType(PremiumScreen), c);
        expectDirection(tester, find.byType(PlusWord), c);
        expect(tester.takeException(), isNull);
        // Nothing of the default prices is a hand-written French string.
        expect(find.textContaining(' par mois'), findsNothing);
      },
    );

    testWidgets('the offer scrolls to the legal line in ${c.name}', (
      tester,
    ) async {
      await _pumpDefaults(tester, c);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hebrew: the first plan row lays out right to left', (
    tester,
  ) async {
    await _pumpDefaults(tester, const L10nCase(Locale('he'), Brightness.light));
    final duration = tester.getTopRight(find.text('חודש אחד'));
    final price = tester.getTopLeft(findPlain('19.99 €'));
    // The duration starts on the right, the price ends on the left.
    expect(duration.dx, greaterThan(price.dx));
  });

  testWidgets('Hebrew: the savings pill keeps its minus on the left', (
    tester,
  ) async {
    await _pumpDefaults(tester, const L10nCase(Locale('he'), Brightness.light));
    final pill = tester.widget<Text>(find.textContaining('25%'));
    expect(pill.data, '‎-25%');
  });

  // Make sure the screens still compile against the types they use.
  test('a store plan keeps its price and currency', () {
    final SubscriptionPlan plan = storePlan(months: 3, price: 24.99);
    expect(plan.currencyCode, 'USD');
  });
}
