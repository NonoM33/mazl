import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';

import '../../support/store_fakes.dart';

/// L'écran d'offre branché sur un vrai [SubscriptionService] (faux store, fausse
/// API) : ce que l'utilisateur voit pour chaque issue d'un achat.
void main() {
  // « 14,99 € » avec l'espace insécable de la typographie française.
  final continueLabel =
      'Continuer · ${planTotalLabel(price: 14.99, currencyCode: 'EUR')}';
  late FakeStoreGateway gateway;
  late FakeSubscriptionApi api;
  late SubscriptionService service;

  setUp(() async {
    storeJournal.clear();
    gateway = FakeStoreGateway();
    api = FakeSubscriptionApi();
    service = SubscriptionService.create(
      gateway: gateway,
      api: api,
      platform: TargetPlatform.iOS,
      now: () => testNow,
      // Assez long pour que le faux store ait livré l'achat restauré (la
      // livraison passe par la vraie boucle d'événements, voir settle).
      restoreSettle: const Duration(milliseconds: 60),
    );
    await service.initialize();
    await service.onSignedIn('jwt-de-test');
  });

  tearDown(() async {
    service.dispose();
    await gateway.controller.close();
  });

  Future<void> pumpOffer(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.iOS,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('page accueil')),
        ),
        GoRoute(
          path: RoutePaths.premium,
          builder: (_, _) =>
              PremiumScreen(service: service, loadPlans: service.loadPlans),
        ),
        GoRoute(
          path: RoutePaths.plusWelcome,
          builder: (_, _) => const Scaffold(body: Text('page bienvenue')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme.copyWith(platform: platform),
        routerConfig: router,
      ),
    );
    await tester.pump();
    unawaited(router.push<bool>(RoutePaths.premium));
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // fin de la transition
  }

  /// Le service écoute le flux depuis la zone réelle (setUp) : ses suites
  /// d'`await` n'avancent que lorsque la boucle d'événements réelle tourne,
  /// d'où l'alternance pump (horloge du test) / runAsync (vraie boucle).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    await tester.pump();
  }

  testWidgets('affiche la formule du store avec son vrai prix', (tester) async {
    await pumpOffer(tester);

    expect(find.text('1 mois'), findsOneWidget);
    expect(find.text(continueLabel), findsOneWidget);
    // Les formules par défaut (6 et 12 mois) ne sont plus proposées.
    expect(find.text('6 mois'), findsNothing);
  });

  testWidgets('achat réussi : le JWS part au serveur puis l\'accueil mazl+', (
    tester,
  ) async {
    gateway.onBuy = (_) async =>
        gateway.emit(purchaseDetails(PurchaseStatus.purchased));
    await pumpOffer(tester);

    await tester.tap(find.text(continueLabel));
    await settle(tester);

    expect(api.verifyBodies, [
      {'signedTransaction': 'JWS-2000000123'},
    ]);
    expect(find.text('page bienvenue'), findsOneWidget);
  });

  testWidgets('achat annulé : on reste sur l\'offre, aucun message d\'erreur', (
    tester,
  ) async {
    gateway.onBuy = (_) async =>
        gateway.emit(purchaseDetails(PurchaseStatus.canceled));
    await pumpOffer(tester);

    await tester.tap(find.text(continueLabel));
    await settle(tester);

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('page bienvenue'), findsNothing);
    expect(find.text(continueLabel), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull, reason: 'le bouton redevient actif');
  });

  testWidgets('achat déjà lié à un autre compte : message clair', (
    tester,
  ) async {
    api.onVerify = () => const ApiReply(409, {
      'success': false,
      'error': 'transaction_owned_by_another_user',
    });
    gateway.onBuy = (_) async =>
        gateway.emit(purchaseDetails(PurchaseStatus.purchased));
    await pumpOffer(tester);

    await tester.tap(find.text(continueLabel));
    await settle(tester);

    expect(
      find.text('Cet achat App Store est déjà associé à un autre compte mazl.'),
      findsOneWidget,
    );
    expect(find.text('page bienvenue'), findsNothing);
  });

  testWidgets('Android : l\'achat est désactivé avec un message', (
    tester,
  ) async {
    await pumpOffer(tester, platform: TargetPlatform.android);

    expect(find.text('Bientôt disponible sur Android'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(gateway.bought, isEmpty);
  });

  testWidgets('Restaurer : abonnement retrouvé -> message de succès', (
    tester,
  ) async {
    gateway.onRestore = () async =>
        gateway.emit(purchaseDetails(PurchaseStatus.restored, id: '1999'));
    await pumpOffer(tester);

    await tester.tap(find.text('Restaurer'));
    await settle(tester);

    expect(service.isMazlPro, isTrue);
    expect(gateway.restoreCalls, 1);
    expect(find.text('Abonnement restauré'), findsOneWidget);
    // L'offre se referme : on est revenu à l'accueil.
    expect(find.text('page accueil'), findsOneWidget);
  });

  testWidgets('Restaurer : rien à restaurer -> « Aucun abonnement trouvé »', (
    tester,
  ) async {
    await pumpOffer(tester);

    await tester.tap(find.text('Restaurer'));
    await settle(tester);

    expect(find.text('Aucun abonnement trouvé'), findsOneWidget);
  });
}
