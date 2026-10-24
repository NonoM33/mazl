import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart'
    show ProfilePhoto;
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart'
    show PlusCtaButton;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/swipe_gestures.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';
import '../../mocks/fake_discover_api.dart';
import '../../helpers/l10n_helpers.dart';

const _likeLimitTitle = 'Vos likes du jour sont partis.';
const _superLikeGateTitle = 'Vous n’avez plus de Super Likes.';
const _boostGateTitle = 'Vous n’avez plus de Boost.';

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

/// The store the packs sheet reads its prices from (and the « server » the
/// purchase is verified by), shared by the tests of this file.
late FakeStoreGateway _store;
late FakeCreditsApi _creditsApi;
late CreditsService _credits;

Future<FakeDiscoverApi> _pumpDiscover(
  WidgetTester tester, {
  List<String> photos = const [],
  bool verified = false,
  int superLikes = 1,
  int boosts = 0,
  bool boostActive = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = FakeDiscoverApi(
    discoverProfiles(3, photos: photos, verified: verified),
    superLikes: superLikes,
    boosts: boosts,
    boostActive: boostActive,
  );
  // What the server told the app when the member signed in.
  _credits.applyFromServer(
    serverCredits(
      superLikeAllowance: 1,
      superLikeRemaining: superLikes,
      superLikePurchased: 0,
      boostAllowance: 0,
      boostRemaining: 0,
      boostPurchased: boosts,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      // As in the app: the iPhone's Reduce Motion reaches the screen here.
      builder: (context, child) => ReduceMotionScope(child: child!),
      home: DiscoverScreen(apiService: api),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return api;
}

/// Drags the card by [by], releases, and watches the next two seconds: the
/// card must stay mounted (same State), never travel farther from its place
/// than where it was released, and the gate must only open once it is back.
Future<void> _releaseRefusedAndWatch(
  WidgetTester tester,
  int userId,
  Offset by,
  String gateTitle,
) async {
  final stateAtStart = tester.state(_card(userId));
  final restCenter = tester.getCenter(_card(userId));
  final gesture = await tester.startGesture(restCenter);
  for (var i = 0; i < 10; i++) {
    await gesture.moveBy(by / 10);
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pump(const Duration(milliseconds: 200));
  final atRelease = (tester.getCenter(_card(userId)) - restCenter).distance;
  await gesture.up();

  double? gapWhenGateOpened;
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(_card(userId), findsOneWidget, reason: 'frame $i');
    expect(
      identical(tester.state(_card(userId)), stateAtStart),
      isTrue,
      reason: 'the card was unmounted and mounted again (frame $i)',
    );
    final gap = (tester.getCenter(_card(userId)) - restCenter).distance;
    expect(
      gap,
      lessThanOrEqualTo(atRelease + 1),
      reason: 'the card left the place it was released at (frame $i)',
    );
    if (gapWhenGateOpened == null &&
        find.text(gateTitle).evaluate().isNotEmpty) {
      gapWhenGateOpened = gap;
    }
  }
  expect(gapWhenGateOpened, isNotNull, reason: 'the gate never opened');
  expect(
    gapWhenGateOpened,
    lessThan(2),
    reason: 'the gate opened before the card was back',
  );
}

double _restX(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

void _expectAtRest(WidgetTester tester, Finder card) {
  expect(card, findsOneWidget);
  expect((tester.getCenter(card).dx - _restX(tester)).abs(), lessThan(1));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    storeJournal.clear();
    _store = FakeStoreGateway()
      ..productResponse = ProductDetailsResponse(
        productDetails: [
          storeProduct('com.mazl.app.boost.1', price: 1.99),
          storeProduct(testBoostPackId, price: 4.99),
          storeProduct(testSuperLikePackId, price: 3.99),
          storeProduct('com.mazl.app.superlikes.15', price: 9.99),
        ],
        notFoundIDs: const [],
      );
    _creditsApi = FakeCreditsApi();
    _credits = installTestCredits(gateway: _store, api: _creditsApi);
  });

  tearDown(PremiumGate.resetForTest);

  testWidgets(
    'the « Vérifiée » pill gives way to the like disc that lands on it',
    (tester) async {
      await _pumpDiscover(tester, verified: true);
      final pill = find.descendant(
        of: _card(101),
        matching: find.byKey(const Key('verified-pill')),
      );
      expect(tester.widget<Opacity>(pill).opacity, 1);

      final width = tester.getSize(_card(101)).width;
      final half = MazlMotion.deckThreshold * width / 2;
      final g = await holdDrag(tester, _card(101), Offset(half, 0));
      expect(tester.widget<Opacity>(pill).opacity, closeTo(0.5, 0.02));

      await g.moveBy(Offset(-2 * half, 0));
      await tester.pump();
      // Passing: the cross lands on the other corner, the pill stays.
      expect(tester.widget<Opacity>(pill).opacity, 1);
      await g.up();
      await settle(tester);
    },
  );

  testWidgets('a downward swipe does not consume the card and sends no swipe', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester);

    await dragSlowly(tester, _card(101), const Offset(0, 320));
    await settle(tester);

    _expectAtRest(tester, _card(101));
    expect(api.swipes, isEmpty);
  });

  testWidgets('a refused like springs back from where it is, stays mounted, '
      'and asks for the gate only once it is back', (tester) async {
    for (var i = 0; i < PremiumGate.freeLikesPerDay; i++) {
      PremiumGate.tryConsumeFreeLike();
    }
    final api = await _pumpDiscover(tester);

    await _releaseRefusedAndWatch(
      tester,
      101,
      const Offset(180, 0),
      _likeLimitTitle,
    );

    expect(api.swipes, isEmpty);
  });

  testWidgets('a super like with none left springs back, then opens the gate', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, superLikes: 0);
    expect(PremiumGate.remainingSuperLikes, 0);

    await _releaseRefusedAndWatch(
      tester,
      101,
      const Offset(0, -360),
      _superLikeGateTitle,
    );

    expect(api.swipes, isEmpty);
  });

  testWidgets('a refused super like goes up by itself once a pack is bought', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, superLikes: 0);
    // The purchase goes through the store; the server verifies it and says the
    // member now holds five Super Likes.
    _creditsApi.onVerify = () async => ApiReply(
      200,
      verifyEnvelope(
        kind: 'super_like',
        quantity: 5,
        credits: serverCredits(superLikeRemaining: 0, superLikePurchased: 5),
      ),
    );
    _store.onBuy = (param) async => _credits.handlePurchase(
      purchaseDetails(
        PurchaseStatus.purchased,
        productId: param.productDetails.id,
      ),
    );
    api.superLikes = 5;

    await dragSlowly(tester, _card(101), const Offset(0, -360));
    await settle(tester);
    expect(find.text(_superLikeGateTitle), findsWidgets);
    expect(api.swipes, isEmpty);

    await tester.tap(find.text('5 Super Likes'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);

    expect(
      _store.boughtConsumables.single.productDetails.id,
      testSuperLikePackId,
    );
    expect(api.swipes, ['101:super_like']);
    expect(_card(101), findsNothing);
    expect(_credits.balance!.superLike.available, 4);
  });

  testWidgets(
    'the sheet offers mazl+ to a free member, and not to a subscriber',
    (tester) async {
      await _pumpDiscover(tester, superLikes: 0);
      await tester.tap(find.bySemanticsLabel('Super like'));
      await settle(tester);
      expect(find.byType(PlusCtaButton), findsOneWidget);

      await tester.tap(find.text('Pas maintenant'));
      await settle(tester);
      PremiumGate.debugPremiumOverride = true;
      await tester.tap(find.bySemanticsLabel('Super like'));
      await settle(tester);
      expect(find.text(_superLikeGateTitle), findsWidgets);
      expect(find.byType(PlusCtaButton), findsNothing);
    },
  );

  testWidgets(
    'the server says 402 although the app thought it had one: the balance is '
    'read again and the sheet opens',
    (tester) async {
      final api = await _pumpDiscover(tester, superLikes: 1);
      api.refuseNextSuperLike = true;

      await dragSlowly(tester, _card(101), const Offset(0, -360));
      await settle(tester);

      expect(api.swipes, ['101:super_like']);
      expect(PremiumGate.remainingSuperLikes, 0);
      expect(find.text(_superLikeGateTitle), findsWidgets);
    },
  );

  testWidgets('the Boost button is not locked for a free member', (
    tester,
  ) async {
    await _pumpDiscover(tester, boosts: 1);
    final boosts = tester
        .widgetList<DiscoverMiniAction>(
          find.byWidgetPredicate(
            (w) => w is DiscoverMiniAction && w.tooltip == 'Boost',
          ),
        )
        .toList();
    expect(boosts, isNotEmpty);
    expect(boosts.every((b) => !b.locked), isTrue);
  });

  testWidgets('a Boost bought earlier is used by a free member', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, boosts: 2);

    await tester.tap(find.bySemanticsLabel('Boost'));
    await settle(tester);

    expect(api.boostActivations, 1);
    expect(find.textContaining('Boost activé'), findsOneWidget);
    expect(find.text(_boostGateTitle), findsNothing);
    expect(PremiumGate.remainingBoosts, 1);
  });

  testWidgets('no Boost left: the packs sheet opens and nothing is activated', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, boosts: 0);

    await tester.tap(find.bySemanticsLabel('Boost'));
    await settle(tester);

    expect(find.text(_boostGateTitle), findsOneWidget);
    expect(find.text('1 Boost'), findsOneWidget);
    expect(find.text('3 Boosts'), findsOneWidget);
    expect(api.boostActivations, 0);
  });

  testWidgets('a Boost already running: a message, nothing is debited', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, boosts: 2, boostActive: true);

    await tester.tap(find.bySemanticsLabel('Boost'));
    await settle(tester);

    expect(find.text('Un Boost est déjà en cours.'), findsOneWidget);
    expect(find.text(_boostGateTitle), findsNothing);
    expect(api.boosts, 2);
    expect(PremiumGate.remainingBoosts, 2);
  });

  testWidgets(
    'after the last card: « Vous avez tout vu. », its actions on one edge',
    (tester) async {
      await _pumpDiscover(tester);
      for (final id in [101, 102, 103]) {
        await dragSlowly(tester, _card(id), const Offset(-300, 0));
        await settle(tester);
      }

      final title = find.text('Vous avez tout vu.');
      expect(title, findsOneWidget);
      final edge = tester.getTopLeft(title).dx;
      expect(
        tester.getTopLeft(find.byType(OutlinedButton)).dx,
        closeTo(edge, 0.5),
      );
      // The text of a bare text button starts on the same edge, not 12 px in.
      expect(tester.getTopLeft(find.text('Actualiser')).dx, closeTo(edge, 0.5));
    },
  );

  testWidgets('the star button with none left leaves the card in place', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester, superLikes: 0);

    await tester.tap(find.bySemanticsLabel('Super like'));
    await settle(tester);

    _expectAtRest(tester, _card(101));
    expect(find.text(_superLikeGateTitle), findsWidgets);
    expect(api.swipes, isEmpty);
  });

  testWidgets('a quick flick short of 30 % but past 48 px likes', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester);

    await flick(tester, _card(101), const Offset(60, 0), 40);
    await settle(tester);

    expect(api.swipes, ['101:like']);
    expect(_card(101), findsNothing);
    expect(_card(102), findsOneWidget);
  });

  testWidgets('a like uses one of the free likes, a pass uses none', (
    tester,
  ) async {
    await _pumpDiscover(tester);
    final before = PremiumGate.remainingFreeLikes;

    await dragSlowly(tester, _card(101), const Offset(-170, 0));
    await settle(tester);
    expect(PremiumGate.remainingFreeLikes, before);

    await dragSlowly(tester, _card(102), const Offset(170, 0));
    await settle(tester);
    expect(PremiumGate.remainingFreeLikes, before - 1);
  });

  testWidgets(
    'a super like by finger sends super_like, spends one, and gives the '
    'threshold click then a medium impact',
    (tester) async {
      final haptics = HapticLog(tester);
      final api = await _pumpDiscover(tester);
      expect(PremiumGate.remainingSuperLikes, 1);

      await dragSlowly(tester, _card(101), const Offset(0, -360));
      await settle(tester);

      // The count comes back from the server's answer, not from the app.
      expect(api.swipes, ['101:super_like']);
      expect(PremiumGate.remainingSuperLikes, 0);
      expect(haptics.calls, ['selectionClick', 'mediumImpact']);
    },
  );

  testWidgets('a slow drag short of 30 % springs back', (tester) async {
    final api = await _pumpDiscover(tester);

    await dragSlowly(tester, _card(101), const Offset(90, 0));
    await settle(tester);

    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
  });

  testWidgets('a fast, mostly vertical flick does not like', (tester) async {
    final api = await _pumpDiscover(tester);

    await flick(tester, _card(101), const Offset(60, 200), 40);
    await settle(tester);

    expect(api.swipes, isEmpty);
    _expectAtRest(tester, _card(101));
  });

  testWidgets('dragging past 30 % to the left passes', (tester) async {
    final api = await _pumpDiscover(tester);

    await dragSlowly(tester, _card(101), const Offset(-170, 0));
    await settle(tester);

    expect(api.swipes, ['101:pass']);
    expect(_card(102), findsOneWidget);
  });

  testWidgets('the like button throws the card, it is not just removed', (
    tester,
  ) async {
    final api = await _pumpDiscover(tester);

    await tester.tap(find.bySemanticsLabel("J'aime"));
    await tester.pump(); // the animation starts on this frame
    await tester.pump(const Duration(milliseconds: 120));
    expect(_card(101), findsOneWidget, reason: 'still on its way out');
    expect(tester.getCenter(_card(101)).dx, greaterThan(_restX(tester) + 20));
    await settle(tester);

    expect(api.swipes, ['101:like']);
    expect(_card(101), findsNothing);
  });

  testWidgets('undo brings the last card back, from the side it left', (
    tester,
  ) async {
    PremiumGate.debugPremiumOverride = true;
    final api = await _pumpDiscover(tester);
    await dragSlowly(tester, _card(101), const Offset(-170, 0));
    await settle(tester);
    expect(_card(101), findsNothing);

    await tester.tap(find.bySemanticsLabel('Annuler'));
    await tester.pump(); // the animation starts on this frame
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getCenter(_card(101)).dx, lessThan(_restX(tester) - 40));
    await settle(tester);

    _expectAtRest(tester, _card(101));
    expect(api.swipes, ['101:pass']);
  });

  group('photo indicator', () {
    Finder inTopCard(Finder f) => find.descendant(of: _card(101), matching: f);
    double inkLeft(WidgetTester tester) => tester
        .getRect(inTopCard(find.byKey(const Key('photo-bar-current'))))
        .left;
    double segmentLeft(WidgetTester tester, int i) =>
        tester.getRect(inTopCard(find.byKey(Key('photo-bar-$i')))).left;
    Rect photo(WidgetTester tester) =>
        tester.getRect(inTopCard(find.byType(ProfilePhoto)));

    testWidgets('photos change by tapping the halves of the photo', (
      tester,
    ) async {
      await _pumpDiscover(tester, photos: const ['', '', '']);
      expect(inkLeft(tester), segmentLeft(tester, 0));

      final box = photo(tester);
      await tester.tapAt(Offset(box.right - 20, box.center.dy));
      await tester.pumpAndSettle();
      expect(inkLeft(tester), segmentLeft(tester, 1));

      await tester.tapAt(Offset(box.left + 20, box.center.dy));
      await tester.pumpAndSettle();
      expect(inkLeft(tester), segmentLeft(tester, 0));
    });

    testWidgets('the ink segment slides to the next photo, it does not jump', (
      tester,
    ) async {
      await _pumpDiscover(tester, photos: const ['', '', '']);
      final from = segmentLeft(tester, 0);
      final to = segmentLeft(tester, 1);

      final box = photo(tester);
      await tester.tapAt(Offset(box.right - 20, box.center.dy));
      await tester.pump();
      await tester.pump(MazlMotion.photoIndicatorSlide ~/ 2);
      expect(inkLeft(tester), greaterThan(from + 1));
      expect(inkLeft(tester), lessThan(to - 1));

      await tester.pump(MazlMotion.photoIndicatorSlide);
      expect(inkLeft(tester), to);
    });

    testWidgets('reduced motion: the ink segment is on the new photo at once', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpDiscover(tester, photos: const ['', '', '']);

      final box = photo(tester);
      await tester.tapAt(Offset(box.right - 20, box.center.dy));
      await tester.pump();
      await tester.pump();
      expect(inkLeft(tester), segmentLeft(tester, 1));
    });
  });
}
