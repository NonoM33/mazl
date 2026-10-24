import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/presentation/features/boost/screens/boost_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';

/// Le serveur de Boosts : les réponses de `boost.routes.ts`.
class _BoostServer implements ApiService {
  _BoostServer({required this.credits});

  Map<String, Object?> credits;
  bool active = false;
  int activations = 0;

  BoostStatus get _status => BoostStatus(
    isActive: active,
    expiresAt: active ? DateTime.now().add(const Duration(minutes: 30)) : null,
    remainingBoosts: CreditBalance.fromJson(credits).boost.available,
    credits: CreditBalance.fromJson(credits),
  );

  @override
  Future<ApiResponse<BoostStatus>> getBoostStatus() async =>
      ApiResponse.success(_status);

  @override
  Future<ApiResponse<BoostStatus>> activateBoost() async {
    activations++;
    if (active) {
      return ApiResponse(
        success: false,
        errorKind: ApiErrorKind.boostAlreadyActive,
        errorCode: 'boost_already_active',
        statusCode: 409,
      );
    }
    final available = CreditBalance.fromJson(credits).boost.available;
    if (available <= 0) {
      return ApiResponse(
        success: false,
        errorKind: ApiErrorKind.creditsExhausted,
        errorCode: 'boosts_exhausted',
        statusCode: 402,
      );
    }
    credits = serverCredits(boostRemaining: 0, boostPurchased: available - 1);
    active = true;
    return ApiResponse.success(_status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_BoostServer: ${invocation.memberName}');
}

Future<void> _pump(WidgetTester tester, ApiService api) async {
  await pumpLocalized(
    tester,
    BoostScreen(apiService: api),
    size: const Size(360, 1600),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits(
      gateway: FakeStoreGateway()
        ..productResponse = ProductDetailsResponse(
          productDetails: [
            storeProduct('com.mazl.app.boost.1', price: 1.99),
            storeProduct(testBoostPackId, price: 4.99),
          ],
          notFoundIDs: const [],
        ),
    );
  });

  tearDown(PremiumGate.resetForTest);

  testWidgets(
    'le compte restant est celui du serveur (credits.boost.available)',
    (tester) async {
      await _pump(
        tester,
        _BoostServer(credits: serverCredits(boostPurchased: 4)),
      );

      expect(find.text('4 boosts restants'), findsOneWidget);
    },
  );

  testWidgets('BoostStatus.credits l\'emporte sur remaining_boosts', (
    tester,
  ) async {
    final api = _BoostServer(credits: serverCredits(boostPurchased: 4));
    final screenApi = _StaleRemaining(api);

    await _pump(tester, screenApi);

    expect(find.text('4 boosts restants'), findsOneWidget);
  });

  testWidgets('avec un crédit : le Boost s\'active, sans feuille', (
    tester,
  ) async {
    final api = _BoostServer(credits: serverCredits(boostPurchased: 2));
    await _pump(tester, api);

    await tester.tap(find.text('Activer le Boost'));
    await _settle(tester);

    expect(api.activations, 1);
    expect(
      find.text('Boost activé. Votre profil est maintenant en avant.'),
      findsOneWidget,
    );
    expect(find.text('Vous n’avez plus de Boost.'), findsNothing);
  });

  testWidgets('épuisé : la feuille « packs » s\'ouvre, rien n\'est activé', (
    tester,
  ) async {
    final api = _BoostServer(credits: serverCredits(boostPurchased: 0));
    await _pump(tester, api);
    expect(find.text('0 boost restant'), findsOneWidget);

    await tester.tap(find.text('Activer le Boost'));
    await _settle(tester);

    expect(api.activations, 0);
    expect(find.text('Vous n’avez plus de Boost.'), findsOneWidget);
    expect(find.text('3 Boosts'), findsOneWidget);
  });

  testWidgets('le serveur répond 402 malgré tout : la feuille s\'ouvre', (
    tester,
  ) async {
    final api = _BoostServer(credits: serverCredits(boostPurchased: 1));
    await _pump(tester, api);
    api.credits = serverCredits(boostPurchased: 0);

    await tester.tap(find.text('Activer le Boost'));
    await _settle(tester);

    expect(api.activations, 1);
    expect(find.text('Vous n’avez plus de Boost.'), findsOneWidget);
  });

  testWidgets('409 : le message traduit, pas la feuille', (tester) async {
    final api = _BoostServer(credits: serverCredits(boostPurchased: 1));
    await _pump(tester, api);
    api.active = true;

    await tester.tap(find.text('Activer le Boost'));
    await _settle(tester);

    expect(find.text('Un Boost est déjà en cours.'), findsOneWidget);
    expect(find.text('Vous n’avez plus de Boost.'), findsNothing);
  });
}

/// Un ancien serveur qui laisse un `remaining_boosts` périmé à côté du solde.
class _StaleRemaining implements ApiService {
  _StaleRemaining(this.inner);

  final _BoostServer inner;

  @override
  Future<ApiResponse<BoostStatus>> getBoostStatus() async {
    final status = inner._status;
    return ApiResponse.success(
      BoostStatus(isActive: false, remainingBoosts: 1, credits: status.credits),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_StaleRemaining: ${invocation.memberName}');
}
