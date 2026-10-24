import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/features/matching/screens/filters_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _FakeFiltersApi implements ApiService {
  _FakeFiltersApi({this.saveFails = false});

  final bool saveFails;
  final saved = <Map<String, dynamic>>[];

  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('offline');

  @override
  Future<ApiResponse<Profile>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    saved.add(profileData);
    return saveFails
        ? ApiResponse.failure('Failed to update profile')
        : ApiResponse.success(Profile(id: 1, userId: 1));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeFiltersApi: ${invocation.memberName}');
}

class _Host extends StatelessWidget {
  const _Host(this.api);

  final ApiService api;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => FiltersScreen(apiService: api),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, ApiService api, L10nCase c) async {
  await pumpLocalized(
    tester,
    _Host(api),
    locale: c.locale,
    brightness: c.brightness,
    size: const Size(360, 3000),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _frenchTexts = [
  "Tranche d'âge",
  'Distance maximale',
  'Courant religieux',
  'Pratiques religieuses',
  "Niveau d'études",
  'Réinitialiser',
  'Toutes',
  'Orthodoxe',
  'Massorti',
  'Libéral',
  'Traditionaliste',
  'Loubavitch',
  'Séfarade',
  'Ashkénaze',
  'Casher strict',
  'Prière quotidienne',
  'Mikvé',
  'Lycée',
  'Doctorat',
  'Yeshiva/Sem',
  'Profils vérifiés uniquement',
  'Voir seulement les profils vérifiés',
  'Avec photo uniquement',
  'En ligne maintenant',
  'Débloquer tous les filtres',
  'Passez à mazl+ pour des recherches précises',
];

void main() {
  tearDown(() => PremiumGate.debugPremiumOverride = null);

  testWidgets('French stays word for word', (tester) async {
    PremiumGate.debugPremiumOverride = false;
    await pumpLocalized(
      tester,
      _Host(_FakeFiltersApi()),
      size: const Size(360, 3000),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Filtres'), findsOneWidget);
    expect(find.text('Réinitialiser'), findsOneWidget);
    expect(find.text('18 ans'), findsOneWidget);
    expect(find.text('45 ans'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(find.text('Séfarade'), findsOneWidget);
    expect(find.text('Effacer le filtre taille'), findsNothing);
  });

  testWidgets('English free member', (tester) async {
    PremiumGate.debugPremiumOverride = false;
    await _open(tester, _FakeFiltersApi(), l10nCases.first);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('18 years'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(find.text('Religious movement'), findsOneWidget);
    expect(find.text('Sephardic'), findsOneWidget);
    expect(find.text('Unlock every filter'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
  });

  testWidgets('Russian ages follow the plural rules', (tester) async {
    PremiumGate.debugPremiumOverride = false;
    await _open(
      tester,
      _FakeFiltersApi(),
      const L10nCase(Locale('ru'), Brightness.light),
    );
    expect(find.text('18 лет'), findsOneWidget);
    expect(find.text('45 лет'), findsOneWidget);
  });

  testWidgets(
    'the server still receives the same values whatever the language',
    (tester) async {
      PremiumGate.debugPremiumOverride = true;
      final api = _FakeFiltersApi();
      await _open(tester, api, const L10nCase(Locale('he'), Brightness.light));
      await tester.tap(find.text('אורתודוקסי'));
      await tester.tap(find.text('שמירת שבת'));
      await tester.tap(find.text('כשרות מהודרת'));
      await tester.tap(find.text('תואר ראשון'));
      await tester.pump();
      await tester.tap(find.text('החלת המסננים'));
      await tester.pumpAndSettle();
      expect(api.saved, hasLength(1));
      expect(api.saved.single['denomination'], 'Orthodoxe');
      expect(api.saved.single['observances'], [
        'Shomer Shabbat',
        'Casher strict',
      ]);
      expect(api.saved.single['education'], 'Licence');
    },
  );

  testWidgets('a refused save shows our sentence, not the diagnostic', (
    tester,
  ) async {
    PremiumGate.debugPremiumOverride = true;
    await _open(tester, _FakeFiltersApi(saveFails: true), l10nCases.first);
    await tester.tap(find.text('Orthodox'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Failed to update profile'), findsNothing);
    expect(find.text('Something went wrong while saving'), findsOneWidget);
  });

  testWidgets('English saved confirmation', (tester) async {
    PremiumGate.debugPremiumOverride = true;
    await _open(tester, _FakeFiltersApi(), l10nCases.first);
    await tester.tap(find.text('Orthodox'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Filters saved'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('free member in ${c.name}', (tester) async {
      PremiumGate.debugPremiumOverride = false;
      await _open(tester, _FakeFiltersApi(), c);
      expectNoFrench(_frenchTexts);
      expectDirection(tester, find.byType(AppBar), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('premium member in ${c.name}', (tester) async {
      PremiumGate.debugPremiumOverride = true;
      await _open(tester, _FakeFiltersApi(), c);
      expectNoFrench(_frenchTexts);
      expect(find.text('Débloquer tous les filtres'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
