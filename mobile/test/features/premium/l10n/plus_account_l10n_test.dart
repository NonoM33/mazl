import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/premium/screens/plus_welcome_screen.dart';
import 'package:mazl/presentation/features/premium/screens/subscription_screen.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_settings_card.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_l10n_harness.dart';

final _active = SubscriptionSnapshot(
  isActive: true,
  planMonths: 6,
  price: '59.99',
  renewalDate: DateTime(2027, 3, 12),
  superLikesLeft: 4,
  superLikesMax: 5,
  boostAvailable: true,
);

final _cancelled = SubscriptionSnapshot(
  isActive: true,
  planMonths: 12,
  renewalDate: DateTime(2027, 1, 1),
  willRenew: false,
  superLikesLeft: 0,
  superLikesMax: 5,
  boostAvailable: false,
);

const _frenchWelcome = [
  'Tout est déverrouillé. Par où commencer ?',
  'Lancer votre Boost',
  'Affiner vos filtres',
  'Plus tard',
  'Les voir maintenant',
];

const _frenchSubscription = [
  'Aucun abonnement actif.',
  'Restaurer mes achats',
  'Gérer dans l’App Store',
  'Illimités',
  'Utilisé aujourd’hui',
];

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
  });

  group('welcome', () {
    Future<void> pumpWelcome(
      WidgetTester tester,
      L10nCase c, {
      int? months = 6,
      int? likes = 12,
    }) => pumpPlus(
      tester,
      PlusWelcomeScreen(planMonths: months, loadLikesCount: () async => likes),
      locale: c.locale,
      brightness: c.brightness,
    );

    testWidgets('English', (tester) async {
      await pumpWelcome(tester, l10nCases.first);
      expect(find.text('ACTIVE SUBSCRIPTION · 6 MONTHS'), findsOneWidget);
      expect(find.text('Welcome to mazl+.'), findsOneWidget);
      expect(
        find.text('Everything is unlocked. Where do you want to start?'),
        findsOneWidget,
      );
      expect(find.text('12 people liked you'), findsOneWidget);
      expect(find.text('See them now'), findsOneWidget);
      expect(find.text('Start your Boost'), findsOneWidget);
      expect(find.text('Fine-tune your filters'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('one like is singular, an unknown count has its own title', (
      tester,
    ) async {
      await pumpWelcome(tester, l10nCases.first, likes: 1);
      expect(find.text('1 person liked you'), findsOneWidget);
      await pumpWelcome(tester, l10nCases.first, likes: null, months: null);
      expect(find.text('See who liked you'), findsOneWidget);
      expect(find.text('ACTIVE SUBSCRIPTION'), findsOneWidget);
    });

    testWidgets('French stays word for word', (tester) async {
      await pumpWelcome(tester, const L10nCase(Locale('fr'), Brightness.light));
      expect(find.text('ABONNEMENT ACTIF · 6 MOIS'), findsOneWidget);
      expect(find.text('Bienvenue dans mazl+.'), findsOneWidget);
      expect(find.text('12 personnes vous ont aimé'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
    });

    testWidgets('Russian picks the plural form from the count', (tester) async {
      const ru = L10nCase(Locale('ru'), Brightness.light);
      await pumpWelcome(tester, ru, likes: 1);
      expect(find.text('1 человек поставил Вам лайк'), findsOneWidget);
      await pumpWelcome(tester, ru, likes: 3);
      expect(find.text('3 человека поставили Вам лайк'), findsOneWidget);
      await pumpWelcome(tester, ru, likes: 12);
      expect(find.text('12 человек поставили Вам лайк'), findsOneWidget);
    });

    testWidgets('Hebrew picks one, two and many', (tester) async {
      const he = L10nCase(Locale('he'), Brightness.light);
      await pumpWelcome(tester, he, likes: 1);
      expect(find.text('אדם אחד אהב אותך'), findsOneWidget);
      await pumpWelcome(tester, he, likes: 2);
      expect(find.text('שני אנשים אהבו אותך'), findsOneWidget);
      await pumpWelcome(tester, he, likes: 12);
      expect(find.text('12 אנשים אהבו אותך'), findsOneWidget);
    });

    testWidgets('the title keeps the brand and its plus together in Hebrew', (
      tester,
    ) async {
      await pumpWelcome(tester, const L10nCase(Locale('he'), Brightness.light));
      final title = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text && (w.textSpan?.toPlainText() ?? '').contains('mazl'),
        ),
      );
      final root = title.textSpan! as TextSpan;
      final pieces = [
        root.text,
        ...?root.children?.cast<TextSpan>().map((s) => s.text),
      ];
      expect(pieces.whereType<String>().where((s) => s.isNotEmpty), [
        'ברוכים הבאים ל-',
        'mazl',
        '+',
        '‎.',
      ]);
    });

    for (final c in l10nCases) {
      testWidgets('in ${c.name}', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpWelcome(tester, c);
        expectNoFrench(_frenchWelcome);
        expectDirection(tester, find.byType(PlusWelcomeScreen), c);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }

    testWidgets('« Plus tard » and the likes row still navigate', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: RoutePaths.plusWelcome,
        routes: [
          GoRoute(
            path: RoutePaths.plusWelcome,
            builder: (_, _) => PlusWelcomeScreen(
              planMonths: 6,
              loadLikesCount: () async => 12,
            ),
          ),
          GoRoute(
            path: RoutePaths.likes,
            builder: (_, _) => const Scaffold(body: Text('likes page')),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = kSmallPhone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('12 people liked you'));
      await tester.pumpAndSettle();
      expect(find.text('likes page'), findsOneWidget);
    });
  });

  group('subscription', () {
    Future<void> pumpSubscription(
      WidgetTester tester,
      L10nCase c,
      SubscriptionSnapshot snapshot, {
      TargetPlatform platform = TargetPlatform.iOS,
    }) => pumpPlus(
      tester,
      SubscriptionScreen(snapshot: snapshot, onManage: () {}),
      locale: c.locale,
      brightness: c.brightness,
      platform: platform,
    );

    testWidgets('English: card, plan, date, today', (tester) async {
      await pumpSubscription(tester, l10nCases.first, _active);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text('6 months · 59.99'), findsOneWidget);
      expect(find.text('RENEWAL'), findsOneWidget);
      expect(find.text('March 12, 2027'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('4 of 5'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
      expect(find.text('Manage in the App Store'), findsOneWidget);
      expect(find.text('Restore my purchases'), findsOneWidget);
    });

    testWidgets('Android manages the subscription in Google Play', (
      tester,
    ) async {
      await pumpSubscription(
        tester,
        l10nCases.first,
        _active,
        platform: TargetPlatform.android,
      );
      expect(find.text('Manage in Google Play'), findsOneWidget);
    });

    testWidgets('a cancelled subscription says Expiration and the plan alone', (
      tester,
    ) async {
      await pumpSubscription(tester, l10nCases.first, _cancelled);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('EXPIRATION'), findsOneWidget);
      expect(find.text('RENEWAL'), findsNothing);
      expect(find.text('12 months'), findsOneWidget);
      expect(find.text('January 1, 2027'), findsOneWidget);
      expect(find.text('Used today'), findsOneWidget);
      expect(find.text('0 of 5'), findsOneWidget);
    });

    testWidgets('French keeps the first of the month as « 1er »', (
      tester,
    ) async {
      await pumpSubscription(
        tester,
        const L10nCase(Locale('fr'), Brightness.light),
        _cancelled,
      );
      expect(find.text('1er janvier 2027'), findsOneWidget);
      expect(find.text('12 mois'), findsOneWidget);
    });

    testWidgets('French writes the 12th of March as before', (tester) async {
      await pumpSubscription(
        tester,
        const L10nCase(Locale('fr'), Brightness.light),
        _active,
      );
      expect(find.text('12 mars 2027'), findsOneWidget);
      expect(find.text('6 mois · 59.99'), findsOneWidget);
      expect(find.text('4 sur 5'), findsOneWidget);
    });

    testWidgets('dates follow the language', (tester) async {
      await pumpSubscription(
        tester,
        const L10nCase(Locale('es'), Brightness.light),
        _active,
      );
      expect(find.text('12 de marzo de 2027'), findsOneWidget);
      await pumpSubscription(
        tester,
        const L10nCase(Locale('ru'), Brightness.light),
        _active,
      );
      expect(find.text('12 марта 2027\u202Fг.'), findsOneWidget);
      await pumpSubscription(
        tester,
        const L10nCase(Locale('he'), Brightness.light),
        _active,
      );
      expect(find.text('12 במרץ 2027'), findsOneWidget);
    });

    testWidgets('no subscription: the sentence and the way to the offer', (
      tester,
    ) async {
      await pumpSubscription(
        tester,
        l10nCases.first,
        const SubscriptionSnapshot(isActive: false),
      );
      expect(find.text('No active subscription.'), findsOneWidget);
      expect(find.text('Discover mazl+'), findsOneWidget);
      expect(find.textContaining('Manage in'), findsNothing);
    });

    for (final c in l10nCases) {
      testWidgets('active in ${c.name}', (tester) async {
        await pumpSubscription(tester, c, _active);
        expectNoFrench(_frenchSubscription);
        expectDirection(tester, find.byType(SubscriptionScreen), c);
        expect(tester.takeException(), isNull);
      });

      testWidgets('cancelled in ${c.name}', (tester) async {
        await pumpSubscription(tester, c, _cancelled);
        expectNoFrench(_frenchSubscription);
        expect(tester.takeException(), isNull);
      });

      testWidgets('without subscription in ${c.name}', (tester) async {
        await pumpSubscription(
          tester,
          c,
          const SubscriptionSnapshot(isActive: false),
        );
        expectNoFrench(_frenchSubscription);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Hebrew: the back chevron points right, the card reads RTL', (
      tester,
    ) async {
      await pumpSubscription(
        tester,
        const L10nCase(Locale('he'), Brightness.light),
        _active,
      );
      final back = tester.widget<Icon>(
        find.descendant(
          of: find.byType(RoundIconButton),
          matching: find.byType(Icon),
        ),
      );
      expect(back.icon, LucideIcons.chevronRight);
    });
  });

  group('settings card', () {
    Future<void> pumpCard(
      WidgetTester tester,
      L10nCase c, {
      required bool premium,
      String? detail,
    }) => pumpPlus(
      tester,
      Scaffold(
        body: PlusSettingsCard(
          isPremium: premium,
          detail: detail,
          onTap: () {},
        ),
      ),
      locale: c.locale,
      brightness: c.brightness,
    );

    testWidgets('English, free member', (tester) async {
      await pumpCard(tester, l10nCases.first, premium: false);
      expect(find.text('Upgrade to mazl+'), findsOneWidget);
      expect(
        find.text('Unlimited likes, see who liked you, Boost'),
        findsOneWidget,
      );
    });

    testWidgets('English, subscriber without detail', (tester) async {
      await pumpCard(tester, l10nCases.first, premium: true);
      expect(find.text('mazl+'), findsOneWidget);
      expect(find.text('Active subscription'), findsOneWidget);
    });

    testWidgets('French stays word for word', (tester) async {
      await pumpCard(
        tester,
        const L10nCase(Locale('fr'), Brightness.light),
        premium: false,
      );
      expect(find.text('Passer à mazl+'), findsOneWidget);
      expect(
        find.text('Likes illimités, voir qui vous a aimé, Boost'),
        findsOneWidget,
      );
    });

    testWidgets('the screen reader reads the whole line', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, l10nCases.first, premium: false);
      expect(
        find.bySemanticsLabel(
          'Upgrade to mazl+. Unlimited likes, see who liked you, Boost',
        ),
        findsOneWidget,
      );
      await pumpCard(
        tester,
        l10nCases.first,
        premium: true,
        detail: '6 months · renews on March 12, 2027',
      );
      expect(
        find.bySemanticsLabel('mazl+. 6 months · renews on March 12, 2027'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    for (final c in l10nCases) {
      testWidgets('free and subscriber in ${c.name}', (tester) async {
        await pumpCard(tester, c, premium: false);
        expectNoFrench([
          'Passer à mazl+',
          'Likes illimités, voir qui vous a aimé, Boost',
        ]);
        expectDirection(tester, find.byType(PlusSettingsCard), c);
        await pumpCard(tester, c, premium: true);
        expectNoFrench(['Abonnement actif']);
        expect(find.byType(PlusWord), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'Hebrew: the chevron points left, the plus stays on the right',
      (tester) async {
        await pumpCard(
          tester,
          const L10nCase(Locale('he'), Brightness.light),
          premium: true,
        );
        final paragraph = find.descendant(
          of: find.byType(PlusWord),
          matching: find.byType(RichText),
        );
        final mazl = glyphBoxes(tester, paragraph, 0, 4).first;
        final plus = glyphBoxes(tester, paragraph, 4, 5).first;
        expect(plus.left, greaterThanOrEqualTo(mazl.right - 0.5));
      },
    );
  });
}
