import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/subscription_models.dart';
import 'package:mazl/core/services/store/subscription_service.dart';

import '../../../support/credits_fakes.dart';
import '../../../support/store_fakes.dart';

/// Le flux d'achats est UNIQUE : `SubscriptionService` reçoit tout et confie
/// les consommables au `CreditsService`.
void main() {
  late FakeStoreGateway gateway;
  late FakeSubscriptionApi subscriptionApi;
  late FakeCreditsApi creditsApi;
  late SubscriptionService subscriptions;
  late CreditsService credits;

  setUp(() async {
    storeJournal.clear();
    gateway = FakeStoreGateway()
      ..productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct('com.mazl.app.boost.1', price: 1.99),
          storeProduct(testBoostPackId, price: 4.99),
        ],
        notFoundIDs: const [],
      );
    subscriptionApi = FakeSubscriptionApi();
    creditsApi = FakeCreditsApi();
    credits = CreditsService.create(
      gateway: gateway,
      api: creditsApi,
      platform: TargetPlatform.iOS,
    );
    subscriptions = SubscriptionService.create(
      gateway: gateway,
      api: subscriptionApi,
      platform: TargetPlatform.iOS,
      now: () => testNow,
      consumables: credits,
    );
    credits.attachPurchaseStream(subscriptions.initialize);
    await subscriptions.onSignedIn('jwt');
    await credits.onSignedIn('jwt');
    storeJournal.clear();
  });

  tearDown(() async {
    subscriptions.dispose();
    credits.dispose();
    await gateway.controller.close();
  });

  Future<void> deliver(PurchaseDetails purchase) async {
    gateway.emit(purchase);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('un consommable du flux part vers credits/verify, pas vers '
      'subscriptions/verify', () async {
    await subscriptions.initialize();

    await deliver(
      purchaseDetails(
        PurchaseStatus.purchased,
        id: '2000000555',
        jws: 'JWS-CONSOMMABLE',
        productId: testBoostPackId,
      ),
    );

    expect(creditsApi.verifyBodies, [
      {'signedTransaction': 'JWS-CONSOMMABLE'},
    ]);
    expect(subscriptionApi.verifyBodies, isEmpty);
    expect(subscriptions.isMazlPro, isFalse);
    expect(gateway.completed.single.purchaseID, '2000000555');
    expect(credits.balance!.boost.purchasedBalance, 5);
  });

  test('un abonnement du flux part vers subscriptions/verify, pas vers '
      'credits/verify', () async {
    await subscriptions.initialize();

    await deliver(purchaseDetails(PurchaseStatus.purchased));

    expect(subscriptionApi.verifyBodies, [
      {'signedTransaction': 'JWS-2000000123'},
    ]);
    expect(creditsApi.verifyBodies, isEmpty);
    expect(subscriptions.isMazlPro, isTrue);
  });

  test('les deux ensemble : chaque achat va à son propriétaire', () async {
    await subscriptions.initialize();

    gateway.controller.add([
      purchaseDetails(PurchaseStatus.purchased),
      purchaseDetails(
        PurchaseStatus.purchased,
        id: '2000000556',
        jws: 'JWS-CONSOMMABLE',
        productId: 'com.mazl.app.boost.1',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(subscriptionApi.verifyBodies, hasLength(1));
    expect(creditsApi.verifyBodies, hasLength(1));
  });

  test('buyPack aboutit par le flux unique, sans second écouteur', () async {
    gateway.onBuy = (param) async => gateway.emit(
      purchaseDetails(
        PurchaseStatus.purchased,
        id: '2000000557',
        jws: 'JWS-ACHAT',
        productId: param.productDetails.id,
      ),
    );
    final packs = await credits.loadPacks(CreditKind.boost);

    final result = await credits.buyPack(packs.last);

    expect(result, isA<PurchaseSucceeded>());
    expect(creditsApi.verifyBodies.single, {'signedTransaction': 'JWS-ACHAT'});
    expect(subscriptionApi.verifyBodies, isEmpty);
    expect(gateway.completed.single.purchaseID, '2000000557');
  });

  test('un consommable en erreur est terminé par le CreditsService', () async {
    await subscriptions.initialize();

    await deliver(
      purchaseDetails(
        PurchaseStatus.error,
        id: '2000000558',
        productId: testBoostPackId,
        error: IAPError(source: 'app_store', code: 'x', message: 'boom'),
      ),
    );

    expect(gateway.completed.single.purchaseID, '2000000558');
    expect(creditsApi.verifyBodies, isEmpty);
  });

  test('sans porte des consommables, un consommable est ignoré et gardé '
      '(non terminé) plutôt que vérifié comme un abonnement', () async {
    final otherGateway = FakeStoreGateway();
    addTearDown(otherGateway.controller.close);
    final alone = SubscriptionService.create(
      gateway: otherGateway,
      api: subscriptionApi,
      platform: TargetPlatform.iOS,
      now: () => testNow,
    );
    addTearDown(alone.dispose);
    await alone.initialize();

    otherGateway.emit(
      purchaseDetails(PurchaseStatus.purchased, productId: testBoostPackId),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(subscriptionApi.verifyBodies, isEmpty);
    expect(otherGateway.completed, isEmpty);
  });
}
