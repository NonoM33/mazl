import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:mazl/presentation/features/likes/widgets/blurred_like_tile.dart';
import 'package:mazl/presentation/features/likes/widgets/like_widgets.dart';
import 'package:mazl/presentation/features/premium/widgets/purchase_moment_sheet.dart';
import 'package:mazl/presentation/features/matching/screens/matches_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';

// Forme de `GET /api/likes/received` (docs/launch/V1-CONTRAT.md §3) : le
// serveur ajoute `is_premium` à la RACINE de la réponse, la forme des éléments
// de `likes` ne change pas. Pour un membre sans mazl+, chaque like est réduit
// à son aperçu (`likes-visibility`) : prénom, badge, date, rien d'autre.

const _subscriberBody = {
  'success': true,
  'count': 2,
  'is_premium': true,
  'likes': [
    {
      'user_id': 41,
      'display_name': 'Jeanne Exemple',
      'picture': 'https://example.com/jeanne.jpg',
      'age': 29,
      'is_verified': true,
      'liked_at': '2026-10-24T18:30:00.000Z',
    },
    {
      'user_id': 42,
      'display_name': 'Noa Exemple',
      'picture': null,
      'age': 31,
      'is_verified': false,
      'liked_at': '2026-10-23T09:00:00.000Z',
    },
  ],
};

const _freeBody = {
  'success': true,
  'count': 12,
  'is_premium': false,
  'likes': [
    {
      'display_name': 'Jeanne Exemple',
      'is_verified': true,
      'liked_at': '2026-10-24T18:30:00.000Z',
      'blurredPhotoUrl': 'https://example.com/media/photos/blur?exp=1&sig=x',
      'is_super_like': true,
    },
    {
      'display_name': 'Noa Exemple',
      'is_verified': false,
      'liked_at': '2026-10-23T09:00:00.000Z',
      'blurredPhotoUrl': null,
      'is_super_like': false,
    },
  ],
};

const _twoLikesBody = {
  'success': true,
  'count': 2,
  'is_premium': false,
  'likes': [
    {
      'display_name': 'Jeanne Exemple',
      'is_verified': true,
      'liked_at': '2026-10-24T18:30:00.000Z',
      'blurredPhotoUrl': null,
      'is_super_like': false,
    },
    {
      'display_name': 'Noa Exemple',
      'is_verified': false,
      'liked_at': '2026-10-23T09:00:00.000Z',
      'blurredPhotoUrl': null,
      'is_super_like': false,
    },
  ],
};

/// A subscriber's like of the new server: the complete form, plus the Super
/// Like and its word.
const _subscriberSuperLikeBody = {
  'success': true,
  'count': 1,
  'is_premium': true,
  'likes': [
    {
      'user_id': 43,
      'display_name': 'Léa Exemple',
      'picture': 'https://example.com/lea.jpg',
      'age': 27,
      'is_verified': true,
      'liked_at': '2026-10-25T08:00:00.000Z',
      'is_super_like': true,
      'note': 'Ton profil m\'a fait sourire.',
    },
  ],
};

/// Rejoue la VRAIE `ApiService.getReceivedLikes` contre [body].
Future<LikesData> _received(Object body) async {
  final response = await http.runWithClient(
    () => ApiService().getReceivedLikes(),
    () => MockClient(
      (request) async => http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );
  expect(response.success, isTrue);
  return response.data!;
}

class _LikesApi implements ApiService {
  _LikesApi(this.likes);

  final LikesData likes;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      ApiResponse.success(likes);

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async =>
      ApiResponse.success(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_LikesApi: ${invocation.memberName}');
}

Future<void> _pumpLikes(WidgetTester tester, LikesData likes) async {
  await pumpLocalized(
    tester,
    LikesScreen(apiService: _LikesApi(likes)),
    size: const Size(390, 1200),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpMatches(WidgetTester tester, LikesData likes) async {
  await pumpLocalized(
    tester,
    MatchesScreen(apiService: _LikesApi(likes)),
    size: const Size(390, 2000),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PurchaseMoments.resetForTest();
    PremiumGate.resetForTest();
  });

  group('le modèle lit is_premium à la racine de la réponse', () {
    test('un abonné : is_premium vrai, les likes complets', () async {
      final data = await _received(_subscriberBody);

      expect(data.isPremium, isTrue);
      expect(data.count, 2);
      expect(data.likes.map((like) => like.userId), [41, 42]);
      expect(data.likes.first.displayName, 'Jeanne Exemple');
      expect(data.likes.first.age, 29);
      expect(data.likes.first.isVerified, isTrue);
      expect(data.likes.first.photoUrl, 'https://example.com/jeanne.jpg');
    });

    test(
      'sans mazl+ : le vrai nombre, des aperçus sans id ni photo nette',
      () async {
        final data = await _received(_freeBody);

        expect(data.isPremium, isFalse);
        // `count` is the real number of likes, not the length of the preview.
        expect(data.count, 12);
        expect(data.likes, hasLength(2));
        expect(data.likes.first.photoUrl, isNull);
        expect(data.likes.first.age, isNull);
        expect(data.likes.first.userId, 0);
      },
    );

    test('sans mazl+ : photo floue, Super Like, badge et date lus', () async {
      final data = await _received(_freeBody);

      final first = data.likes.first;
      expect(
        first.blurredPhotoUrl,
        'https://example.com/media/photos/blur?exp=1&sig=x',
      );
      expect(first.isSuperLike, isTrue);
      expect(first.isVerified, isTrue);
      expect(first.likedAt.toUtc(), DateTime.utc(2026, 10, 24, 18, 30));
      expect(data.likes.last.blurredPhotoUrl, isNull);
      expect(data.likes.last.isSuperLike, isFalse);
    });

    test('un abonné : le Super Like et son mot', () async {
      final data = await _received(_subscriberSuperLikeBody);

      expect(data.likes.single.isSuperLike, isTrue);
      expect(data.likes.single.note, 'Ton profil m\'a fait sourire.');
      expect(data.likes.single.blurredPhotoUrl, isNull);
    });

    test(
      'un ancien serveur (sans les nouveaux champs) reste lisible',
      () async {
        final data = await _received(_subscriberBody);

        expect(data.likes.first.isSuperLike, isFalse);
        expect(data.likes.first.note, isNull);
        expect(data.likes.first.blurredPhotoUrl, isNull);
      },
    );

    test('une photo floue vide ou un mot vide valent « absent »', () async {
      final data = await _received({
        'success': true,
        'count': 1,
        'is_premium': false,
        'likes': [
          {
            'liked_at': '2026-10-24T18:30:00.000Z',
            'blurredPhotoUrl': '  ',
            'note': '',
          },
        ],
      });

      expect(data.likes.single.blurredPhotoUrl, isNull);
      expect(data.likes.single.note, isNull);
    });

    test('un serveur qui ne dit rien : on reste fermé', () async {
      final data = await _received({
        'success': true,
        'count': 0,
        'likes': <Object>[],
      });

      expect(data.isPremium, isFalse);
    });

    test(
      'is_premium dans un like ne compte pas : seule la racine fait foi',
      () async {
        final data = await _received({
          'success': true,
          'count': 1,
          'likes': [
            {
              'display_name': 'Jeanne Exemple',
              'is_premium': true,
              'liked_at': '2026-10-24T18:30:00.000Z',
            },
          ],
        });

        expect(data.isPremium, isFalse);
      },
    );
  });

  group('l\'écran Likes', () {
    testWidgets('un abonné voit les cartes, aucune tuile verrouillée', (
      tester,
    ) async {
      await _pumpLikes(tester, await _received(_subscriberBody));

      expect(find.byType(LockedLikeTile), findsNothing);
      expect(find.byType(LikeCard), findsNWidgets(2));
      expect(find.byType(MazlPlusPill), findsNothing);
    });

    testWidgets(
      'sans mazl+, que des tuiles floues, le vrai nombre et l\'invitation',
      (tester) async {
        await _pumpLikes(tester, await _received(_freeBody));

        expect(find.byType(LikeCard), findsNothing);
        expect(find.byType(LockedLikeTile), findsNothing);
        expect(find.byType(BlurredLikeTile), findsNWidgets(2));
        expect(find.text('12 personnes vous ont aimé'), findsOneWidget);
        expect(find.textContaining('Jeanne'), findsNothing);
        expect(find.textContaining('Noa'), findsNothing);
        expect(find.byType(MazlPlusPill), findsOneWidget);
      },
    );

    testWidgets('un abonné voit la marque Super Like et le mot', (
      tester,
    ) async {
      await _pumpLikes(tester, await _received(_subscriberSuperLikeBody));

      expect(find.byType(LikeCard), findsOneWidget);
      expect(find.text('Super Like'), findsOneWidget);
      expect(find.text('Ton profil m\'a fait sourire.'), findsOneWidget);
    });

    testWidgets(
      'sans mazl+ et 3 likes ou plus : l\'offre du 3e like, une fois',
      (tester) async {
        await _pumpLikes(tester, await _received(_freeBody));
        await tester.pumpAndSettle();

        expect(find.byType(PurchaseMomentSheet), findsOneWidget);
        expect(find.text('Plusieurs personnes vous ont aimé.'), findsOneWidget);
        await tester.tap(find.text('Plus tard'));
        await tester.pumpAndSettle();

        // Pulling to refresh does not bring it back.
        await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseMomentSheet), findsNothing);
      },
    );

    testWidgets('sans mazl+ mais moins de 3 likes : pas d\'offre', (
      tester,
    ) async {
      await _pumpLikes(tester, await _received(_twoLikesBody));
      await tester.pumpAndSettle();

      expect(find.byType(PurchaseMomentSheet), findsNothing);
    });

    testWidgets('un abonné n\'a jamais l\'offre', (tester) async {
      await _pumpLikes(tester, await _received(_subscriberBody));
      await tester.pumpAndSettle();

      expect(find.byType(PurchaseMomentSheet), findsNothing);
    });

    testWidgets('un appui sur une tuile floue ouvre mazl+', (tester) async {
      // The offer of the 3rd like was already made: it does not cover the grid.
      SharedPreferences.setMockInitialValues({
        'purchase_moment.third_like_done': true,
      });
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final likes = await _received(_freeBody);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => LikesScreen(apiService: _LikesApi(likes)),
          ),
          GoRoute(
            path: RoutePaths.premium,
            builder: (_, _) => const Scaffold(body: Text('page mazl+')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(BlurredLikeTile).first);
      await tester.pumpAndSettle();

      expect(find.text('page mazl+'), findsOneWidget);
    });
  });

  group('l\'écran Matchs', () {
    testWidgets(
      'sans mazl+ et 3 likes ou plus : l\'offre du 3e like, une fois',
      (tester) async {
        await _pumpMatches(tester, await _received(_freeBody));
        await tester.pumpAndSettle();

        expect(find.byType(PurchaseMomentSheet), findsOneWidget);
        await tester.tap(find.text('Plus tard'));
        await tester.pumpAndSettle();

        // Made here, so the Likes screen does not make it again.
        await _pumpLikes(tester, await _received(_freeBody));
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseMomentSheet), findsNothing);
      },
    );

    testWidgets(
      'un abonné voit les cartes des likes, aucune tuile verrouillée',
      (tester) async {
        await _pumpMatches(tester, await _received(_subscriberBody));

        expect(find.byType(LockedLikeTile), findsNothing);
        expect(find.byType(LikeCard), findsNWidgets(2));
        expect(find.byType(MazlPlusPill), findsNothing);
      },
    );

    testWidgets('sans mazl+, des tuiles verrouillées et l\'invitation', (
      tester,
    ) async {
      await _pumpMatches(tester, await _received(_freeBody));

      expect(find.byType(LikeCard), findsNothing);
      expect(find.byType(LockedLikeTile), findsNWidgets(2));
      expect(find.byType(MazlPlusPill), findsOneWidget);
    });
  });
}
