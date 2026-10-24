import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/matching/screens/matches_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakeMatchesApi implements ApiService {
  _FakeMatchesApi({required this.matches, this.likes});

  final ApiResponse<List<Map<String, dynamic>>> matches;
  final LikesData? likes;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async => matches;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async => likes == null
      ? ApiResponse.failure('Failed to get likes')
      : ApiResponse.success(likes!);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchesApi: ${invocation.memberName}');
}

Map<String, dynamic> _match(
  int id,
  Duration ago, {
  String? name,
  String? place,
}) => {
  'conversationId': id,
  'matchedAt': DateTime.now().subtract(ago).toIso8601String(),
  'profile': {
    'user_id': id,
    'display_name': ?name,
    'age': 20 + id,
    'location': ?place,
  },
};

List<Map<String, dynamic>> _someMatches() => [
  _match(1, const Duration(hours: 1), name: 'Jeanne', place: 'Paris'),
  _match(2, const Duration(hours: 30), name: 'Léa'),
  _match(3, const Duration(days: 3, hours: 1), name: 'Noa', place: 'Lyon'),
  _match(4, const Duration(days: 15), place: 'Nice'),
  _match(5, const Duration(days: 95), name: 'Eli', place: 'Lille'),
];

_FakeMatchesApi _api({List<Map<String, dynamic>>? matches, LikesData? likes}) =>
    _FakeMatchesApi(
      matches: ApiResponse.success(matches ?? _someMatches()),
      likes: likes,
    );

LikesData _likes({bool premium = false, int total = 9}) => LikesData(
  count: total,
  isPremium: premium,
  likes: [
    for (var i = 1; i <= 4; i++)
      LikeProfile(userId: i, displayName: 'Noa$i', likedAt: DateTime(2026, 10)),
  ],
);

Future<void> _pump(WidgetTester tester, ApiService api, L10nCase c) async {
  await pumpLocalized(
    tester,
    MatchesScreen(apiService: api),
    locale: c.locale,
    brightness: c.brightness,
    size: const Size(360, 2000),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

const _frenchTexts = [
  'MATCHS',
  'NOUVEAUX · 3',
  'Aujourd\'hui',
  'Hier',
  'Il y a 3 jours',
  'Il y a 2 semaines',
  'Il y a 3 mois',
  'Inconnu',
  'Écrivez-lui',
  'Ça y est, vous avez matché ?',
  'Activer le mode couple',
  'ILS VOUS ONT AIMÉ · 9',
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      MatchesScreen(apiService: _api(likes: _likes())),
      size: const Size(360, 2000),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Il y a 3 jours'), findsOneWidget);
    expect(find.text('Il y a 2 semaines'), findsOneWidget);
    expect(find.text('Il y a 3 mois'), findsOneWidget);
    expect(find.text('Écrivez-lui'), findsOneWidget);
    expect(find.text('Voir les 5 autres avec mazl+'), findsOneWidget);
  });

  testWidgets('English list, relative dates, promo banner', (tester) async {
    await _pump(tester, _api(likes: _likes()), l10nCases.first);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('3 days ago'), findsOneWidget);
    expect(find.text('2 weeks ago'), findsOneWidget);
    expect(find.text('3 months ago'), findsOneWidget);
    expect(find.text('Say hello'), findsOneWidget);
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('NEW · 3'), findsOneWidget);
    expect(find.text('CONVERSATIONS · 5'), findsOneWidget);
    expect(find.text('Did you two match?'), findsOneWidget);
    expect(find.text('Turn on couple mode'), findsOneWidget);
    expect(find.text('See 5 more with mazl+'), findsOneWidget);
  });

  testWidgets('Russian weeks and months follow the count', (tester) async {
    await _pump(tester, _api(), const L10nCase(Locale('ru'), Brightness.light));
    expect(find.text('2 недели назад'), findsOneWidget);
    expect(find.text('3 месяца назад'), findsOneWidget);
  });

  testWidgets('premium member keeps a plain « see more » button', (
    tester,
  ) async {
    await _pump(tester, _api(likes: _likes(premium: true)), l10nCases.first);
    expect(find.text('See 5 more'), findsOneWidget);
  });

  testWidgets('English empty and failed states', (tester) async {
    await _pump(tester, _api(matches: []), l10nCases.first);
    expect(find.text('No matches yet'), findsOneWidget);
    expect(find.text('Keep discovering profiles.'), findsOneWidget);
  });

  testWidgets('a failed load never shows the server diagnostic', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeMatchesApi(matches: ApiResponse.failure('Failed to get matches')),
      l10nCases.first,
    );
    expect(find.text('Failed to get matches'), findsNothing);
    expect(find.text("Couldn't load your matches"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('matches in ${c.name}', (tester) async {
      await _pump(tester, _api(likes: _likes()), c);
      expectNoFrench(_frenchTexts);
      expectDirection(tester, find.text('Jeanne, 21'), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state in ${c.name}', (tester) async {
      await _pump(tester, _api(matches: []), c);
      expectNoFrench([
        'Pas encore de match',
        'Continuez à découvrir des profils.',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name}', (tester) async {
      await _pump(
        tester,
        _FakeMatchesApi(matches: ApiResponse.failure('Failed to get matches')),
        c,
      );
      expectNoFrench(['Impossible de charger les matchs', 'Réessayer']);
      expect(find.text('Failed to get matches'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
