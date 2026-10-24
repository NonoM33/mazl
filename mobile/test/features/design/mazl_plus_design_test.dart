import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/premium/screens/plus_welcome_screen.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';
import 'package:mazl/presentation/features/premium/screens/subscription_screen.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_settings_card.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/l10n_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  Size size = const Size(390, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: (theme ?? AppTheme.lightTheme).copyWith(
        platform: TargetPlatform.iOS,
      ),
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Aucun dégradé ni ombre dans l'arbre : ni DecoratedBox, ni Ink, ni Material.
void _expectNoGradientNorShadow(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration) {
      expect(
        decoration.gradient,
        isNull,
        reason: 'aucun dégradé dans le design',
      );
      expect(
        decoration.boxShadow,
        anyOf(isNull, isEmpty),
        reason: 'aucune ombre',
      );
    }
  }
  expect(find.byType(ShaderMask), findsNothing);
}

void _expectTouchTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder.first);
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
}

Future<void> _pumpOffer(WidgetTester tester, {ThemeData? theme}) async {
  await _pump(
    tester,
    PremiumScreen(loadPlans: () async => const []),
    theme: theme,
  );
  await tester.pump(const Duration(milliseconds: 50));
}

final _active = SubscriptionSnapshot(
  isActive: true,
  planLabel: '6 mois',
  price: '59,99 €',
  renewalDate: DateTime(2027, 3, 12),
  superLikesLeft: 4,
  superLikesMax: 5,
  boostAvailable: true,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
  });

  group('offre mazl+ (P2)', () {
    testWidgets(
      'affiche le titre, la promesse, les six avantages et les trois formules',
      (tester) async {
        await _pumpOffer(tester);

        expect(find.text('mazl+'), findsOneWidget);
        expect(find.text('Rencontrez sans compter.'), findsOneWidget);
        for (final perk in const [
          'Likes illimités',
          'Voir qui vous a aimé',
          '5 Super Likes par jour',
          'Un Boost par jour',
          'Revenir en arrière',
          'Filtres avancés',
        ]) {
          expect(find.text(perk), findsOneWidget, reason: perk);
        }
        expect(find.text('VOTRE FORMULE'), findsOneWidget);
        expect(find.text('1 mois'), findsOneWidget);
        expect(find.text('3 mois'), findsOneWidget);
        expect(find.text('6 mois'), findsOneWidget);
        expect(find.text('12 mois'), findsOneWidget);
        expect(find.text('2 mois'), findsNothing);
        expect(find.text('-25 %'), findsOneWidget);
        expect(find.text('-42 %'), findsOneWidget);
        expect(find.text('-58 %'), findsOneWidget);
        expect(find.text('Restaurer'), findsOneWidget);
        expect(find.text('Conditions'), findsOneWidget);
        expect(find.text('Confidentialité'), findsOneWidget);
        expect(find.textContaining('Mazl Pro'), findsNothing);
      },
    );

    testWidgets('choisir une formule change le prix du bouton', (tester) async {
      await _pumpOffer(tester);

      // 3 mois, la formule mise en avant, est présélectionné
      expect(find.text('Continuer · 44,99 €'), findsOneWidget);

      await tester.tap(find.text('1 mois'));
      await tester.pump();
      expect(find.text('Continuer · 19,99 €'), findsOneWidget);
      expect(find.text('Continuer · 44,99 €'), findsNothing);

      await tester.tap(find.text('6 mois'));
      await tester.pump();
      expect(find.text('Continuer · 69,99 €'), findsOneWidget);

      await tester.tap(find.text('12 mois'));
      await tester.pump();
      expect(find.text('Continuer · 99,99 €'), findsOneWidget);
    });

    testWidgets(
      'la formule choisie a un contour encre de 2 px, les autres un filet',
      (tester) async {
        await _pumpOffer(tester);

        final selectedSide = tester
            .widgetList<Material>(find.byType(Material))
            .map((m) => m.shape)
            .whereType<RoundedRectangleBorder>()
            .map((s) => s.side)
            .where((side) => side.width == 2)
            .toList();
        expect(selectedSide, hasLength(1));
        expect(selectedSide.single.color, AppColors.ink);
      },
    );

    testWidgets('pas de dégradé, fond blanc, "+" en tekhelet', (tester) async {
      await _pumpOffer(tester);

      _expectNoGradientNorShadow(tester);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppColors.paper);
      final title = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == 'mazl+',
        ),
      );
      final plus = (title.textSpan! as TextSpan).children!.last as TextSpan;
      expect(plus.style?.color, AppColors.tekhelet);
    });

    testWidgets(
      'cibles tactiles de 44 px minimum et libellés d\'accessibilité',
      (tester) async {
        await _pumpOffer(tester);

        _expectTouchTarget(tester, find.byType(RoundIconButton));
        _expectTouchTarget(
          tester,
          find.widgetWithText(TextButton, 'Restaurer'),
        );
        _expectTouchTarget(
          tester,
          find.widgetWithText(TextButton, 'Conditions'),
        );
        expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
      },
    );

    testWidgets('mode sombre : même arbre, aucun dégradé', (tester) async {
      await _pumpOffer(tester, theme: AppTheme.darkTheme);

      expect(find.text('Rencontrez sans compter.'), findsOneWidget);
      _expectNoGradientNorShadow(tester);
    });

    testWidgets('tient à 320 px de large sans débordement', (tester) async {
      await _pump(
        tester,
        PremiumScreen(loadPlans: () async => const []),
        size: const Size(320, 700),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });

  group('limite du jour (P1)', () {
    testWidgets(
      'affiche l\'étiquette, le titre, le compte à rebours et les deux actions',
      (tester) async {
        var now = DateTime(2026, 10, 23, 23, 59, 30);
        await _pump(
          tester,
          Scaffold(body: DailyLimitSheet(freeLikesPerDay: 10, now: () => now)),
        );

        expect(find.text('LIMITE DU JOUR · 10 / 10'), findsOneWidget);
        expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
        expect(find.text('Prochains likes dans'), findsOneWidget);
        expect(find.text('00:00:30'), findsOneWidget);
        expect(find.text('Découvrir mazl+'), findsOneWidget);
        expect(find.text('Attendre minuit'), findsOneWidget);

        // le compte à rebours avance avec l'horloge
        now = now.add(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:00:20'), findsOneWidget);

        _expectNoGradientNorShadow(tester);
        _expectTouchTarget(
          tester,
          find.widgetWithText(TextButton, 'Attendre minuit'),
        );
      },
    );

    testWidgets('« Découvrir mazl+ » ouvre l\'offre', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => PremiumGate.showDailyLimitSheet(context),
                child: const Text('ouvrir'),
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.premium,
            builder: (_, __) => const Scaffold(body: Text('page offre')),
          ),
        ],
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Découvrir mazl+'));
      await tester.pumpAndSettle();

      expect(find.text('page offre'), findsOneWidget);
    });

    testWidgets('« Attendre minuit » ferme sans ouvrir l\'offre', (
      tester,
    ) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PremiumGate.showDailyLimitSheet(context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attendre minuit'));
      await tester.pumpAndSettle();

      expect(find.text('Vos likes du jour sont partis.'), findsNothing);
    });
  });

  group('fenêtre d\'une fonction réservée', () {
    testWidgets('même vocabulaire que la limite du jour', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: PremiumFeatureSheet(
            title: 'Revenir en arrière',
            description: 'Rattrapez un « Passer » trop rapide.',
          ),
        ),
      );

      expect(find.text('RÉSERVÉ À MAZL+'), findsOneWidget);
      expect(find.text('Revenir en arrière'), findsOneWidget);
      expect(find.text('Découvrir mazl+'), findsOneWidget);
      expect(find.text('Pas maintenant'), findsOneWidget);
      _expectNoGradientNorShadow(tester);
    });
  });

  group('bienvenue (P3)', () {
    testWidgets('annonce la formule et les trois premiers gestes', (
      tester,
    ) async {
      await _pump(
        tester,
        PlusWelcomeScreen(planLabel: '6 mois', loadLikesCount: () async => 12),
      );

      expect(find.text('ABONNEMENT ACTIF · 6 MOIS'), findsOneWidget);
      expect(find.text('Bienvenue dans mazl+.'), findsOneWidget);
      expect(
        find.text('Tout est déverrouillé. Par où commencer ?'),
        findsOneWidget,
      );
      expect(find.text('12 personnes vous ont aimé'), findsOneWidget);
      expect(find.text('Lancer votre Boost'), findsOneWidget);
      expect(find.text('Affiner vos filtres'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
      _expectNoGradientNorShadow(tester);
      _expectTouchTarget(tester, find.widgetWithText(TextButton, 'Plus tard'));
    });

    testWidgets('accorde le singulier', (tester) async {
      await _pump(
        tester,
        PlusWelcomeScreen(planLabel: '1 mois', loadLikesCount: () async => 1),
      );
      expect(find.text('1 personne vous a aimé'), findsOneWidget);
    });

    testWidgets('tolère un nombre inconnu et une formule inconnue', (
      tester,
    ) async {
      await _pump(
        tester,
        PlusWelcomeScreen(planLabel: null, loadLikesCount: () async => null),
      );
      expect(find.text('Voir qui vous a aimé'), findsOneWidget);
      expect(find.text('ABONNEMENT ACTIF'), findsOneWidget);
    });

    testWidgets('la rangée « personnes vous ont aimé » mène aux likes', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: RoutePaths.plusWelcome,
        routes: [
          GoRoute(
            path: RoutePaths.plusWelcome,
            builder: (_, __) => PlusWelcomeScreen(
              planLabel: '6 mois',
              loadLikesCount: () async => 12,
            ),
          ),
          GoRoute(
            path: RoutePaths.likes,
            builder: (_, __) => const Scaffold(body: Text('page likes')),
          ),
        ],
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('12 personnes vous ont aimé'));
      await tester.pumpAndSettle();
      expect(find.text('page likes'), findsOneWidget);
    });
  });

  group('abonnement (P5)', () {
    testWidgets(
      'affiche la carte, la formule, l\'échéance et les avantages du jour',
      (tester) async {
        var managed = 0;
        await _pump(
          tester,
          SubscriptionScreen(snapshot: _active, onManage: () => managed++),
        );

        expect(find.text('Abonnement'), findsOneWidget);
        expect(find.text('mazl+'), findsOneWidget);
        expect(find.text('Actif'), findsOneWidget);
        expect(find.text('FORMULE'), findsOneWidget);
        expect(find.text('6 mois · 59,99 €'), findsOneWidget);
        expect(find.text('RENOUVELLEMENT'), findsOneWidget);
        expect(find.text('12 mars 2027'), findsOneWidget);
        expect(find.text("AUJOURD'HUI"), findsOneWidget);
        expect(find.text('4 sur 5'), findsOneWidget);
        expect(find.text('Disponible'), findsOneWidget);
        expect(find.text('Illimités'), findsOneWidget);
        expect(find.text('Restaurer mes achats'), findsOneWidget);
        _expectNoGradientNorShadow(tester);

        await tester.tap(find.text('Gérer dans l’App Store'));
        expect(managed, 1);
      },
    );

    testWidgets('un abonnement résilié annonce son expiration', (tester) async {
      await _pump(
        tester,
        SubscriptionScreen(
          snapshot: SubscriptionSnapshot(
            isActive: true,
            planLabel: '12 mois',
            renewalDate: DateTime(2027, 1, 1),
            willRenew: false,
            superLikesLeft: 0,
            superLikesMax: 5,
            boostAvailable: false,
          ),
        ),
      );

      expect(find.text('EXPIRATION'), findsOneWidget);
      expect(find.text('RENOUVELLEMENT'), findsNothing);
      expect(find.text('1er janvier 2027'), findsOneWidget);
      expect(find.text('Résilié'), findsOneWidget);
      expect(find.text('0 sur 5'), findsOneWidget);
      expect(find.text('Utilisé aujourd’hui'), findsOneWidget);
    });

    testWidgets('sans abonnement : propose de découvrir mazl+', (tester) async {
      await _pump(
        tester,
        const SubscriptionScreen(
          snapshot: SubscriptionSnapshot(isActive: false),
        ),
      );

      expect(find.text('Aucun abonnement actif.'), findsOneWidget);
      expect(find.text('Découvrir mazl+'), findsOneWidget);
      expect(find.textContaining('Gérer dans'), findsNothing);
    });

    testWidgets('mode sombre : aucun dégradé', (tester) async {
      await _pump(
        tester,
        SubscriptionScreen(snapshot: _active),
        theme: AppTheme.darkTheme,
      );
      expect(find.text('Illimités'), findsOneWidget);
      _expectNoGradientNorShadow(tester);
    });
  });

  group('réglages : section Abonnement', () {
    testWidgets('abonné : une ligne « mazl+ » vers la gestion', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        Scaffold(
          body: PlusSettingsCard(
            isPremium: true,
            detail: '6 mois · renouvellement le 12 mars 2027',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('mazl+'), findsOneWidget);
      expect(
        find.text('6 mois · renouvellement le 12 mars 2027'),
        findsOneWidget,
      );
      _expectNoGradientNorShadow(tester);
      await tester.tap(find.text('mazl+'));
      expect(taps, 1);
    });

    testWidgets('gratuit : une ligne « Passer à mazl+ » vers l\'offre', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        Scaffold(body: PlusSettingsCard(isPremium: false, onTap: () => taps++)),
      );

      expect(find.text('Passer à mazl+'), findsOneWidget);
      expect(find.textContaining('Likes illimités'), findsOneWidget);
      _expectNoGradientNorShadow(tester);
      await tester.tap(find.text('Passer à mazl+'));
      expect(taps, 1);
    });
  });
}
