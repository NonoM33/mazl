import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/subscription_api.dart';

import 'store_fakes.dart';

const testCreditsPath = '/api/credits';
const testCreditsVerifyPath = '/api/credits/apple/verify';
const testBoostPackId = 'com.mazl.app.boost.3';
const testSuperLikePackId = 'com.mazl.app.superlikes.5';

/// Le `credits` du serveur (`src/features/credits/domain/view.ts`), recopié de
/// la forme du contrat `docs/premium/CREDITS.md`, jamais de notre code Dart.
Map<String, Object?> serverCredits({
  int superLikeAllowance = 5,
  int superLikeRemaining = 3,
  int superLikePurchased = 12,
  int boostAllowance = 1,
  int boostRemaining = 0,
  int boostPurchased = 2,
}) => {
  'super_like': <String, Object?>{
    'daily_allowance': superLikeAllowance,
    'daily_remaining': superLikeRemaining,
    'purchased_balance': superLikePurchased,
    'available': superLikeRemaining + superLikePurchased.clamp(0, 1 << 30),
  },
  'boost': <String, Object?>{
    'daily_allowance': boostAllowance,
    'daily_remaining': boostRemaining,
    'purchased_balance': boostPurchased,
    'available': boostRemaining + boostPurchased.clamp(0, 1 << 30),
  },
  'resets_at': '2026-11-02T00:00:00.000Z',
};

/// Réponse de `GET /api/credits`.
Map<String, Object?> creditsEnvelope({Map<String, Object?>? credits}) => {
  'success': true,
  'credits': credits ?? serverCredits(),
};

/// Réponse 200 de `POST /api/credits/apple/verify`.
Map<String, Object?> verifyEnvelope({
  bool credited = true,
  String kind = 'boost',
  int quantity = 3,
  Map<String, Object?>? credits,
}) => {
  'success': true,
  'credited': credited,
  'kind': kind,
  'quantity': quantity,
  'credits': credits ?? serverCredits(boostPurchased: 5),
};

/// Les erreurs du serveur : `{ success: false, error: <code> }`.
Map<String, Object?> errorEnvelope(String code) => {
  'success': false,
  'error': code,
};

/// Le serveur de crédits : ne répond qu'aux VRAIS chemins.
class FakeCreditsApi implements SubscriptionApi {
  ApiReply Function() onGet = () => ApiReply(200, creditsEnvelope());
  Future<ApiReply> Function() onVerify = () async =>
      ApiReply(200, verifyEnvelope());

  final List<Map<String, Object?>> verifyBodies = [];
  int getCalls = 0;

  @override
  Future<ApiReply> get(String path) async {
    if (path != testCreditsPath) throw StateError('GET inattendu : $path');
    getCalls++;
    storeJournal.add('credits-get');
    return onGet();
  }

  @override
  Future<ApiReply> post(String path, Map<String, Object?> body) async {
    if (path != testCreditsVerifyPath) {
      throw StateError('POST inattendu : $path');
    }
    verifyBodies.add(body);
    storeJournal.add('credits-verify');
    return onVerify();
  }
}

/// Installe un `CreditsService` de test comme singleton (celui que lisent
/// `PremiumGate`, `ApiService` et les écrans) et le retire à la fin du test.
/// Le service n'a PAS de session : son solde ne bouge que par
/// `applyFromServer`, ou par `onSignedIn` si le test le demande.
CreditsService installTestCredits({
  FakeStoreGateway? gateway,
  FakeCreditsApi? api,
  TargetPlatform platform = TargetPlatform.iOS,
}) {
  final service = CreditsService.create(
    gateway: gateway ?? FakeStoreGateway(),
    api: api ?? FakeCreditsApi(),
    platform: platform,
  );
  final previous = CreditsService.debugReplaceShared(service);
  addTearDown(() {
    CreditsService.debugReplaceShared(previous);
    service.dispose();
  });
  return service;
}
