import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart'
    show ProfilePhoto;
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/swipe_gestures.dart';
import '../../mocks/fake_discover_api.dart';

const _likeLimitTitle = 'Vos likes du jour sont partis.';
const _superLikeGateTitle = 'Super Likes';

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

Future<FakeDiscoverApi> _pumpDiscover(
  WidgetTester tester, {
  List<String> photos = const [],
  bool verified = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = FakeDiscoverApi(
    discoverProfiles(3, photos: photos, verified: verified),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
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
    PremiumGate.useSuperLike();
    expect(PremiumGate.remainingSuperLikes, 0);
    final api = await _pumpDiscover(tester);

    await _releaseRefusedAndWatch(
      tester,
      101,
      const Offset(0, -360),
      _superLikeGateTitle,
    );

    expect(api.swipes, isEmpty);
  });

  testWidgets('the star button with none left leaves the card in place', (
    tester,
  ) async {
    PremiumGate.useSuperLike();
    final api = await _pumpDiscover(tester);

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

  testWidgets('photos change by tapping the halves of the photo', (
    tester,
  ) async {
    await _pumpDiscover(tester, photos: const ['', '', '']);
    Finder inTopCard(Finder f) => find.descendant(of: _card(101), matching: f);
    Color bar(int i) =>
        (tester
                    .widget<Container>(
                      inTopCard(find.byKey(Key('photo-bar-$i'))),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;
    final box = tester.getRect(inTopCard(find.byType(ProfilePhoto)));

    expect(bar(0), AppColors.ink);
    await tester.tapAt(Offset(box.right - 20, box.center.dy));
    await tester.pump();
    expect(bar(1), AppColors.ink);
    await tester.tapAt(Offset(box.left + 20, box.center.dy));
    await tester.pump();
    expect(bar(0), AppColors.ink);
  });
}
