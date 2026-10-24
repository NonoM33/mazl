import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credit_pack.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_models.dart';

import '../../../support/credits_fakes.dart';
import '../../../support/store_fakes.dart';

CreditsService _service(
  FakeStoreGateway gateway,
  FakeCreditsApi api, {
  TargetPlatform platform = TargetPlatform.iOS,
  Duration purchaseSettleTimeout = const Duration(seconds: 5),
}) => CreditsService.create(
  gateway: gateway,
  api: api,
  platform: platform,
  purchaseSettleTimeout: purchaseSettleTimeout,
);

/// Le store livre le consommable [productId] au service, comme le fait le flux
/// d'achats de `SubscriptionService`.
Future<void> Function(PurchaseParam) _delivers(
  CreditsService service,
  PurchaseStatus status, {
  String id = '2000000456',
  String jws = 'JWS-2000000456',
  String productId = testBoostPackId,
}) =>
    (_) => service.handlePurchase(
      purchaseDetails(status, id: id, jws: jws, productId: productId),
    );

Future<CreditPack> _boostPack(
  CreditsService service, {
  String id = testBoostPackId,
}) async {
  final packs = await service.loadPacks(CreditKind.boost);
  return packs.firstWhere((p) => p.product.id == id);
}

void main() {
  late FakeStoreGateway gateway;
  late FakeCreditsApi api;
  late CreditsService service;

  setUp(() async {
    storeJournal.clear();
    gateway = FakeStoreGateway()
      ..productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct('com.mazl.app.boost.1', price: 1.99),
          storeProduct(testBoostPackId, price: 4.99),
          storeProduct(testSuperLikePackId, price: 3.99),
          storeProduct('com.mazl.app.superlikes.15', price: 9.99),
        ],
        notFoundIDs: const [],
      );
    api = FakeCreditsApi();
    service = _service(gateway, api);
    await service.onSignedIn('jwt-de-test');
    storeJournal.clear();
    api.getCalls = 0;
  });

  tearDown(() async {
    service.dispose();
    await gateway.controller.close();
  });

  group('solde', () {
    test('refresh lit GET /api/credits et tient le solde', () async {
      var notified = 0;
      service.addListener(() => notified++);

      await service.refresh();

      expect(api.getCalls, 1);
      expect(service.available(CreditKind.superLike), 15);
      expect(service.balance!.boost.purchasedBalance, 2);
      expect(service.balance!.superLike.dailyAllowance, 5);
      expect(notified, 1);
    });

    test('onSignedIn lit le solde sans autre appel', () async {
      final fresh = _service(gateway, api);
      addTearDown(fresh.dispose);
      expect(fresh.balance, isNull);

      await fresh.onSignedIn('jwt');

      expect(fresh.available(CreditKind.boost), 2);
    });

    test('sans session, refresh ne fait aucun appel', () async {
      final fresh = _service(gateway, api);
      addTearDown(fresh.dispose);
      api.getCalls = 0;

      await fresh.refresh();

      expect(api.getCalls, 0);
      expect(fresh.balance, isNull);
    });

    test('applyFromServer prend le credits d\'un swipe, d\'un boost', () {
      var notified = 0;
      service.addListener(() => notified++);

      service.applyFromServer(
        serverCredits(superLikeRemaining: 0, superLikePurchased: 0),
      );

      expect(service.available(CreditKind.superLike), 0);
      expect(notified, 1);
    });

    test(
      'applyFromServer ignore une forme illisible et garde le solde',
      () async {
        await service.refresh();
        service.applyFromServer({'super_like': 'oups'});
        service.applyFromServer(null);
        expect(service.available(CreditKind.superLike), 15);
      },
    );

    test('une panne réseau garde le dernier solde connu', () async {
      await service.refresh();
      api.onGet = () => throw const SocketLikeException();

      await service.refresh();

      expect(service.available(CreditKind.superLike), 15);
    });

    test('un 500 garde le dernier solde connu', () async {
      await service.refresh();
      api.onGet = () => const ApiReply(500);
      await service.refresh();
      expect(service.available(CreditKind.superLike), 15);
    });

    test('un 401 efface le solde : la session n\'est plus la bonne', () async {
      await service.refresh();
      api.onGet = () => ApiReply(401, errorEnvelope('unauthorized'));
      await service.refresh();
      expect(service.balance, isNull);
    });

    test('onSignedOut vide le solde et prévient', () async {
      await service.refresh();
      var notified = 0;
      service.addListener(() => notified++);

      service.onSignedOut();

      expect(service.balance, isNull);
      expect(service.available(CreditKind.boost), 0);
      expect(notified, 1);
    });
  });

  group('loadPacks', () {
    test(
      'les deux packs du type, au prix du store, du plus petit au plus grand',
      () async {
        final packs = await service.loadPacks(CreditKind.boost);

        expect(gateway.queried.single, {
          'com.mazl.app.boost.1',
          testBoostPackId,
        });
        expect(packs.map((p) => p.product.id), [
          'com.mazl.app.boost.1',
          testBoostPackId,
        ]);
        expect(packs.map((p) => p.quantity), [1, 3]);
        expect(packs.last.price, 4.99);
        expect(packs.last.currencyCode, 'EUR');
        expect(packs.first.kind, CreditKind.boost);
      },
    );

    test('les Super Likes ont leurs propres packs', () async {
      final packs = await service.loadPacks(CreditKind.superLike);
      expect(packs.map((p) => p.quantity), [5, 15]);
    });

    test(
      'un produit que le store rend mais qui n\'est pas du type : ignoré',
      () async {
        gateway.productResponse = ProductDetailsResponse(
          productDetails: [
            storeProduct(testSuperLikePackId),
            storeProduct('com.mazl.app.plus.1m'),
            storeProduct(testBoostPackId),
          ],
          notFoundIDs: const [],
        );
        final packs = await service.loadPacks(CreditKind.boost);
        expect(packs.map((p) => p.product.id), [testBoostPackId]);
      },
    );

    test('store indisponible : liste vide, sans exception', () async {
      gateway.available = false;
      expect(await service.loadPacks(CreditKind.boost), isEmpty);
    });

    test('le store échoue : liste vide, sans exception', () async {
      gateway.productResponse = ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [testBoostPackId],
        error: IAPError(source: 'app_store', code: 'x', message: 'boom'),
      );
      expect(await service.loadPacks(CreditKind.boost), isEmpty);
    });
  });

  group('achat', () {
    test('200 : le JWS part tel quel, le solde vient du serveur, et '
        'completePurchase n\'est appelé QU\'APRÈS la réponse', () async {
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);
      final pack = await _boostPack(service);

      final result = await service.buyPack(pack);

      expect(result, isA<PurchaseSucceeded>());
      expect(
        gateway.boughtConsumables.single.productDetails.id,
        pack.product.id,
      );
      expect(api.verifyBodies, [
        {'signedTransaction': 'JWS-2000000456'},
      ]);
      expect(service.balance!.boost.purchasedBalance, 5);
      expect(storeJournal, ['credits-verify', 'complete:2000000456']);
    });

    test('200 « déjà crédité » (credited: false) : succès, terminé', () async {
      api.onVerify = () async => ApiReply(200, verifyEnvelope(credited: false));
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect(result, isA<PurchaseSucceeded>());
      expect(gateway.completed, hasLength(1));
    });

    test('200 sans credits lisible : terminé, et le solde est relu', () async {
      api.onVerify = () async => ApiReply(200, {
        'success': true,
        'credited': true,
        'kind': 'boost',
        'quantity': 3,
      });
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect(result, isA<PurchaseSucceeded>());
      expect(gateway.completed, hasLength(1));
      expect(api.getCalls, 1);
    });

    test('409 : refus définitif, la transaction est terminée', () async {
      api.onVerify = () async =>
          ApiReply(409, errorEnvelope('transaction_owned_by_another_user'));
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect(
        (result as PurchaseFailed).problem,
        PurchaseProblem.ownedByAnotherAccount,
      );
      expect(gateway.completed, hasLength(1));
      expect(storeJournal, ['credits-verify', 'complete:2000000456']);
    });

    test(
      '422 : refus corrigeable, la transaction n\'est PAS terminée',
      () async {
        api.onVerify = () async =>
            ApiReply(422, errorEnvelope('invalid_transaction'));
        gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

        final result = await service.buyPack(await _boostPack(service));

        expect(
          (result as PurchaseFailed).problem,
          PurchaseProblem.invalidTransaction,
        );
        expect(gateway.completed, isEmpty);
      },
    );

    test('400 : la transaction n\'est PAS terminée', () async {
      api.onVerify = () async => ApiReply(400, errorEnvelope('invalid_body'));
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect((result as PurchaseFailed).problem, PurchaseProblem.invalidBody);
      expect(gateway.completed, isEmpty);
    });

    test('401 : pas terminée, rejouée après la connexion suivante', () async {
      api.onVerify = () async => ApiReply(401, errorEnvelope('unauthorized'));
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect((result as PurchaseFailed).problem, PurchaseProblem.signInAgain);
      expect(gateway.completed, isEmpty);
      expect(api.verifyBodies, hasLength(1));

      api.onVerify = () async => ApiReply(200, verifyEnvelope());
      await service.onSignedIn('nouveau-jwt');

      expect(api.verifyBodies, hasLength(2));
      expect(api.verifyBodies.last, {'signedTransaction': 'JWS-2000000456'});
      expect(gateway.completed.single.purchaseID, '2000000456');
      expect(service.balance!.boost.purchasedBalance, 5);
    });

    test(
      'réseau coupé : pas terminée, rejouée à la connexion suivante',
      () async {
        api.onVerify = () async => throw const SocketLikeException();
        gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

        final result = await service.buyPack(await _boostPack(service));

        expect((result as PurchaseFailed).problem, PurchaseProblem.offline);
        expect(gateway.completed, isEmpty);

        api.onVerify = () async => ApiReply(200, verifyEnvelope());
        await service.onSignedIn('jwt-de-test');

        expect(api.verifyBodies, hasLength(2));
        expect(gateway.completed, hasLength(1));
      },
    );

    test('un 503 est traité comme une panne : rejoué', () async {
      api.onVerify = () async => const ApiReply(503);
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);

      final result = await service.buyPack(await _boostPack(service));

      expect((result as PurchaseFailed).problem, PurchaseProblem.offline);
      api.onVerify = () async => ApiReply(200, verifyEnvelope());
      await service.onSignedIn('jwt-de-test');
      expect(gateway.completed, hasLength(1));
    });

    test('la déconnexion oublie les achats à rejouer', () async {
      api.onVerify = () async => ApiReply(401, errorEnvelope('unauthorized'));
      gateway.onBuy = _delivers(service, PurchaseStatus.purchased);
      await service.buyPack(await _boostPack(service));

      service.onSignedOut();
      api.onVerify = () async => ApiReply(200, verifyEnvelope());
      await service.onSignedIn('autre-compte');

      expect(api.verifyBodies, hasLength(1));
      expect(gateway.completed, isEmpty);
    });

    test(
      'annulé par l\'utilisateur : issue normale, rien n\'est vérifié',
      () async {
        gateway.onBuy = _delivers(service, PurchaseStatus.canceled);

        final result = await service.buyPack(await _boostPack(service));

        expect(result, isA<PurchaseCancelled>());
        expect(api.verifyBodies, isEmpty);
      },
    );

    test(
      'annulation levée par le plugin : une annulation, pas une erreur',
      () async {
        gateway.buyError = PlatformException(
          code: 'storekit2_purchase_cancelled',
          message: 'cancelled',
        );
        final result = await service.buyPack(await _boostPack(service));
        expect(result, isA<PurchaseCancelled>());
      },
    );

    test('Ask to Buy : en attente', () async {
      gateway.onBuy = _delivers(service, PurchaseStatus.pending);
      final result = await service.buyPack(await _boostPack(service));
      expect(result, isA<PurchasePending>());
      expect(api.verifyBodies, isEmpty);
    });

    test('délai dépassé sans nouvelle du store : en attente', () async {
      final slow = _service(
        gateway,
        api,
        purchaseSettleTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(slow.dispose);
      final result = await slow.buyPack(await _boostPack(slow));
      expect(result, isA<PurchasePending>());
    });

    test(
      'erreur du store : échec général, la transaction est terminée',
      () async {
        gateway.onBuy = (_) => service.handlePurchase(
          purchaseDetails(
            PurchaseStatus.error,
            id: '2000000456',
            productId: testBoostPackId,
            error: IAPError(source: 'app_store', code: 'x', message: 'boom'),
          ),
        );
        final result = await service.buyPack(await _boostPack(service));
        expect((result as PurchaseFailed).problem, PurchaseProblem.generic);
        expect(gateway.completed, hasLength(1));
      },
    );

    test(
      'un achat laissé de la session précédente (sans buyPack) est crédité',
      () async {
        await service.handlePurchase(
          purchaseDetails(
            PurchaseStatus.restored,
            id: '2000000999',
            jws: 'JWS-2000000999',
            productId: testSuperLikePackId,
          ),
        );

        expect(api.verifyBodies, [
          {'signedTransaction': 'JWS-2000000999'},
        ]);
        expect(gateway.completed.single.purchaseID, '2000000999');
      },
    );

    test('le même purchaseID livré deux fois : UN seul POST', () async {
      final gate = Completer<ApiReply>();
      api.onVerify = () => gate.future;
      final purchase = purchaseDetails(
        PurchaseStatus.purchased,
        id: '2000000777',
        jws: 'JWS-2000000777',
        productId: testBoostPackId,
      );

      final first = service.handlePurchase(purchase);
      final second = service.handlePurchase(purchase);
      await Future<void>.delayed(Duration.zero);
      expect(api.verifyBodies, hasLength(1));

      gate.complete(ApiReply(200, verifyEnvelope()));
      await Future.wait([first, second]);

      expect(api.verifyBodies, hasLength(1));
      expect(gateway.completed, hasLength(1));
    });

    test('un second achat pendant le premier : refusé proprement', () async {
      final quick = _service(
        gateway,
        api,
        purchaseSettleTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(quick.dispose);
      final pack = await _boostPack(quick);
      final first = quick.buyPack(pack);
      await Future<void>.delayed(Duration.zero);

      final second = await quick.buyPack(pack);

      expect(
        (second as PurchaseFailed).problem,
        PurchaseProblem.purchaseInProgress,
      );
      expect(await first, isA<PurchasePending>());
    });

    test('Android : achat désactivé, comme pour les abonnements', () async {
      final android = _service(gateway, api, platform: TargetPlatform.android);
      addTearDown(android.dispose);
      expect(android.canPurchase, isFalse);
      expect(android.unavailablePurchaseProblem, PurchaseProblem.androidSoon);
      final pack = await _boostPack(android);

      final result = await android.buyPack(pack);

      expect((result as PurchaseFailed).problem, PurchaseProblem.androidSoon);
      expect(gateway.boughtConsumables, isEmpty);
    });

    test('iOS : l\'achat est permis', () {
      expect(service.canPurchase, isTrue);
      expect(service.unavailablePurchaseProblem, isNull);
    });
  });

  test('le service démarre le flux d\'achats avant d\'acheter', () async {
    var started = 0;
    final withStream = CreditsService.create(
      gateway: gateway,
      api: api,
      platform: TargetPlatform.iOS,
    )..attachPurchaseStream(() async => started++);
    addTearDown(withStream.dispose);
    gateway.onBuy = _delivers(withStream, PurchaseStatus.canceled);

    await withStream.buyPack(await _boostPack(withStream));

    expect(started, 1);
  });
}

/// Une panne de réseau, sans dépendre de `dart:io`.
class SocketLikeException implements Exception {
  const SocketLikeException();
}
