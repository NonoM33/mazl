import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:mazl/presentation/features/matching/screens/daily_picks_screen.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:mazl/presentation/features/matching/widgets/match_sheet.dart';
import 'package:mazl/presentation/features/profile/screens/profile_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/fake_discover_api.dart';

// A choice made on the profile page (like, pass) is the same choice as on the
// card: the person must not come back on Discover, a match shows the match
// sheet, and the key read is the server's (`match`, SwipeResult).

Finder _card(int userId) => find.byWidgetPredicate(
  (w) => w is DiscoverCard && w.profile.userId == userId,
);

/// [home] at `/home`, the profile page at `/discover/profile/:id` above it,
/// and a Messages stub at `/chat`.
Future<void> _pumpWithProfilePage(
  WidgetTester tester,
  FakeDiscoverApi api,
  Widget home,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => home),
      GoRoute(
        path: '/discover/profile/:userId',
        builder: (_, state) => ProfileViewScreen(
          userId: state.pathParameters['userId'],
          apiService: api,
        ),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, _) => const Scaffold(body: Text('Messages')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      // The subscription service is an app-wide singleton that a disposed
      // scope would dispose with it: the tests do not need it.
      overrides: [isMazlProProvider.overrideWithValue(false)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _openProfileFromDiscover(WidgetTester tester) async {
  await tester.tap(find.textContaining('Profil1', findRichText: true).first);
  await tester.pumpAndSettle();
  expect(find.byType(ProfileViewScreen), findsOneWidget);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
  });

  tearDown(PremiumGate.resetForTest);

  group('from Discover', () {
    testWidgets('a like on the profile page throws the card: the person does '
        'not come back, and the like is sent once', (tester) async {
      final api = FakeDiscoverApi(discoverProfiles(3));
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileViewScreen), findsNothing);
      expect(_card(101), findsNothing, reason: 'Profil1 is still on Discover');
      expect(_card(102), findsOneWidget);
      expect(api.swipes, ['101:like']);
      expect(PremiumGate.remainingFreeLikes, PremiumGate.freeLikesPerDay - 1);
    });

    testWidgets('a pass on the profile page throws the card too', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(3));
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(ProfileViewScreen),
          matching: find.bySemanticsLabel('Passer'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_card(101), findsNothing);
      expect(api.swipes, ['101:pass']);
    });

    testWidgets('a match on the profile page opens the match sheet, once, '
        'and the card is gone after it', (tester) async {
      final api = FakeDiscoverApi(discoverProfiles(3))..matchWith.add(101);
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();
      expect(find.byType(MatchSheetContent), findsOneWidget);

      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchSheetContent), findsNothing);
      expect(_card(101), findsNothing);
      expect(api.swipes, ['101:like']);
    });

    testWidgets('« Envoyer un message » on that sheet leads to Messages', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(3))..matchWith.add(101);
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Envoyer un message'));
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('a like that did not leave keeps the page and says so', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(3))..swipesFail = true;
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileViewScreen), findsOneWidget);
      expect(
        find.text("Votre choix n'est pas parti. Réessayez."),
        findsOneWidget,
      );
    });

    testWidgets('no free like left: the page stays and nothing is sent', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(3));
      while (PremiumGate.remainingFreeLikes > 0) {
        PremiumGate.useFreeLike();
      }
      await _pumpWithProfilePage(tester, api, DiscoverScreen(apiService: api));
      await _openProfileFromDiscover(tester);

      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();

      expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
      expect(api.swipes, isEmpty);
    });
  });

  group('Likes', () {
    testWidgets('liking back someone who liked you, with the server answer '
        '{ match: true }, opens the match sheet', (tester) async {
      final api = FakeDiscoverApi(discoverProfiles(1))
        ..matchWith.add(101)
        ..receivedLikes = LikesData(
          count: 1,
          isPremium: true,
          likes: [
            LikeProfile(
              userId: 101,
              displayName: 'Profil1',
              likedAt: DateTime(2026, 10, 24),
            ),
          ],
        );
      await _pumpWithProfilePage(tester, api, LikesScreen(apiService: api));

      await tester.tap(find.bySemanticsLabel('Aimer Profil1'));
      await tester.pumpAndSettle();

      expect(find.byType(MatchSheetContent), findsOneWidget);
      expect(api.swipes, ['101:like']);
    });
  });

  group('Daily picks', () {
    testWidgets('a match is the match sheet, not a system dialog', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(2))..matchWith.add(101);
      await _pumpWithProfilePage(
        tester,
        api,
        DailyPicksScreen(apiService: api),
      );

      await tester.tap(find.byTooltip("J'aime").first);
      await tester.pumpAndSettle();

      expect(find.byType(MatchSheetContent), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a like on the profile page takes the pick off the grid', (
      tester,
    ) async {
      final api = FakeDiscoverApi(discoverProfiles(2));
      await _pumpWithProfilePage(
        tester,
        api,
        DailyPicksScreen(apiService: api),
      );

      await tester.tap(
        find.textContaining('Profil1', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("J'aime Profil1"));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileViewScreen), findsNothing);
      expect(find.textContaining('Profil1'), findsNothing);
      expect(find.textContaining('Profil2'), findsOneWidget);
      expect(api.swipes, ['101:like']);
    });
  });
}
