import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_models.dart';
import 'package:mazl/core/services/store/subscription_service.dart';
import '../../../support/store_fakes.dart';

SubscriptionService _service(
  FakeStoreGateway gateway,
  FakeSubscriptionApi api, {
  TargetPlatform platform = TargetPlatform.iOS,
  Future<bool> Function(Uri uri)? openUrl,
  Duration purchaseSettleTimeout = const Duration(seconds: 5),
}) => SubscriptionService.create(
  gateway: gateway,
  api: api,
  platform: platform,
  now: () => testNow,
  restoreSettle: Duration.zero,
  purchaseSettleTimeout: purchaseSettleTimeout,
  openUrl: openUrl ?? (_) async => true,
);

Future<SubscriptionPlan> _firstPlan(SubscriptionService service) async {
  final plans = await service.loadPlans();
  expect(plans, hasLength(1));
  return plans.single;
}

void main() {
  late FakeStoreGateway gateway;
  late FakeSubscriptionApi api;
  late SubscriptionService service;

  setUp(() async {
    storeJournal.clear();
    gateway = FakeStoreGateway();
    api = FakeSubscriptionApi();
    service = _service(gateway, api);
    await service.initialize();
    await service.onSignedIn('jwt-de-test');
    storeJournal.clear();
    api.getCalls = 0;
  });

  tearDown(() async {
    service.dispose();
    await gateway.controller.close();
  });

  group('loadPlans', () {
    test('rend le produit du store avec durée, prix et devise', () async {
      final plan = await _firstPlan(service);

      expect(plan.productId, testProductId);
      expect(plan.months, 1);
      expect(plan.price, 14.99);
      expect(plan.currencyCode, 'EUR');
      expect(plan.priceLabel, '14,99 €');
    });

    test('la durée vient de l\'identifiant com.mazl.app.plus.<n>m', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct('com.mazl.app.plus.6m', price: 59.99),
          storeProduct('com.mazl.app.plus.1m'),
        ],
        notFoundIDs: const [],
      );
      final plans = await service.loadPlans();
      // Triées de la plus courte à la plus longue.
      expect(plans.map((p) => p.months), [1, 6]);
    });

    test('ignore un produit dont l\'identifiant n\'a pas de durée', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct('autre.chose'),
          storeProduct(testProductId),
        ],
        notFoundIDs: const [],
      );
      expect((await service.loadPlans()).map((p) => p.productId), [
        testProductId,
      ]);
    });

    test('store indisponible : liste vide, sans exception', () async {
      gateway.available = false;
      expect(await service.loadPlans(), isEmpty);
    });

    test('le store échoue : liste vide, sans exception', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [testProductId],
        error: IAPError(source: 'app_store', code: 'x', message: 'boom'),
      );
      expect(await service.loadPlans(), isEmpty);
    });
  });

  group('loadCouplePlan', () {
    test('rend le produit MAZL Couple avec le prix du store', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct(testProductId),
          storeProduct('com.mazl.app.couple.1m', price: 29.99),
        ],
        notFoundIDs: const [],
      );

      final plan = await service.loadCouplePlan();

      expect(plan?.productId, 'com.mazl.app.couple.1m');
      expect(plan?.months, 1);
      expect(plan?.price, 29.99);
    });

    test('le produit couple n\'entre pas dans les formules mazl+', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct(testProductId),
          storeProduct('com.mazl.app.couple.1m', price: 29.99),
        ],
        notFoundIDs: const [],
      );

      expect((await service.loadPlans()).map((p) => p.productId), [
        testProductId,
      ]);
    });

    test('inconnu du store, store indisponible ou en panne : null', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: [storeProduct(testProductId)],
        notFoundIDs: const ['com.mazl.app.couple.1m'],
      );
      expect(await service.loadCouplePlan(), isNull);

      gateway.available = false;
      expect(await service.loadCouplePlan(), isNull);
    });
  });

  group('achat', () {
    test(
      'annulé par l\'utilisateur : PurchaseCancelled, rien n\'est jeté ni vérifié',
      () async {
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.canceled));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseCancelled>());
        expect(api.verifyBodies, isEmpty);
        expect(service.isMazlPro, isFalse);
      },
    );

    test(
      'annulation remontée comme une erreur StoreKit (code 2) : toujours une annulation',
      () async {
        gateway.onBuy = (_) async => gateway.emit(
          purchaseDetails(
            PurchaseStatus.error,
            error: IAPError(
              source: 'app_store',
              code: 'storekit_purchase_cancelled',
              message:
                  'The operation couldn’t be completed. (SKErrorDomain error 2.)',
              details: {'code': 2},
            ),
          ),
        );
        final plan = await _firstPlan(service);

        expect(await service.purchase(plan), isA<PurchaseCancelled>());
      },
    );

    test(
      'annulation levée comme PlatformException par le plugin : annulation, pas erreur',
      () async {
        gateway.buyError = PlatformException(
          code: 'storekit2_purchase_cancelled',
          message: 'cancelled',
        );
        final plan = await _firstPlan(service);

        expect(await service.purchase(plan), isA<PurchaseCancelled>());
      },
    );

    test(
      'une vraie erreur du store est un PurchaseFailed « échec général »',
      () async {
        gateway.onBuy = (_) async => gateway.emit(
          purchaseDetails(
            PurchaseStatus.error,
            error: IAPError(
              source: 'app_store',
              code: 'storekit_duplicate',
              message: 'x',
            ),
          ),
        );
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseFailed>());
        expect((result as PurchaseFailed).problem, PurchaseProblem.generic);
        expect(service.isMazlPro, isFalse);
      },
    );

    test(
      'acheté : le JWS part tel quel au backend, premium, puis completePurchase',
      () async {
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseSucceeded>());
        expect(api.verifyBodies, [
          {'signedTransaction': 'JWS-2000000123'},
        ]);
        expect(service.isMazlPro, isTrue);
        expect(service.expirationDate, DateTime.utc(2026, 12, 1, 12));
        expect(service.activePlanMonths, 1);
        // La transaction n'est terminée QU'APRÈS la vérification serveur.
        expect(storeJournal, ['verify', 'complete:2000000123']);
      },
    );

    test('le produit acheté est celui du plan choisi', () async {
      gateway.onBuy = (_) async =>
          gateway.emit(purchaseDetails(PurchaseStatus.purchased));
      final plan = await _firstPlan(service);
      await service.purchase(plan);

      expect(gateway.bought.single.productDetails.id, testProductId);
    });

    test(
      '409 : problème « déjà associé à un autre compte mazl », pas premium',
      () async {
        api.onVerify = () => const ApiReply(409, {
          'success': false,
          'error': 'transaction_owned_by_another_user',
        });
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseFailed>());
        expect(
          (result as PurchaseFailed).problem,
          PurchaseProblem.ownedByAnotherAccount,
        );
        expect(service.isMazlPro, isFalse);
      },
    );

    test(
      '409 : refus définitif, la transaction est terminée (sinon rejouée à chaque lancement)',
      () async {
        api.onVerify = () => const ApiReply(409, {
          'success': false,
          'error': 'transaction_owned_by_another_user',
        });
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        await service.purchase(plan);

        expect(storeJournal, ['verify', 'complete:2000000123']);
      },
    );

    test(
      '422 : erreur, pas premium, transaction NON terminée (rejouable après correction)',
      () async {
        api.onVerify = () => const ApiReply(422, {
          'success': false,
          'error': 'invalid_transaction',
        });
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseFailed>());
        expect(
          (result as PurchaseFailed).problem,
          PurchaseProblem.invalidTransaction,
        );
        expect(service.isMazlPro, isFalse);
        expect(gateway.completed, isEmpty);
      },
    );

    test('400 : erreur, transaction NON terminée', () async {
      api.onVerify = () =>
          const ApiReply(400, {'success': false, 'error': 'invalid_body'});
      gateway.onBuy = (_) async =>
          gateway.emit(purchaseDetails(PurchaseStatus.purchased));
      final plan = await _firstPlan(service);

      final result = await service.purchase(plan);
      expect(result, isA<PurchaseFailed>());
      expect((result as PurchaseFailed).problem, PurchaseProblem.invalidBody);
      expect(gateway.completed, isEmpty);
    });

    test(
      'réseau coupé pendant la vérification : erreur, NON terminée, pas premium',
      () async {
        api.onVerify = () => throw TimeoutException('réseau');
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);

        expect(result, isA<PurchaseFailed>());
        expect((result as PurchaseFailed).problem, PurchaseProblem.offline);
        expect(service.isMazlPro, isFalse);
        expect(gateway.completed, isEmpty);
      },
    );

    test(
      '200 mais corps illisible : jamais premium sur une réponse qu\'on ne comprend pas',
      () async {
        api.onVerify = () => const ApiReply(200, {
          'success': true,
          'subscription': {'x': 1},
        });
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        final plan = await _firstPlan(service);

        expect(await service.purchase(plan), isA<PurchaseFailed>());
        expect(service.isMazlPro, isFalse);
        expect(gateway.completed, isEmpty);
      },
    );

    test(
      'Ask to Buy : PurchasePending, puis l\'approbation arrive plus tard sur le flux',
      () async {
        gateway.onBuy = (_) async =>
            gateway.emit(purchaseDetails(PurchaseStatus.pending));
        final plan = await _firstPlan(service);

        final result = await service.purchase(plan);
        expect(result, isA<PurchasePending>());
        expect(service.isMazlPro, isFalse);
        expect(gateway.completed, isEmpty);

        // Le parent approuve : la transaction réapparaît, achetée.
        gateway.emit(purchaseDetails(PurchaseStatus.purchased));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(service.isMazlPro, isTrue);
        expect(storeJournal, ['verify', 'complete:2000000123']);
      },
    );

    test(
      'le store ne répond jamais : PurchasePending après le délai, pas de blocage',
      () async {
        final impatient = _service(
          gateway,
          api,
          purchaseSettleTimeout: const Duration(milliseconds: 20),
        );
        await impatient.initialize();
        await impatient.onSignedIn('jwt');
        final plan = (await impatient.loadPlans()).single;

        expect(await impatient.purchase(plan), isA<PurchasePending>());
        impatient.dispose();
      },
    );

    test(
      'la même transaction livrée deux fois n\'est vérifiée qu\'une fois',
      () async {
        final d = purchaseDetails(PurchaseStatus.purchased);
        // Deux livraisons quasi simultanées de la même transaction.
        gateway.emit(d);
        gateway.emit(d);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(api.verifyBodies, hasLength(1));
        expect(gateway.completed, hasLength(1));
      },
    );

    test('un achat déjà en cours refuse d\'en lancer un second', () async {
      final plan = await _firstPlan(service);
      final first = service.purchase(plan); // jamais résolu par le faux store
      final second = await service.purchase(plan);

      expect(second, isA<PurchaseFailed>());
      expect(
        (second as PurchaseFailed).problem,
        PurchaseProblem.purchaseInProgress,
      );
      gateway.emit(purchaseDetails(PurchaseStatus.canceled));
      expect(await first, isA<PurchaseCancelled>());
    });
  });

  group('transaction livrée au lancement, avant la connexion', () {
    test(
      'non vérifiable sans compte : gardée, puis vérifiée et terminée à la connexion',
      () async {
        final coldGateway = FakeStoreGateway();
        final cold = _service(coldGateway, api);
        await cold.initialize(); // pas encore connecté
        storeJournal.clear();

        api.onVerify = () =>
            const ApiReply(401, {'success': false, 'error': 'unauthorized'});
        coldGateway.emit(purchaseDetails(PurchaseStatus.purchased));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(cold.isMazlPro, isFalse);
        expect(coldGateway.completed, isEmpty);

        api.onVerify = () => ApiReply(200, activeSubscriptionBody());
        await cold.onSignedIn('jwt');

        expect(cold.isMazlPro, isTrue);
        expect(coldGateway.completed.map((d) => d.purchaseID), ['2000000123']);
        cold.dispose();
        await coldGateway.controller.close();
      },
    );
  });

  group('restauration', () {
    test('un achat restauré est vérifié puis ouvre le droit', () async {
      gateway.onRestore = () async => gateway.emit(
        purchaseDetails(
          PurchaseStatus.restored,
          id: '1999',
          jws: 'JWS-RESTORED',
        ),
      );

      final result = await service.restore();

      expect(result, isA<RestoreFound>());
      expect(api.verifyBodies, [
        {'signedTransaction': 'JWS-RESTORED'},
      ]);
      expect(service.isMazlPro, isTrue);
      expect(storeJournal.first, 'verify');
      expect(gateway.completed.map((d) => d.purchaseID), ['1999']);
    });

    test('rien à restaurer : RestoreNothing, toujours pas premium', () async {
      final result = await service.restore();

      expect(result, isA<RestoreNothing>());
      expect(gateway.restoreCalls, 1);
      expect(service.isMazlPro, isFalse);
    });

    test(
      'rien dans le store mais le serveur connaît l\'abonnement : restauré',
      () async {
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());

        expect(await service.restore(), isA<RestoreFound>());
        expect(service.isMazlPro, isTrue);
      },
    );

    test('restauration refusée par le serveur (409) : message clair', () async {
      api.onVerify = () => const ApiReply(409, {
        'success': false,
        'error': 'transaction_owned_by_another_user',
      });
      gateway.onRestore = () async =>
          gateway.emit(purchaseDetails(PurchaseStatus.restored));

      final result = await service.restore();

      expect(result, isA<RestoreFailed>());
      expect(
        (result as RestoreFailed).problem,
        PurchaseProblem.ownedByAnotherAccount,
      );
    });

    test('le store plante : RestoreFailed, jamais d\'exception', () async {
      final broken = _BrokenRestoreGateway();
      final s = _service(broken, api);
      await s.initialize();
      await s.onSignedIn('jwt');

      final result = await s.restore();
      expect(result, isA<RestoreFailed>());
      expect(
        (result as RestoreFailed).problem,
        PurchaseProblem.restoreFailed,
      );
      s.dispose();
      await broken.controller.close();
    });
  });

  group('statut premium (source de vérité : GET /api/subscription)', () {
    test('actif et échéance dans le futur : premium', () async {
      api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
      await service.refresh();

      expect(service.isMazlPro, isTrue);
      expect(service.activePlanMonths, 1);
      expect(service.willRenew, isTrue);
    });

    test(
      'échéance dépassée : pas premium, même avec le statut « active »',
      () async {
        api.onGetSubscription = () => ApiReply(
          200,
          activeSubscriptionBody(expiresAt: '2026-10-31T23:59:59.000Z'),
        );
        await service.refresh();

        expect(service.isMazlPro, isFalse);
        expect(service.activePlanMonths, isNull);
      },
    );

    test('subscription: null : pas premium', () async {
      await service.refresh();
      expect(service.isMazlPro, isFalse);
      expect(service.expirationDate, isNull);
    });

    test(
      'le service suit l\'horloge : un abonnement qui expire cesse d\'être premium',
      () async {
        var current = testNow;
        final timed = SubscriptionService.create(
          gateway: gateway,
          api: api,
          platform: TargetPlatform.iOS,
          now: () => current,
          restoreSettle: Duration.zero,
          openUrl: (_) async => true,
        );
        await timed.onSignedIn('jwt');
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
        await timed.refresh();
        expect(timed.isMazlPro, isTrue);

        current = DateTime.utc(2026, 12, 1, 12);
        expect(timed.isMazlPro, isFalse);
        timed.dispose();
      },
    );

    test(
      'refresh : le réseau tombe, le dernier état connu est conservé',
      () async {
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
        await service.refresh();
        api.onGetSubscription = () => throw TimeoutException('réseau');

        await service.refresh();

        expect(service.isMazlPro, isTrue);
      },
    );

    test(
      'refresh : 401 -> on ne garde pas un statut premium d\'une session morte',
      () async {
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
        await service.refresh();
        api.onGetSubscription = () => const ApiReply(401, {'success': false});

        await service.refresh();

        expect(service.isMazlPro, isFalse);
      },
    );

    test('connexion : le statut est rafraîchi', () async {
      final fresh = _service(gateway, api);
      api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());

      await fresh.onSignedIn('jwt');

      expect(fresh.isMazlPro, isTrue);
      fresh.dispose();
    });

    test(
      'déconnexion : le statut est effacé et plus aucun appel authentifié',
      () async {
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
        await service.refresh();
        expect(service.isMazlPro, isTrue);
        api.getCalls = 0;

        service.onSignedOut();
        await service.refresh();

        expect(service.isMazlPro, isFalse);
        expect(api.getCalls, 0);
      },
    );

    test('notifie ses auditeurs quand le statut change', () async {
      var notified = 0;
      service.addListener(() => notified++);
      api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());

      await service.refresh();

      expect(notified, greaterThan(0));
    });
  });

  group('Android : pas encore de vérification Google Play côté serveur', () {
    test(
      'canPurchase est faux et acheter est refusé avec un message clair',
      () async {
        final android = _service(
          gateway,
          api,
          platform: TargetPlatform.android,
        );
        await android.initialize();
        await android.onSignedIn('jwt');
        final plan = (await android.loadPlans()).single;

        expect(android.canPurchase, isFalse);
        expect(
          android.unavailablePurchaseProblem,
          PurchaseProblem.androidSoon,
        );
        final result = await android.purchase(plan);

        expect(result, isA<PurchaseFailed>());
        expect(
          (result as PurchaseFailed).problem,
          PurchaseProblem.androidSoon,
        );
        expect(gateway.bought, isEmpty);
        android.dispose();
      },
    );

    test(
      'Android n\'écoute pas le flux d\'achats (rien ne part non vérifié)',
      () async {
        final androidGateway = FakeStoreGateway();
        final android = _service(
          androidGateway,
          api,
          platform: TargetPlatform.android,
        );
        await android.initialize();
        androidGateway.emit(purchaseDetails(PurchaseStatus.purchased));
        await Future<void>.delayed(Duration.zero);

        expect(androidGateway.controller.hasListener, isFalse);
        expect(api.verifyBodies, isEmpty);
        expect(androidGateway.completed, isEmpty);
        android.dispose();
        await androidGateway.controller.close();
      },
    );

    test('iOS peut acheter', () {
      expect(service.canPurchase, isTrue);
      expect(service.unavailablePurchaseProblem, isNull);
    });
  });

  group('gérer l\'abonnement', () {
    test('iOS : ouvre la page des abonnements de l\'App Store', () async {
      Uri? opened;
      final s = _service(
        gateway,
        api,
        openUrl: (uri) async {
          opened = uri;
          return true;
        },
      );

      expect(await s.manageSubscriptions(), isTrue);
      expect(opened, Uri.parse('https://apps.apple.com/account/subscriptions'));
      s.dispose();
    });

    test('Android : page des abonnements de Google Play', () async {
      Uri? opened;
      final s = _service(
        gateway,
        api,
        platform: TargetPlatform.android,
        openUrl: (uri) async {
          opened = uri;
          return true;
        },
      );
      await s.manageSubscriptions();
      expect(
        opened,
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      );
      s.dispose();
    });

    test('ouverture impossible : faux, sans exception', () async {
      final s = _service(gateway, api, openUrl: (_) async => false);
      expect(await s.manageSubscriptions(), isFalse);
      s.dispose();
    });
  });

  group('prix de la formule active', () {
    test(
      'retrouve le prix du store pour le produit de l\'abonnement',
      () async {
        api.onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
        await service.refresh();

        expect(await service.activePlanPrice(), '14,99 €');
      },
    );

    test('sans abonnement : null', () async {
      expect(await service.activePlanPrice(), isNull);
    });
  });
}

class _BrokenRestoreGateway extends FakeStoreGateway {
  @override
  Future<void> restorePurchases() async {
    throw PlatformException(code: 'boom', message: 'App Store injoignable');
  }
}
