import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/analytics/analytics_event.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/store_products.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/generated/app_localizations.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';
import 'package:mazl/presentation/features/premium/widgets/credit_packs_sheet.dart';

import '../../core/analytics/analytics_fakes.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';

/// What the measurement received, `name` or `name:property`.
List<String> _seen(FakeAnalyticsTransport transport) => [
  for (final batch in transport.batches)
    for (final queued in batch)
      [
        queued.event.name,
        ...queued.event.properties.values.map((v) => '$v'),
      ].join(':'),
];

class _Rig {
  _Rig() {
    analytics =
        Analytics(
            transport: transport,
            clock: FakeClock().call,
            periodicTimer: FakeTimers().call,
          )
          ..signedIn()
          ..consentLoaded(granted: true);
  }

  final transport = FakeAnalyticsTransport();
  late final Analytics analytics;

  Future<List<String>> events() async {
    await analytics.flush();
    return _seen(transport);
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
        child: MaterialApp(
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: home,
        ),
      ),
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => storeJournal.clear());

  group('the mazl+ offer', () {
    late FakeStoreGateway gateway;
    late SubscriptionService service;

    setUp(() async {
      gateway = FakeStoreGateway();
      service = SubscriptionService.create(
        gateway: gateway,
        api: FakeSubscriptionApi(),
        platform: TargetPlatform.iOS,
        now: () => testNow,
        restoreSettle: const Duration(milliseconds: 60),
        purchaseSettleTimeout: const Duration(milliseconds: 100),
      );
      await service.initialize();
      await service.onSignedIn('jwt-de-test');
    });

    tearDown(() async {
      service.dispose();
      await gateway.controller.close();
    });

    Widget offer() =>
        PremiumScreen(service: service, loadPlans: service.loadPlans);

    testWidgets('opening it is a paywall_viewed from "premium"', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.pump(tester, offer());
      await _settle(tester);
      expect(await rig.events(), ['paywall_viewed:premium']);
    });

    testWidgets('« Continuer » is purchase_started with the store product', (
      tester,
    ) async {
      gateway.onBuy = (_) async {};
      final rig = _Rig();
      await rig.pump(tester, offer());
      await _settle(tester);

      await tester.tap(find.textContaining('Continuer'));
      await tester.pump();
      await _settle(tester);

      expect(await rig.events(), [
        'paywall_viewed:premium',
        'purchase_started:$testProductId',
      ]);
    });

    testWidgets('a purchase the member abandons is purchase_cancelled', (
      tester,
    ) async {
      gateway.onBuy = (_) async =>
          gateway.emit(purchaseDetails(PurchaseStatus.canceled));
      final rig = _Rig();
      await rig.pump(tester, offer());
      await _settle(tester);

      await tester.tap(find.textContaining('Continuer'));
      await _settle(tester);

      expect(await rig.events(), [
        'paywall_viewed:premium',
        'purchase_started:$testProductId',
        'purchase_cancelled:$testProductId',
      ]);
    });
  });

  group('the credit packs', () {
    late FakeStoreGateway gateway;
    late FakeCreditsApi api;
    late CreditsService credits;

    setUp(() {
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
      credits = CreditsService.create(
        gateway: gateway,
        api: api,
        platform: TargetPlatform.iOS,
        purchaseSettleTimeout: const Duration(milliseconds: 200),
      );
    });

    Widget sheet(CreditKind kind) => Scaffold(
      body: SingleChildScrollView(
        child: CreditPacksSheet(
          kind: kind,
          isSubscriber: false,
          service: credits,
        ),
      ),
    );

    testWidgets('the Boost sheet is a paywall_viewed from boostPacks', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.pump(tester, sheet(CreditKind.boost));
      await _settle(tester);
      expect(await rig.events(), ['paywall_viewed:boostPacks']);
    });

    testWidgets(
      'the Super Like sheet is a paywall_viewed from superLikePacks',
      (tester) async {
        final rig = _Rig();
        await rig.pump(tester, sheet(CreditKind.superLike));
        await _settle(tester);
        expect(await rig.events(), ['paywall_viewed:superLikePacks']);
      },
    );

    testWidgets('a pack the member abandons: started, then cancelled', (
      tester,
    ) async {
      gateway.onBuy = (param) => credits.handlePurchase(
        purchaseDetails(
          PurchaseStatus.canceled,
          productId: param.productDetails.id,
        ),
      );
      final rig = _Rig();
      await rig.pump(tester, sheet(CreditKind.boost));
      await _settle(tester);

      await tester.tap(find.text('3 Boosts'));
      await _settle(tester);

      expect(await rig.events(), [
        'paywall_viewed:boostPacks',
        'purchase_started:$testBoostPackId',
        'purchase_cancelled:$testBoostPackId',
      ]);
    });
  });

  test('every product the app sells fits the format of the plan', () {
    final ids = [
      ...kSubscriptionProductIds,
      for (final product in kConsumableProducts) product.id,
    ];
    expect(ids, isNotEmpty);
    for (final id in ids) {
      expect(
        AnalyticsEvent.purchaseStarted(id),
        isNotNull,
        reason: '$id would be dropped',
      );
    }
  });
}
