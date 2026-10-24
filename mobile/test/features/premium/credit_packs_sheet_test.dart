import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/presentation/features/premium/widgets/credit_packs_sheet.dart';

import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';
import 'l10n/premium_l10n_harness.dart';

/// Les prix du store pour les quatre packs : 1,99 / 4,99 pour les Boosts,
/// 3,99 / 9,99 pour les Super Likes.
ProductDetailsResponse _storePrices({String currency = 'EUR'}) =>
    ProductDetailsResponse(
      productDetails: [
        storeProduct('com.mazl.app.boost.1', price: 1.99, currency: currency),
        storeProduct(testBoostPackId, price: 4.99, currency: currency),
        storeProduct(testSuperLikePackId, price: 3.99, currency: currency),
        storeProduct(
          'com.mazl.app.superlikes.15',
          price: 9.99,
          currency: currency,
        ),
      ],
      notFoundIDs: const [],
    );

class _Harness {
  _Harness({TargetPlatform platform = TargetPlatform.iOS}) {
    gateway = FakeStoreGateway()..productResponse = _storePrices();
    api = FakeCreditsApi();
    service = CreditsService.create(
      gateway: gateway,
      api: api,
      platform: platform,
      purchaseSettleTimeout: const Duration(milliseconds: 200),
    );
  }

  late final FakeStoreGateway gateway;
  late final FakeCreditsApi api;
  late final CreditsService service;
  CreditPacksOutcome? popped;
  bool didPop = false;

  Widget sheet({
    CreditKind kind = CreditKind.boost,
    bool isSubscriber = false,
  }) => Builder(
    builder: (context) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: CreditPacksSheet(
          kind: kind,
          isSubscriber: isSubscriber,
          service: service,
        ),
      ),
    ),
  );

  /// Ouvre la feuille depuis un bouton, pour voir ce qu'elle rend en se fermant.
  Widget opener({
    CreditKind kind = CreditKind.boost,
    bool isSubscriber = false,
  }) => Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          popped = await showModalBottomSheet<CreditPacksOutcome>(
            context: context,
            isScrollControlled: true,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: CreditPacksSheet(
                kind: kind,
                isSubscriber: isSubscriber,
                service: service,
              ),
            ),
          );
          didPop = true;
        },
        child: const Text('ouvrir'),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => storeJournal.clear());

  testWidgets('pendant le chargement : titre déjà là, indicateur nommé', (
    tester,
  ) async {
    final h = _Harness();
    final prices = Completer<void>();
    h.gateway.queryGate = prices.future;
    await pumpPlus(tester, h.sheet());

    expect(find.text('Vous n’avez plus de Boost.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Chargement des offres'), findsOneWidget);
    prices.complete();
    await _settle(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('les deux packs de Boosts, au prix du store, avec la quantité', (
    tester,
  ) async {
    final h = _Harness();
    await pumpPlus(tester, h.sheet());
    await _settle(tester);

    expect(find.text('BOOSTS'), findsOneWidget);
    expect(find.text('1 Boost'), findsOneWidget);
    expect(find.text('3 Boosts'), findsOneWidget);
    expect(findPlain('1,99 €'), findsOneWidget);
    expect(findPlain('4,99 €'), findsOneWidget);
    expect(find.text('5 Super Likes'), findsNothing);
    expect(h.gateway.queried.single, {'com.mazl.app.boost.1', testBoostPackId});
  });

  testWidgets('les deux packs de Super Likes', (tester) async {
    final h = _Harness();
    await pumpPlus(tester, h.sheet(kind: CreditKind.superLike));
    await _settle(tester);

    expect(find.text('Vous n’avez plus de Super Likes.'), findsOneWidget);
    expect(find.text('5 Super Likes'), findsOneWidget);
    expect(find.text('15 Super Likes'), findsOneWidget);
    expect(findPlain('3,99 €'), findsOneWidget);
    expect(findPlain('9,99 €'), findsOneWidget);
  });

  testWidgets('le prix suit la devise du store, pas un euro écrit en dur', (
    tester,
  ) async {
    final h = _Harness();
    h.gateway.productResponse = _storePrices(currency: 'USD');
    await pumpPlus(tester, h.sheet(), locale: const Locale('en'));
    await _settle(tester);

    expect(find.text('\$4.99'), findsOneWidget);
  });

  testWidgets('chaque ligne se lit en entier : quantité, prix, bouton', (
    tester,
  ) async {
    final h = _Harness();
    final handle = tester.ensureSemantics();
    await pumpPlus(tester, h.sheet());
    await _settle(tester);

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Acheter 3 Boosts pour 4,99')),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    expect(
      tester
          .getSemantics(find.text('Vous n’avez plus de Boost.'))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('toucher un pack lance l\'achat de CE produit, puis se ferme', (
    tester,
  ) async {
    final h = _Harness();
    h.gateway.onBuy = (param) => h.service.handlePurchase(
      purchaseDetails(
        PurchaseStatus.purchased,
        id: '2000000900',
        jws: 'JWS-2000000900',
        productId: param.productDetails.id,
      ),
    );
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.tap(find.text('3 Boosts'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      h.gateway.boughtConsumables.single.productDetails.id,
      testBoostPackId,
    );
    expect(h.api.verifyBodies.single, {'signedTransaction': 'JWS-2000000900'});
    expect(h.didPop, isTrue);
    expect(h.popped, CreditPacksOutcome.purchased);
  });

  testWidgets('achat annulé : la feuille reste, sans message d\'erreur', (
    tester,
  ) async {
    final h = _Harness();
    h.gateway.onBuy = (param) => h.service.handlePurchase(
      purchaseDetails(
        PurchaseStatus.canceled,
        productId: param.productDetails.id,
      ),
    );
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.tap(find.text('1 Boost'));
    await _settle(tester);

    expect(h.didPop, isFalse);
    expect(find.text('3 Boosts'), findsOneWidget);
    expect(find.textContaining('n’a pas pu'), findsNothing);
  });

  testWidgets('achat refusé par le serveur : le message est dans la feuille', (
    tester,
  ) async {
    final h = _Harness();
    h.api.onVerify = () async =>
        ApiReply(422, errorEnvelope('invalid_transaction'));
    h.gateway.onBuy = (param) => h.service.handlePurchase(
      purchaseDetails(
        PurchaseStatus.purchased,
        productId: param.productDetails.id,
      ),
    );
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.tap(find.text('3 Boosts'));
    await _settle(tester);

    expect(h.didPop, isFalse);
    expect(
      find.textContaining('Nous n’avons pas pu valider cet achat'),
      findsOneWidget,
    );
    expect(h.gateway.completed, isEmpty);
  });

  testWidgets('Ask to Buy : le message d\'attente, la feuille reste', (
    tester,
  ) async {
    final h = _Harness();
    h.gateway.onBuy = (param) => h.service.handlePurchase(
      purchaseDetails(
        PurchaseStatus.pending,
        productId: param.productDetails.id,
      ),
    );
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.tap(find.text('3 Boosts'));
    await _settle(tester);

    expect(
      find.textContaining('Achat en attente d’approbation'),
      findsOneWidget,
    );
  });

  testWidgets('Android : les packs s\'affichent mais l\'achat est désactivé, '
      'avec le même message que les abonnements', (tester) async {
    final h = _Harness(platform: TargetPlatform.android);
    final handle = tester.ensureSemantics();
    await pumpPlus(tester, h.sheet(), platform: TargetPlatform.android);
    await _settle(tester);

    expect(find.text('Bientôt disponible sur Android'), findsOneWidget);
    expect(find.text('3 Boosts'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Acheter 3 Boosts pour 4,99')),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);

    await tester.tap(find.text('3 Boosts'));
    await _settle(tester);
    expect(h.gateway.boughtConsumables, isEmpty);
    handle.dispose();
  });

  testWidgets('non-abonné : « Découvrir mazl+ » est proposé et le dit', (
    tester,
  ) async {
    final h = _Harness();
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    expect(find.bySemanticsLabel('Découvrir mazl+'), findsWidgets);
    await tester.tap(find.byType(ElevatedButton));
    await _settle(tester);

    expect(h.popped, CreditPacksOutcome.discoverPlus);
  });

  testWidgets('abonné : pas de lien vers mazl+', (tester) async {
    final h = _Harness();
    await pumpPlus(tester, h.sheet(isSubscriber: true));
    await _settle(tester);

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.bySemanticsLabel('Découvrir mazl+'), findsNothing);
    expect(find.text('Pas maintenant'), findsOneWidget);
  });

  testWidgets('« Pas maintenant » ferme sans rien acheter', (tester) async {
    final h = _Harness();
    await pumpPlus(tester, h.opener());
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.tap(find.text('Pas maintenant'));
    await _settle(tester);

    expect(h.didPop, isTrue);
    expect(h.popped, isNull);
    expect(h.gateway.boughtConsumables, isEmpty);
  });

  testWidgets(
    'store indisponible : un message, et « Réessayer » relit les prix',
    (tester) async {
      final h = _Harness();
      h.gateway.available = false;
      await pumpPlus(tester, h.sheet());
      await _settle(tester);

      expect(
        find.text(
          'La boutique n’est pas disponible pour le moment. Réessayez dans un instant.',
        ),
        findsOneWidget,
      );
      expect(find.text('3 Boosts'), findsNothing);

      h.gateway.available = true;
      await tester.tap(find.text('Réessayer'));
      await _settle(tester);

      expect(find.text('3 Boosts'), findsOneWidget);
      expect(find.textContaining('boutique'), findsNothing);
    },
  );

  group('toutes les langues, sans débordement à 360 px', () {
    for (final c in l10nCases) {
      for (final kind in CreditKind.values) {
        testWidgets('${c.name} ${kind.name}', (tester) async {
          final h = _Harness();
          await pumpPlus(
            tester,
            h.sheet(kind: kind),
            locale: c.locale,
            brightness: c.brightness,
          );
          await _settle(tester);

          // Sans texte français, et dans le bon sens de lecture.
          expectNoFrench(const [
            'Vous n’avez plus de Boost.',
            'Vous n’avez plus de Super Likes.',
            'Pas maintenant',
            'Découvrir mazl+',
          ]);
          final title = find.byWidgetPredicate(
            (w) => w is Text && (w.style?.fontSize ?? 0) == 32,
          );
          expect(title, findsOneWidget);
          expectDirection(tester, title, c);
          expect(find.textContaining(RegExp(r'\d[.,]\d{2}')), findsNWidgets(2));
        });
      }
    }
  });

  testWidgets(
    'en hébreu : la quantité est du côté du début, le prix de la fin',
    (tester) async {
      final h = _Harness();
      await pumpPlus(tester, h.sheet(), locale: const Locale('he'));
      await _settle(tester);

      expect(find.text('בוסט אחד'), findsOneWidget);
      expect(find.text('3 בוסטים'), findsOneWidget);
      final quantity = tester.getTopRight(find.text('3 בוסטים')).dx;
      final price = tester.getTopRight(find.textContaining('4.99')).dx;
      expect(quantity, greaterThan(price), reason: 'le début est à droite');
    },
  );
}
