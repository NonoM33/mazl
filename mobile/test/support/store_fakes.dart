import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/store_gateway.dart';
import 'package:mazl/core/services/store/subscription_api.dart';

const testProductId = 'com.mazl.app.plus.1m';
const testVerifyPath = '/api/subscriptions/apple/verify';
const testSubscriptionPath = '/api/subscription';

/// Journal commun aux deux faux : l'ordre des appels est ce qu'on vérifie.
final List<String> storeJournal = [];

/// « Maintenant » fixe : 1er novembre 2026.
final DateTime testNow = DateTime.utc(2026, 11, 1, 12);

Map<String, Object?> activeSubscriptionBody({
  String expiresAt = '2026-12-01T12:00:00.000Z',
}) => {
  'success': true,
  'subscription': {
    'plan_type': 'plus',
    'status': 'active',
    'expires_at': expiresAt,
    'product_id': testProductId,
  },
};

const Map<String, Object?> noSubscriptionBody = {
  'success': true,
  'subscription': null,
};

PurchaseDetails purchaseDetails(
  PurchaseStatus status, {
  String id = '2000000123',
  String jws = 'JWS-2000000123',
  IAPError? error,
}) {
  final d = PurchaseDetails(
    purchaseID: id,
    productID: testProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: jws,
      source: 'app_store',
    ),
    transactionDate: '1793448000000',
    status: status,
  );
  d.error = error;
  d.pendingCompletePurchase = status != PurchaseStatus.pending;
  return d;
}

ProductDetails storeProduct(
  String id, {
  double price = 14.99,
  String currency = 'EUR',
}) => ProductDetails(
  id: id,
  title: 'mazl+ 1 mois',
  description: 'Abonnement mazl+',
  price: '14,99 €',
  rawPrice: price,
  currencyCode: currency,
);

class FakeStoreGateway implements StoreGateway {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  ProductDetailsResponse productResponse = ProductDetailsResponse(
    productDetails: [storeProduct(testProductId)],
    notFoundIDs: const [],
  );
  Object? buyError;

  /// Ce que le « store » fait quand on lance un achat.
  Future<void> Function(PurchaseParam param)? onBuy;

  /// Ce que le « store » fait quand on restaure.
  Future<void> Function()? onRestore;

  final List<PurchaseParam> bought = [];
  final List<PurchaseDetails> completed = [];
  int restoreCalls = 0;

  void emit(PurchaseDetails d) => controller.add([d]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      productResponse;

  @override
  Future<bool> buyNonConsumable(PurchaseParam param) async {
    bought.add(param);
    final error = buyError;
    if (error != null) throw error;
    final handler = onBuy;
    if (handler != null) {
      unawaited(
        Future<void>.delayed(Duration.zero).then((_) => handler(param)),
      );
    }
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    final handler = onRestore;
    if (handler != null) {
      unawaited(Future<void>.delayed(Duration.zero).then((_) => handler()));
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    storeJournal.add('complete:${purchase.purchaseID}');
    completed.add(purchase);
  }
}

class FakeSubscriptionApi implements SubscriptionApi {
  ApiReply Function() onVerify = () => ApiReply(200, activeSubscriptionBody());
  ApiReply Function() onGetSubscription = () =>
      const ApiReply(200, noSubscriptionBody);
  final List<Map<String, Object?>> verifyBodies = [];
  int getCalls = 0;

  @override
  Future<ApiReply> get(String path) async {
    if (path != testSubscriptionPath) {
      throw StateError('GET inattendu : $path');
    }
    getCalls++;
    storeJournal.add('get');
    return onGetSubscription();
  }

  @override
  Future<ApiReply> post(String path, Map<String, Object?> body) async {
    if (path != testVerifyPath) {
      throw StateError('POST inattendu : $path');
    }
    verifyBodies.add(body);
    storeJournal.add('verify');
    return onVerify();
  }
}
