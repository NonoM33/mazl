import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:mazl/presentation/features/likes/widgets/like_widgets.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakeLikesApi implements ApiService {
  _FakeLikesApi(this.result);

  final ApiResponse<LikesData> result;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeLikesApi: ${invocation.memberName}');
}

List<LikeProfile> _likes(int n) => [
  for (var i = 1; i <= n; i++)
    LikeProfile(
      userId: i,
      displayName: 'Jeanne$i',
      age: 20 + i,
      likedAt: DateTime(2026, 10, 1),
    ),
];

_FakeLikesApi _free(int total) => _FakeLikesApi(
  ApiResponse.success(
    LikesData(count: total, isPremium: false, likes: _likes(3)),
  ),
);

_FakeLikesApi _premium() => _FakeLikesApi(
  ApiResponse.success(LikesData(count: 2, isPremium: true, likes: _likes(2))),
);

Future<void> _pump(WidgetTester tester, ApiService api, L10nCase c) async {
  await pumpLocalized(
    tester,
    LikesScreen(apiService: api),
    locale: c.locale,
    brightness: c.brightness,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

const _en = Locale('en');
const _frenchFree = [
  'ILS VOUS ONT AIMÉ · 10+',
  '10+ personnes attendent votre réponse.',
];

void main() {
  testWidgets('English free member sees the banded count', (tester) async {
    await _pump(tester, _free(12), l10nCases.first);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('THEY LIKED YOU · 10+'), findsOneWidget);
    expect(find.text('10+ people are waiting for your reply.'), findsOneWidget);
    expect(find.text('See who liked you with mazl+'), findsOneWidget);
    expect(find.byType(MazlPlusPill), findsOneWidget);
  });

  testWidgets('one like waiting is singular in every language', (tester) async {
    await _pump(tester, _free(1), l10nCases.first);
    expect(find.text('1 person is waiting for your reply.'), findsOneWidget);
  });

  testWidgets('Russian picks the plural form from the real count', (
    tester,
  ) async {
    await _pump(
      tester,
      _free(3),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('3 человека ждут Вашего ответа.'), findsOneWidget);
  });

  testWidgets('Russian band « 10+ » takes the many form', (tester) async {
    await _pump(
      tester,
      _free(12),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('10+ человек ждут Вашего ответа.'), findsOneWidget);
  });

  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(tester, LikesScreen(apiService: _free(12)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('ILS VOUS ONT AIMÉ · 10+'), findsOneWidget);
    expect(find.text('10+ personnes attendent votre réponse.'), findsOneWidget);
  });

  testWidgets('the brand stays glued to its plus in Hebrew', (tester) async {
    await pumpLocalized(
      tester,
      Scaffold(
        body: MazlPlusPill(
          label: 'לראות מי אהב אותך עם mazl+‎',
          onPressed: () {},
        ),
      ),
      locale: const Locale('he'),
    );
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MazlPlusPill),
        matching: find.byType(Text),
      ),
    );
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.map((s) => s.text), ['mazl', '+', '‎']);
  });

  for (final c in l10nCases) {
    testWidgets('free member in ${c.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _free(12), c);
      expectNoFrench(_frenchFree);
      expect(find.bySemanticsLabel('Profil masqué'), findsNothing);
      expect(find.bySemanticsLabel('Retour'), findsNothing);
      expectDirection(tester, find.byType(MazlPlusPill), c);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('premium member in ${c.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _premium(), c);
      expect(find.byType(LikeCard), findsNWidgets(2));
      for (final label in [
        'Passer Jeanne1',
        'Aimer Jeanne1',
        'Voir le like de Jeanne1, 21',
      ]) {
        expect(find.bySemanticsLabel(label), findsNothing, reason: label);
      }
      expect(find.text('Anonyme'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('empty list in ${c.name}', (tester) async {
      await _pump(
        tester,
        _FakeLikesApi(
          ApiResponse.success(LikesData(count: 0, isPremium: false, likes: [])),
        ),
        c,
      );
      expectNoFrench([
        'Pas encore de likes',
        'Continuez à découvrir des profils et complétez votre profil pour attirer plus de likes.',
        'Découvrir des profils',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name}', (tester) async {
      await _pump(
        tester,
        _FakeLikesApi(ApiResponse.failure('Failed to get likes')),
        c,
      );
      expect(find.text('Failed to get likes'), findsNothing);
      expectNoFrench(['Erreur de chargement', 'Réessayer']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English premium card labels and empty state', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _premium(), l10nCases.first);
    expect(find.bySemanticsLabel('Pass on Jeanne1'), findsOneWidget);
    expect(find.bySemanticsLabel('Like Jeanne1'), findsOneWidget);
    expect(find.bySemanticsLabel("View Jeanne1, 21's like"), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('English failed load says it in English', (tester) async {
    await pumpLocalized(
      tester,
      LikesScreen(
        apiService: _FakeLikesApi(ApiResponse.failure('Failed to get likes')),
      ),
      locale: _en,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Couldn’t load'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
