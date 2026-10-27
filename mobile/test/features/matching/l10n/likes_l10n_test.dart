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
const _frenchFree = ['12 personnes vous ont aimé', 'Quelqu\'un'];

void main() {
  testWidgets('English free member sees the real count', (tester) async {
    await _pump(tester, _free(12), l10nCases.first);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('12 people liked you'), findsOneWidget);
    expect(find.text('Someone'), findsWidgets);
    expect(find.text('See who liked you with mazl+'), findsOneWidget);
    expect(find.byType(MazlPlusPill), findsOneWidget);
  });

  testWidgets('one like is singular, and not rounded up', (tester) async {
    await _pump(tester, _free(1), l10nCases.first);
    expect(find.text('1 person liked you'), findsOneWidget);
  });

  // A word per number: the plural form comes from the REAL count.
  for (final (count, text) in [
    (1, '1 человек Вас лайкнул'),
    (3, '3 человека Вас лайкнули'),
    (12, '12 человек Вас лайкнули'),
    (21, '21 человек Вас лайкнул'),
  ]) {
    testWidgets('Russian $count: $text', (tester) async {
      await _pump(
        tester,
        _free(count),
        const L10nCase(Locale('ru'), Brightness.light),
      );
      expect(find.text(text), findsOneWidget);
    });
  }

  for (final (count, text) in [
    (1, 'אדם אחד אהב אותך'),
    (2, 'שני אנשים אהבו אותך'),
    (12, '12 אנשים אהבו אותך'),
  ]) {
    testWidgets('Hebrew $count: $text', (tester) async {
      await _pump(
        tester,
        _free(count),
        const L10nCase(Locale('he'), Brightness.light),
      );
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(tester, LikesScreen(apiService: _free(12)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('12 personnes vous ont aimé'), findsOneWidget);
    expect(find.text('Quelqu\'un'), findsWidgets);
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
      expect(find.textContaining('Jeanne'), findsNothing);
      expect(find.bySemanticsLabel('Retour'), findsNothing);
      expectDirection(tester, find.byType(MazlPlusPill), c);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('the like preview sheet in ${c.name}', (tester) async {
      await _pump(tester, _premium(), c);
      await tester.tap(find.byType(LikeCard).first);
      await tester.pumpAndSettle();
      expectNoFrench(["J'aime", 'Passer']);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
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

  testWidgets('English like preview sheet', (tester) async {
    await _pump(tester, _premium(), l10nCases.first);
    await tester.tap(find.byType(LikeCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Pass'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
  });

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
