import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/matching/discover_filters_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/matching/screens/filters_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import '../discover_filters_fakes.dart';
import 'l10n_harness.dart';

class _FakeProfileApi implements ApiService {
  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('offline');

  @override
  Future<ApiResponse<Profile>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    return ApiResponse.success(Profile(id: 1, userId: 1));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeProfileApi: ${invocation.memberName}');
}

class _Host extends StatelessWidget {
  const _Host(this.profile);

  final ApiService profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => FiltersScreen(apiService: profile),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  FakeDiscoverFiltersApi filters,
  L10nCase c, {
  ApiService? profile,
}) async {
  await pumpLocalized(
    tester,
    _Host(profile ?? _FakeProfileApi()),
    locale: c.locale,
    brightness: c.brightness,
    size: const Size(360, 3200),
    overrides: [discoverFiltersApiProvider.overrideWithValue(filters)],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _frenchTexts = [
  "Tranche d'âge",
  'Distance maximale',
  'Courant religieux',
  'Réinitialiser',
  'Massorti',
  'Traditionaliste',
  'Orthodoxe moderne',
  'À la maison',
  'Partiellement',
  'Très observant',
  'Profils vérifiés uniquement',
  'Voir seulement les profils vérifiés',
  'Avec photo uniquement',
  'Débloquer tous les filtres',
  'Passez à mazl+ pour des recherches précises',
  "Plusieurs choix possibles. Les profils qui n'ont pas répondu ne sont pas proposés.",
];

void main() {
  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      _Host(_FakeProfileApi()),
      size: const Size(360, 3200),
      overrides: [
        discoverFiltersApiProvider.overrideWithValue(
          FakeDiscoverFiltersApi(plus: false),
        ),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Filtres'), findsOneWidget);
    expect(find.text('Réinitialiser'), findsOneWidget);
    expect(find.text('18 ans'), findsOneWidget);
    expect(find.text('45 ans'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(find.text('Courant religieux'), findsOneWidget);
    expect(find.text('Kashrout'), findsOneWidget);
    expect(find.text('Shabbat'), findsOneWidget);
    expect(find.text('Habad'), findsOneWidget);
    expect(find.text('Strict'), findsOneWidget);
    expect(find.text('Débloquer tous les filtres'), findsOneWidget);
  });

  testWidgets('English without mazl+', (tester) async {
    await _open(tester, FakeDiscoverFiltersApi(plus: false), l10nCases.first);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('18 years'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(find.text('Religious movement'), findsOneWidget);
    expect(find.text('Secular'), findsOneWidget);
    expect(find.text('Unlock every filter'), findsOneWidget);
  });

  testWidgets('Russian ages follow the plural rules', (tester) async {
    await _open(
      tester,
      FakeDiscoverFiltersApi(),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('18 лет'), findsOneWidget);
    expect(find.text('45 лет'), findsOneWidget);
  });

  testWidgets(
    'the server receives the same stored answers whatever the language',
    (tester) async {
      final api = FakeDiscoverFiltersApi();
      await _open(tester, api, const L10nCase(Locale('he'), Brightness.light));
      await tester.tap(find.text('אורתודוקסי (חרדי)'));
      await tester.tap(find.text('גלאט'));
      await tester.tap(find.text('שמירה קפדנית'));
      await tester.pump();
      await tester.tap(find.text('החלת המסננים'));
      await tester.pumpAndSettle();
      expect(api.saved, hasLength(1));
      expect(api.saved.single.denominations, ['Orthodox', 'Orthodoxe']);
      expect(api.saved.single.kashrutLevels, ['Glatt']);
      expect(api.saved.single.shabbatObservances, [
        'Tres observant',
        'Très observant',
        'tres_observant',
      ]);
    },
  );

  testWidgets('a refused save shows our sentence, not the diagnostic', (
    tester,
  ) async {
    final api = FakeDiscoverFiltersApi()
      ..refusals.add(ApiResponse.failure('boom', ApiErrorKind.server));
    await _open(tester, api, l10nCases.first);
    await tester.tap(find.text('Orthodox'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('boom'), findsNothing);
    expect(find.text('Something went wrong while saving'), findsOneWidget);
  });

  testWidgets('English saved confirmation', (tester) async {
    await _open(tester, FakeDiscoverFiltersApi(), l10nCases.first);
    await tester.tap(find.text('Orthodox'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Filters saved'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('member without mazl+ in ${c.name}', (tester) async {
      await _open(tester, FakeDiscoverFiltersApi(plus: false), c);
      expectNoFrench(_frenchTexts);
      expectDirection(tester, find.byType(AppBar), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mazl+ member in ${c.name}', (tester) async {
      await _open(tester, FakeDiscoverFiltersApi(), c);
      expectNoFrench(_frenchTexts);
      expect(find.text('Débloquer tous les filtres'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed load in ${c.name}', (tester) async {
      await _open(tester, FakeDiscoverFiltersApi()..failLoad = true, c);
      expectNoFrench([
        "Vos filtres avancés n'ont pas pu être chargés.",
        'Filtres avancés',
        'Réessayer',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
