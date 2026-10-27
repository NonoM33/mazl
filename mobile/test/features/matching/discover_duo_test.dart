import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/profile.dart' show Profile;
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart'
    show ProfilePhoto;
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../helpers/swipe_gestures.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';

// The Discover feed on the foldable iPhone (iPhone Duo): flat it is the usual
// card; half open the fold cuts it, the photo on the viewing half and the name,
// the details and every action on the other one, out of the curve.

/// The four buttons of the card, by icon: pass, like, super like, boost.
const _actionIcons = [
  LucideIcons.x,
  LucideIcons.heart,
  LucideIcons.star,
  LucideIcons.zap,
];

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

Finder _inCard(int userId, Finder matching) =>
    find.descendant(of: _card(userId), matching: matching);

Finder _photo(int userId) => _inCard(userId, find.byType(ProfilePhoto));

Finder _name(int userId) => _inCard(userId, find.textContaining('Profil'));

Finder _action(int userId, IconData icon) => _inCard(
  userId,
  find.ancestor(of: find.byIcon(icon), matching: find.byType(InkWell)),
);

List<Profile> _profiles() => [
  for (var i = 1; i <= 3; i++)
    Profile(
      id: i,
      userId: 100 + i,
      displayName: 'Profil$i',
      age: 20 + i,
      location: 'Paris',
      distance: 12,
      denomination: 'modern_orthodox',
      kashrut: 'strict',
      isVerified: true,
      bio: 'Pianiste numéro $i, aime les longues marches.',
    ),
];

Future<DuoPoseController> _pumpDiscover(
  WidgetTester tester,
  DuoPose pose, {
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  final api = FakeDiscoverApi(_profiles());
  final inFold = duoAppBuilder(controller);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          ReduceMotionScope(child: inFold(context, child)),
      home: DiscoverScreen(
        apiService: api,
        likeAllowanceApi: FakeLikeAllowanceApi.free(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

void _expectInsideSafeArea(Rect rect, DuoPose pose, String reason) {
  final safe = pose.safeRect.inflate(0.5);
  expect(
    safe.contains(rect.topLeft) && safe.contains(rect.bottomRight),
    isTrue,
    reason: '$reason $rect is outside ${pose.safeRect} in ${pose.name}',
  );
}

void main() {
  // Real glyph widths: the test font is twice as wide as the app's.
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    storeJournal.clear();
    final store = FakeStoreGateway();
    installTestCredits(gateway: store, api: FakeCreditsApi()).applyFromServer(
      serverCredits(
        superLikeAllowance: 1,
        superLikeRemaining: 1,
        superLikePurchased: 0,
        boostAllowance: 0,
        boostRemaining: 0,
        boostPurchased: 1,
      ),
    );
  });

  tearDown(PremiumGate.resetForTest);

  // Renaud on 2026-10-27, the foldable iPhone open flat: the half beside the
  // photo held a name and « Voir le profil » on a big empty card. With a fold
  // or a wide screen, that half reads the whole profile directly.
  group('the full profile beside the photo', () {
    for (final pose in [DuoPose.openLandscape, DuoPose.halfOpenBook]) {
      testWidgets('${pose.name}: about and the essentials without a tap', (
        tester,
      ) async {
        await _pumpDiscover(tester, pose);
        final bio = _inCard(101, find.text('Pianiste numéro 1, aime les longues marches.'));
        expect(bio, findsOneWidget);
        _expectInsideSafeArea(tester.getRect(bio), pose, 'the bio');
        expect(
          tester.getRect(bio).left,
          greaterThan(tester.getRect(_photo(101)).right),
          reason: 'beside the photo, not under it',
        );
        expect(
          _inCard(101, find.byKey(const ValueKey('discover-detail'))),
          findsOneWidget,
        );
      });
    }

    testWidgets('closed: the compact card, no detail', (tester) async {
      await _pumpDiscover(tester, DuoPose.closed);
      expect(_inCard(101, find.text('Pianiste numéro 1, aime les longues marches.')), findsNothing);
    });
  });

  group('every posture', () {
    for (final pose in DuoPose.values) {
      testWidgets('${pose.name}: the card fits and its four buttons are in '
          'view', (tester) async {
        await _pumpDiscover(tester, pose);
        expect(_card(101), findsOneWidget);
        expectFitsDuoPose(tester, pose, 'Discover');
        for (final icon in _actionIcons) {
          final button = _action(101, icon);
          expect(button, findsOneWidget, reason: '$icon in ${pose.name}');
          expect(button.hitTestable(), findsOneWidget, reason: '$icon');
          _expectInsideSafeArea(tester.getRect(button), pose, '$icon');
        }
        _expectInsideSafeArea(tester.getRect(_name(101)), pose, 'the name');
      });
    }
  });

  group('half open like a laptop', () {
    testWidgets('the photo is above the fold, the name and every button '
        'below', (tester) async {
      await _pumpDiscover(tester, DuoPose.halfOpenLaptop);
      final fold = DuoPose.halfOpenLaptop.fold!;

      expect(tester.getRect(_photo(101)).bottom, lessThanOrEqualTo(fold.top));
      expect(tester.getRect(_name(101)).top, greaterThanOrEqualTo(fold.bottom));
      for (final icon in _actionIcons) {
        expect(
          tester.getRect(_action(101, icon)).top,
          greaterThanOrEqualTo(fold.bottom),
          reason: '$icon is not below the fold',
        );
      }
    });
  });

  group('half open like a book', () {
    testWidgets('the photo is left of the fold, the name and every button '
        'right', (tester) async {
      await _pumpDiscover(tester, DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;

      expect(tester.getRect(_photo(101)).right, lessThanOrEqualTo(fold.left));
      expect(tester.getRect(_name(101)).left, greaterThanOrEqualTo(fold.right));
      for (final icon in _actionIcons) {
        expect(
          tester.getRect(_action(101, icon)).left,
          greaterThanOrEqualTo(fold.right),
          reason: '$icon is not right of the fold',
        );
      }
    });

    testWidgets('in Hebrew the photo is on the right, the rest on the left', (
      tester,
    ) async {
      await _pumpDiscover(
        tester,
        DuoPose.halfOpenBook,
        locale: const Locale('he'),
      );
      final fold = DuoPose.halfOpenBook.fold!;

      expect(
        textDirectionAt(tester, _card(101)),
        TextDirection.rtl,
        reason: 'the test must run right to left',
      );
      expect(
        tester.getRect(_photo(101)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(tester.getRect(_name(101)).right, lessThanOrEqualTo(fold.left));
      for (final icon in _actionIcons) {
        expect(
          tester.getRect(_action(101, icon)).right,
          lessThanOrEqualTo(fold.left),
          reason: '$icon is not left of the fold',
        );
      }
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'Discover in Hebrew');
    });
  });

  group('folding keeps the feed', () {
    testWidgets('the same card, the same profile, through every posture', (
      tester,
    ) async {
      final pose = await _pumpDiscover(tester, DuoPose.openPortrait);
      // The member has already liked the first profile.
      await tester.tap(_action(101, LucideIcons.heart));
      await settle(tester);
      expect(_card(101), findsNothing);
      expect(_card(102), findsOneWidget);
      final card = tester.state(_card(102));

      for (final next in [
        DuoPose.halfOpenLaptop,
        DuoPose.openPortrait,
        DuoPose.halfOpenBook,
        DuoPose.closed,
        DuoPose.halfOpenLaptop,
        DuoPose.splitView,
      ]) {
        await pose.moveTo(tester, next);
        await tester.pump(const Duration(milliseconds: 100));
        expect(_card(102), findsOneWidget, reason: next.name);
        expect(_card(101), findsNothing, reason: next.name);
        expect(
          identical(tester.state(_card(102)), card),
          isTrue,
          reason: 'the card was rebuilt from scratch in ${next.name}',
        );
        expect(_name(102), findsOneWidget, reason: next.name);
        expectFitsDuoPose(tester, next, 'Discover');
      }
    });

    testWidgets('a like sent while half open still reaches the next profile', (
      tester,
    ) async {
      await _pumpDiscover(tester, DuoPose.halfOpenLaptop);
      await tester.tap(_action(101, LucideIcons.heart));
      await settle(tester);
      expect(_card(101), findsNothing);
      expect(_card(102), findsOneWidget);
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(tester.getRect(_photo(102)).bottom, lessThanOrEqualTo(fold.top));
      expect(
        tester.getRect(_action(102, LucideIcons.heart)).top,
        greaterThanOrEqualTo(fold.bottom),
      );
    });
  });
}
