import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:mazl/presentation/features/likes/widgets/like_widgets.dart';
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
  'count': 2,
  'is_premium': false,
  'likes': [
    {
      'display_name': 'Jeanne Exemple',
      'is_verified': true,
      'liked_at': '2026-10-24T18:30:00.000Z',
    },
    {
      'display_name': 'Noa Exemple',
      'is_verified': false,
      'liked_at': '2026-10-23T09:00:00.000Z',
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

    test('sans mazl+ : is_premium faux, des aperçus sans id ni photo', () async {
      final data = await _received(_freeBody);

      expect(data.isPremium, isFalse);
      expect(data.count, 2);
      expect(data.likes, hasLength(2));
      expect(data.likes.first.displayName, 'Jeanne Exemple');
      expect(data.likes.first.photoUrl, isNull);
      expect(data.likes.first.age, isNull);
    });

    test('un serveur qui ne dit rien : on reste fermé', () async {
      final data = await _received({
        'success': true,
        'count': 0,
        'likes': <Object>[],
      });

      expect(data.isPremium, isFalse);
    });

    test('is_premium dans un like ne compte pas : seule la racine fait foi',
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
    });
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

    testWidgets('sans mazl+, que des tuiles verrouillées et l\'invitation', (
      tester,
    ) async {
      await _pumpLikes(tester, await _received(_freeBody));

      expect(find.byType(LikeCard), findsNothing);
      expect(find.byType(LockedLikeTile), findsNWidgets(2));
      expect(find.byType(MazlPlusPill), findsOneWidget);
    });
  });

  group('l\'écran Matchs', () {
    testWidgets('un abonné voit les cartes des likes, aucune tuile verrouillée',
        (tester) async {
      await _pumpMatches(tester, await _received(_subscriberBody));

      expect(find.byType(LockedLikeTile), findsNothing);
      expect(find.byType(LikeCard), findsNWidgets(2));
      expect(find.byType(MazlPlusPill), findsNothing);
    });

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
