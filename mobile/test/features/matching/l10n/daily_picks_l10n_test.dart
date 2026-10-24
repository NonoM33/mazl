import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/matching/screens/daily_picks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakePicksApi implements ApiService {
  _FakePicksApi({this.picks = const [], this.failure});

  final List<Profile> picks;
  final ApiResponse<List<Profile>>? failure;

  @override
  Future<ApiResponse<List<Profile>>> getDailyPicks() async =>
      failure ?? ApiResponse.success(picks);

  @override
  Future<ApiResponse<List<Profile>>> getDiscoverProfiles({
    int limit = 20,
    int offset = 0,
  }) async => failure ?? ApiResponse.success(picks);

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendSwipe({
    required int targetUserId,
    required String action,
  }) async => ApiResponse.success(<String, dynamic>{'match': true});

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePicksApi: ${invocation.memberName}');
}

List<Profile> _profiles(int n) => [
  for (var i = 1; i <= n; i++)
    Profile(
      id: i,
      userId: 100 + i,
      displayName: 'Jeanne$i',
      age: 20 + i,
      location: 'Paris',
      isVerified: i.isEven,
    ),
];

Future<void> _pump(WidgetTester tester, ApiService api, L10nCase c) async {
  await pumpLocalized(
    tester,
    DailyPicksScreen(apiService: api),
    locale: c.locale,
    brightness: c.brightness,
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

const _frenchTexts = [
  'Sélections du jour',
  '3 profils sélectionnés pour vous',
  'Vous avez vu toutes vos sélections.',
  'Découvrir plus de profils',
  'Réessayer',
  'Erreur lors du chargement',
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      DailyPicksScreen(apiService: _FakePicksApi(picks: _profiles(3))),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Sélections du jour'), findsOneWidget);
    expect(find.text('3 profils sélectionnés pour vous'), findsOneWidget);
    expect(find.textContaining('Mis à jour dans'), findsOneWidget);
    expect(find.text('Pick'), findsWidgets);
  });

  testWidgets('English picks', (tester) async {
    await _pump(tester, _FakePicksApi(picks: _profiles(3)), l10nCases.first);
    expect(find.text('Daily picks'), findsOneWidget);
    expect(find.text('3 profiles picked for you'), findsOneWidget);
    expect(find.textContaining('Refreshes in'), findsOneWidget);
    expect(find.text('Pick'), findsWidgets);
  });

  testWidgets('one pick is singular, Hebrew has a dual', (tester) async {
    await _pump(tester, _FakePicksApi(picks: _profiles(1)), l10nCases.first);
    expect(find.text('1 profile picked for you'), findsOneWidget);
  });

  testWidgets('Hebrew dual', (tester) async {
    await _pump(
      tester,
      _FakePicksApi(picks: _profiles(2)),
      const L10nCase(Locale('he'), Brightness.light),
    );
    expect(find.text('שני פרופילים נבחרו בשבילך'), findsOneWidget);
  });

  testWidgets('English empty state', (tester) async {
    await _pump(tester, _FakePicksApi(), l10nCases.first);
    expect(find.text("You've seen all your picks."), findsOneWidget);
    expect(find.textContaining('Next picks in'), findsOneWidget);
    expect(find.text('Discover more profiles'), findsOneWidget);
  });

  testWidgets('English match dialog after a like', (tester) async {
    await _pump(tester, _FakePicksApi(picks: _profiles(2)), l10nCases.first);
    await tester.tap(find.byIcon(LucideIcons.heart).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("It's a match!"), findsOneWidget);
    expect(find.text('You matched with Jeanne1.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Send a message'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('picks in ${c.name}', (tester) async {
      await _pump(tester, _FakePicksApi(picks: _profiles(3)), c);
      expectNoFrench(_frenchTexts);
      expect(find.textContaining('Mis à jour dans'), findsNothing);
      expectDirection(tester, find.byType(AppBar), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state in ${c.name}', (tester) async {
      await _pump(tester, _FakePicksApi(), c);
      expectNoFrench(_frenchTexts);
      expect(find.textContaining('Prochaines sélections'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('match dialog in ${c.name}', (tester) async {
      await _pump(tester, _FakePicksApi(picks: _profiles(2)), c);
      await tester.tap(find.byIcon(LucideIcons.heart).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expectNoFrench([
        "C'est un match",
        'Vous avez matché avec Jeanne1.',
        'Continuer',
        'Envoyer un message',
      ]);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name} hides the diagnostic', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakePicksApi(
          failure: ApiResponse.failure(
            'Failed to get picks',
            ApiErrorKind.server,
          ),
        ),
        c,
      );
      expect(find.text('Failed to get picks'), findsNothing);
      expectNoFrench(_frenchTexts);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
