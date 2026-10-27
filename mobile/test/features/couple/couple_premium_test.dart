import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/models/couple_daily.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/store/store_products.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_premium_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/store_fakes.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';

// A price nobody would write in the code: whatever the screen shows has to
// come from the store.
const _storePrice = '12,34 €';

ProductDetails _couple({String price = _storePrice}) => ProductDetails(
  id: kCoupleProductId,
  title: 'MAZL Couple',
  description: 'Abonnement MAZL Couple',
  price: price,
  rawPrice: 12.34,
  currencyCode: 'EUR',
);

/// A couple service that counts its refreshes and shows the subscription a
/// test wants.
class _SpyCouple extends CoupleService {
  _SpyCouple({this.shown = CouplePremium.inactive, this.partner})
    : super.forTesting(api: FakeCoupleApi());

  CouplePremium shown;
  final String? partner;
  int refreshes = 0;

  @override
  CouplePremium get premium => shown;

  @override
  CoupleData? get coupleData =>
      partner == null ? null : CoupleData(partnerName: partner);

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

AppLocalizations _l10n() => lookupAppLocalizations(kTestLocale);

class _Rig {
  _Rig({TargetPlatform platform = TargetPlatform.iOS, _SpyCouple? couple})
    : couple = couple ?? _SpyCouple() {
    gateway.productResponse = ProductDetailsResponse(
      productDetails: [_couple()],
      notFoundIDs: const [],
    );
    service = SubscriptionService.create(
      gateway: gateway,
      api: api,
      platform: platform,
      now: () => testNow,
      restoreSettle: Duration.zero,
      purchaseSettleTimeout: const Duration(seconds: 5),
      openUrl: (uri) async {
        opened.add(uri);
        return true;
      },
    );
  }

  final FakeStoreGateway gateway = FakeStoreGateway();
  final FakeSubscriptionApi api = FakeSubscriptionApi();
  final _SpyCouple couple;
  final List<Uri> opened = [];
  final List<Uri> links = [];
  late final SubscriptionService service;

  Future<void> dispose() async {
    service.dispose();
    await gateway.controller.close();
    couple.dispose();
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the page over a home page, like the app does, so that closing it
/// can be seen.
Future<void> _pump(
  WidgetTester tester,
  _Rig rig, {
  DuoPose? pose,
  Brightness brightness = Brightness.light,
  Locale locale = kTestLocale,
}) async {
  if (pose != null) {
    setDuoPose(tester, pose);
  } else {
    tester.view.physicalSize = const Size(500, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final controller = DuoPoseController(pose ?? DuoPose.openPortrait);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light
          ? AppTheme.lightTheme
          : AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: pose == null ? null : duoAppBuilder(controller),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => CouplePremiumScreen(
                    subscriptions: rig.service,
                    couple: rig.couple,
                    openUrl: (uri) async {
                      rig.links.add(uri);
                      return true;
                    },
                  ),
                ),
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await _settle(tester);
  await settleFold(tester);
}

FilledButton _subscribe(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, "S'abonner pour nous deux"),
);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the price', () {
    testWidgets('is the one the store gives', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      expect(find.text(_storePrice), findsOneWidget);
      expect(find.text('par mois'), findsOneWidget);
      expect(find.textContaining('29,99'), findsNothing);
      expect(rig.gateway.queried, [
        {kCoupleProductId},
      ]);
      expect(_subscribe(tester).onPressed, isNotNull);
    });

    testWidgets('another store price is shown as it comes', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.productResponse = ProductDetailsResponse(
        productDetails: [_couple(price: '\$9.87')],
        notFoundIDs: const [],
      );
      await _pump(tester, rig);

      expect(find.text('\$9.87'), findsOneWidget);
      expect(find.text(_storePrice), findsNothing);
    });

    testWidgets('a skeleton stands in while the store answers', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      final gate = Completer<void>();
      rig.gateway.queryGate = gate.future;
      await _pump(tester, rig);

      expect(find.byKey(const ValueKey('price-skeleton')), findsOneWidget);
      expect(find.text(_storePrice), findsNothing);
      expect(_subscribe(tester).onPressed, isNull);

      gate.complete();
      await _settle(tester);
      expect(find.byKey(const ValueKey('price-skeleton')), findsNothing);
      expect(find.text(_storePrice), findsOneWidget);
    });

    testWidgets('store unavailable: a sentence and a disabled button', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.available = false;
      await _pump(tester, rig);

      expect(
        find.text("Le prix s'affiche dès que l'App Store répond."),
        findsOneWidget,
      );
      expect(_subscribe(tester).onPressed, isNull);
    });

    testWidgets('the store does not know the product: same sentence', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.productResponse = ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [kCoupleProductId],
      );
      await _pump(tester, rig);

      expect(
        find.text("Le prix s'affiche dès que l'App Store répond."),
        findsOneWidget,
      );
      expect(_subscribe(tester).onPressed, isNull);
    });

    testWidgets('Android: soon, nothing is sold and the store is not asked', (
      tester,
    ) async {
      final rig = _Rig(platform: TargetPlatform.android);
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      expect(find.text('Bientôt disponible sur Android'), findsOneWidget);
      expect(_subscribe(tester).onPressed, isNull);
      expect(rig.gateway.queried, isEmpty);
    });
  });

  group('the offer', () {
    testWidgets('the headline, the five perks and the legal line', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      expect(find.text("Le plus dur, c'est de le garder."), findsOneWidget);
      for (final perk in [
        'Conciergerie',
        'Vos rituels et vos dates',
        'Sorties choisies pour vous',
        'La question du jour',
        'Le bilan du couple',
      ]) {
        expect(find.text(perk), findsOneWidget);
      }
      expect(find.text('POUR VOUS DEUX'), findsOneWidget);
      expect(
        find.text(
          "Un seul abonnement : l'autre en profite aussitôt, sans rien payer.",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'mazl+ est inclus pour vous deux tant que l\'abonnement couple est actif.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Renouvellement automatique'), findsOneWidget);
    });

    testWidgets('Conditions and Confidentialité open the site', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      await tester.tap(find.text('Conditions'));
      await tester.tap(find.text('Confidentialité'));
      await tester.pump();

      expect(rig.links, [
        Uri.parse('https://mazl.app/terms'),
        Uri.parse('https://mazl.app/privacy'),
      ]);
    });
  });

  group('buying', () {
    testWidgets('a successful purchase refreshes the couple, closes the page '
        'and confirms', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.onBuy = (param) async => rig.gateway.emit(
        purchaseDetails(PurchaseStatus.purchased, productId: kCoupleProductId),
      );
      await _pump(tester, rig);

      await tester.tap(find.text("S'abonner pour nous deux"));
      await _settle(tester);

      expect(rig.gateway.bought.single.productDetails.id, kCoupleProductId);
      expect(rig.api.verifyBodies, hasLength(1));
      expect(rig.couple.refreshes, 1);
      expect(find.text("Le plus dur, c'est de le garder."), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(
        find.text('MAZL Couple est actif pour vous deux.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling says nothing and keeps the page', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.onBuy = (param) async => rig.gateway.emit(
        purchaseDetails(PurchaseStatus.canceled, productId: kCoupleProductId),
      );
      await _pump(tester, rig);

      await tester.tap(find.text("S'abonner pour nous deux"));
      await _settle(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text("Le plus dur, c'est de le garder."), findsOneWidget);
      expect(rig.couple.refreshes, 0);
      // And the button is usable again.
      expect(_subscribe(tester).onPressed, isNotNull);
    });

    testWidgets('waiting for approval says so', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.onBuy = (param) async => rig.gateway.emit(
        purchaseDetails(PurchaseStatus.pending, productId: kCoupleProductId),
      );
      await _pump(tester, rig);

      await tester.tap(find.text("S'abonner pour nous deux"));
      await _settle(tester);

      expect(
        find.textContaining('Achat en attente d’approbation'),
        findsOneWidget,
      );
      expect(rig.couple.refreshes, 0);
    });

    testWidgets('a refused purchase explains why, in words', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.api.onVerify = () => const ApiReply(422);
      rig.gateway.onBuy = (param) async => rig.gateway.emit(
        purchaseDetails(PurchaseStatus.purchased, productId: kCoupleProductId),
      );
      await _pump(tester, rig);

      await tester.tap(find.text("S'abonner pour nous deux"));
      await _settle(tester);

      expect(find.text(_l10n().plusErrorInvalidTransaction), findsOneWidget);
      expect(find.text("Le plus dur, c'est de le garder."), findsOneWidget);
      expect(rig.couple.refreshes, 0);
    });
  });

  group('restoring', () {
    testWidgets('a restored purchase refreshes the couple and says so', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      rig.gateway.onRestore = () async => rig.gateway.emit(
        purchaseDetails(PurchaseStatus.restored, productId: kCoupleProductId),
      );
      await _pump(tester, rig);

      await tester.tap(find.text('Restaurer un achat'));
      await _settle(tester);

      expect(rig.gateway.restoreCalls, 1);
      expect(rig.couple.refreshes, 1);
      expect(find.text('Abonnement restauré'), findsOneWidget);
    });

    testWidgets('nothing to restore: the couple is still re-read', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      await tester.tap(find.text('Restaurer un achat'));
      await _settle(tester);

      expect(rig.gateway.restoreCalls, 1);
      expect(rig.couple.refreshes, 1);
      expect(find.text('Aucun abonnement trouvé'), findsOneWidget);
    });
  });

  group('already subscribed', () {
    testWidgets('the partner pays: who, and when it renews, no purchase', (
      tester,
    ) async {
      final rig = _Rig(
        couple: _SpyCouple(
          shown: CouplePremium(
            active: true,
            paidBy: CouplePayer.partner,
            renewsAt: DateTime(2026, 12, 1, 12),
          ),
          partner: 'David',
        ),
      );
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      expect(find.text('MAZL Couple est actif'), findsOneWidget);
      expect(find.text('Payé par David'), findsOneWidget);
      expect(find.text('Renouvelé le 1er décembre 2026'), findsOneWidget);
      expect(find.text("S'abonner pour nous deux"), findsNothing);
      expect(find.text('Restaurer un achat'), findsNothing);
      expect(find.text("Gérer l'abonnement"), findsNothing);
      expect(find.text(_storePrice), findsNothing);
    });

    testWidgets('I pay: Gérer l\'abonnement opens the App Store settings', (
      tester,
    ) async {
      final rig = _Rig(
        couple: _SpyCouple(
          shown: CouplePremium(
            active: true,
            paidBy: CouplePayer.me,
            renewsAt: DateTime(2026, 12, 15, 12),
          ),
          partner: 'David',
        ),
      );
      addTearDown(rig.dispose);
      await _pump(tester, rig);

      expect(find.text('Payé par vous'), findsOneWidget);
      expect(find.text('Renouvelé le 15 décembre 2026'), findsOneWidget);

      await tester.tap(find.text("Gérer l'abonnement"));
      await tester.pump();

      expect(rig.opened.single.toString(), contains('account/subscriptions'));
    });
  });

  group('iPhone Duo', () {
    testWidgets('book: the argument on the first page, the price and the '
        'buttons on the other, the close in the column', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig, pose: DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;
      Rect rect(String text) => tester.getRect(find.text(text).first);

      expect(
        rect("Le plus dur, c'est de le garder.").right,
        lessThanOrEqualTo(fold.left),
      );
      expect(rect('Le bilan du couple').right, lessThanOrEqualTo(fold.left));
      expect(rect(_storePrice).left, greaterThanOrEqualTo(fold.right));
      // The main button is on screen, with no scrolling.
      expect(
        rect("S'abonner pour nous deux").left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        rect("S'abonner pour nous deux").bottom,
        lessThan(DuoPose.halfOpenBook.safeRect.bottom),
      );
      expect(
        DuoPose.halfOpenBook.verticalBar!.controls
            .inflate(0.5)
            .contains(tester.getCenter(find.byType(CloseButton))),
        isTrue,
        reason: 'the close is not in the vertical bar',
      );
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expect(tappableProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('open landscape: the buttons are on screen', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig, pose: DuoPose.openLandscape);

      final button = tester.getRect(find.text("S'abonner pour nous deux"));
      expect(button.bottom, lessThan(DuoPose.openLandscape.safeRect.bottom));
      expect(tappableProblems(tester, DuoPose.openLandscape), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('laptop: nothing in the fold', (tester) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(tester, rig, pose: DuoPose.halfOpenLaptop);

      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expect(tappableProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: renders in the closed pose without overflow', (
      tester,
    ) async {
      final rig = _Rig();
      addTearDown(rig.dispose);
      await _pump(
        tester,
        rig,
        pose: DuoPose.closed,
        brightness: Brightness.dark,
      );

      expect(tappableProblems(tester, DuoPose.closed), isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final pose in DuoPose.values) {
      testWidgets('offer and subscribed states fit ${pose.name}', (
        tester,
      ) async {
        final rig = _Rig();
        addTearDown(rig.dispose);
        await _pump(tester, rig, pose: pose);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(tester.takeException(), isNull);

        rig.couple
          ..shown = const CouplePremium(active: true, paidBy: CouplePayer.me)
          ..notifyListeners();
        await _settle(tester);
        final manage = find.text("Gérer l'abonnement");
        if (manage.evaluate().isEmpty) {
          // One column: the button is below the argument.
          await tester.scrollUntilVisible(
            manage,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          // Then to the end of the page, where its bottom margin is.
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2000),
          );
          await _settle(tester);
        }
        expect(manage, findsOneWidget);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    for (final code in ['en', 'he', 'es', 'ru']) {
      for (final pose in [DuoPose.closed, DuoPose.halfOpenBook]) {
        testWidgets('premium in $code fits ${pose.name}', (tester) async {
          final rig = _Rig();
          addTearDown(rig.dispose);
          await _pump(tester, rig, pose: pose, locale: Locale(code));
          expect(foldCrossingProblems(tester, pose), isEmpty);
          expect(tappableProblems(tester, pose), isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
