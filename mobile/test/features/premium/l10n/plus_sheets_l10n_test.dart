import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_l10n_harness.dart';

const _frenchSheet = [
  'Vos likes du jour sont partis.',
  'Prochains likes dans',
  'Attendre minuit',
  'Pas maintenant',
  'Découvrir mazl+',
];

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
  });

  final now = DateTime(2026, 10, 23, 23, 59, 30);

  testWidgets('the daily limit sheet in English', (tester) async {
    await pumpPlus(
      tester,
      Scaffold(body: DailyLimitSheet(freeLikesPerDay: 10, now: () => now)),
      locale: const Locale('en'),
    );
    expect(find.text('DAILY LIMIT · 10 / 10'), findsOneWidget);
    expect(find.text('Your likes for today are gone.'), findsOneWidget);
    expect(find.text('Next likes in'), findsOneWidget);
    expect(find.text('00:00:30'), findsOneWidget);
    expect(find.text('Discover mazl+'), findsOneWidget);
    expect(find.text('Wait until midnight'), findsOneWidget);
  });

  testWidgets('the daily limit sheet stays French word for word', (
    tester,
  ) async {
    await pumpPlus(
      tester,
      Scaffold(body: DailyLimitSheet(freeLikesPerDay: 10, now: () => now)),
    );
    expect(find.text('LIMITE DU JOUR · 10 / 10'), findsOneWidget);
    expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
    expect(
      find.text(
        'Ils reviennent à minuit. Ou continuez sans compter, et voyez qui vous a déjà aimé.',
      ),
      findsOneWidget,
    );
    expect(find.text('Découvrir mazl+'), findsOneWidget);
    expect(find.text('Attendre minuit'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('the daily limit sheet in ${c.name}', (tester) async {
      await pumpPlus(
        tester,
        Scaffold(body: DailyLimitSheet(freeLikesPerDay: 10, now: () => now)),
        locale: c.locale,
        brightness: c.brightness,
      );
      expectNoFrench(_frenchSheet);
      expect(find.text('00:00:30'), findsOneWidget);
      expectDirection(tester, find.byType(DailyLimitSheet), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the feature sheet of every feature in ${c.name}', (
      tester,
    ) async {
      final seen = <String>{};
      for (final feature in PremiumFeature.values) {
        await pumpPlus(
          tester,
          Scaffold(body: PremiumFeatureSheet(feature: feature)),
          locale: c.locale,
          brightness: c.brightness,
        );
        expectNoFrench(_frenchSheet);
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
        // Label, title, description, button, dismiss: all different texts.
        expect(
          texts.toSet().length,
          greaterThanOrEqualTo(5),
          reason: '$feature',
        );
        seen.add(texts[1]);
        expect(tester.takeException(), isNull, reason: '$feature ${c.name}');
      }
      expect(
        seen.length,
        PremiumFeature.values.length,
        reason: 'one title each',
      );
    });
  }

  testWidgets('the feature sheet in English', (tester) async {
    await pumpPlus(
      tester,
      const Scaffold(body: PremiumFeatureSheet(feature: PremiumFeature.seeWhoLikesYou)),
      locale: const Locale('en'),
    );
    expect(find.text('RESERVED FOR MAZL+'), findsOneWidget);
    expect(find.text('See who liked you'), findsOneWidget);
    expect(
      find.text('See who liked you before you even cross paths.'),
      findsOneWidget,
    );
    expect(find.text('Discover mazl+'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('the feature sheet stays French word for word', (tester) async {
    await pumpPlus(
      tester,
      const Scaffold(
        body: PremiumFeatureSheet(feature: PremiumFeature.superLikes),
      ),
    );
    expect(find.text('RÉSERVÉ À MAZL+'), findsOneWidget);
    expect(find.text('Super Likes'), findsOneWidget);
    expect(
      find.text('Faites-vous remarquer avec 5 Super Likes par jour.'),
      findsOneWidget,
    );
  });

  group('the brand « mazl+ » inside a sentence', () {
    TextSpan spansOf(WidgetTester tester) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(PlusCtaButton),
          matching: find.byType(Text),
        ),
      );
      return text.textSpan! as TextSpan;
    }

    List<String?> pieces(TextSpan root) => [
      root.text,
      ...?root.children?.cast<TextSpan>().map((s) => s.text),
    ];

    testWidgets('English: « Discover » then mazl then the accent plus', (
      tester,
    ) async {
      await pumpPlus(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => PlusCtaButton(
              label: context.l10n.plusDiscover,
              onPressed: () {},
            ),
          ),
        ),
        locale: const Locale('en'),
      );
      expect(
        pieces(spansOf(tester)).whereType<String>().where((s) => s.isNotEmpty),
        ['Discover ', 'mazl', '+'],
      );
    });

    testWidgets('Hebrew keeps the left-to-right mark glued after the plus', (
      tester,
    ) async {
      await pumpPlus(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => PlusCtaButton(
              label: context.l10n.plusDiscover,
              onPressed: () {},
            ),
          ),
        ),
        locale: const Locale('he'),
      );
      expect(
        pieces(spansOf(tester)).whereType<String>().where((s) => s.isNotEmpty),
        ['לגלות את ', 'mazl', '+', '‎'],
      );
    });

    testWidgets('the screen reader reads the whole sentence', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPlus(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => PlusCtaButton(
              label: context.l10n.plusDiscover,
              onPressed: () {},
            ),
          ),
        ),
        locale: const Locale('es'),
      );
      expect(find.bySemanticsLabel('Descubrir mazl+'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('the logo « mazl+ » is a logo: it never reads right to left', () {
    for (final locale in const [Locale('he'), Locale('en')]) {
      testWidgets(
        'the plus is on the right of mazl in ${locale.languageCode}',
        (tester) async {
          await pumpPlus(
            tester,
            const Scaffold(body: Center(child: PlusWord(size: 72))),
            locale: locale,
          );
          final paragraph = find.descendant(
            of: find.byType(PlusWord),
            matching: find.byType(RichText),
          );
          expect(textDirectionAt(tester, paragraph), TextDirection.ltr);
          final mazl = glyphBoxes(tester, paragraph, 0, 4).first;
          final plus = glyphBoxes(tester, paragraph, 4, 5).first;
          expect(plus.left, greaterThanOrEqualTo(mazl.right - 0.5));
        },
      );
    }
  });

  testWidgets('« Découvrir mazl+ » still opens the offer in English', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => PremiumGate.showDailyLimitSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.premium,
          builder: (_, _) => const Scaffold(body: Text('offer page')),
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover mazl+'));
    await tester.pumpAndSettle();
    expect(find.text('offer page'), findsOneWidget);
  });
}
