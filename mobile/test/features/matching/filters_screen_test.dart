import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/matching/discover_filters.dart';
import 'package:mazl/core/matching/discover_filters_providers.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/matching/screens/filters_screen.dart';

import '../../presentation/privacy/privacy_fakes.dart';
import 'discover_filters_fakes.dart';

/// The profile service: only the two calls the screen makes, and a record of
/// what it was asked to store.
class _FakeProfileApi implements ApiService {
  _FakeProfileApi({this.updateFails = false});

  final bool updateFails;
  final updates = <Map<String, dynamic>>[];

  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('offline');

  @override
  Future<ApiResponse<Profile>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    updates.add(profileData);
    return updateFails
        ? ApiResponse.failure('Failed to update profile')
        : ApiResponse.success(Profile(id: 1, userId: 1));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeProfileApi: ${invocation.memberName}');
}

Future<void> _open(
  WidgetTester tester, {
  required FakeDiscoverFiltersApi filters,
  _FakeProfileApi? profile,
  FakePrivacyConsentApi? privacy,
}) async {
  tester.view.physicalSize = const Size(390, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      FiltersScreen(apiService: profile ?? _FakeProfileApi()),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.premium,
        builder: (_, _) => const Scaffold(body: Text('ECRAN MAZL+')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverFiltersApiProvider.overrideWithValue(filters),
        privacyConsentApiProvider.overrideWithValue(
          privacy ?? FakePrivacyConsentApi(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text('Appliquer les filtres'));
  // The button spins while the save waits (consent sheet open): never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _acceptConsent(WidgetTester tester) async {
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  await tester.tap(find.text("J'accepte"));
  await tester.pumpAndSettle();
}

void main() {
  group('loading', () {
    testWidgets('shows what the server kept, as the stored answers', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi(
        filters: const DiscoverFilters(
          denominations: ['Massorti', 'Habad'],
          kashrutLevels: ['Strict'],
          onlyVerified: true,
        ),
      );
      await _open(tester, filters: api);

      FilterChip chip(String label) =>
          tester.widget(find.widgetWithText(FilterChip, label));
      expect(chip('Massorti').selected, isTrue);
      expect(chip('Habad').selected, isTrue);
      expect(chip('Orthodoxe').selected, isFalse);
      expect(chip('Strict').selected, isTrue);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(
                SwitchListTile,
                'Profils vérifiés uniquement',
              ),
            )
            .value,
        isTrue,
      );
      expect(find.text('Appliquer les filtres'), findsNothing);
    });

    testWidgets('the removed filters (studies, height, online) are gone', (
      tester,
    ) async {
      await _open(tester, filters: FakeDiscoverFiltersApi());
      for (final removed in [
        "Niveau d'études",
        'Taille',
        'En ligne maintenant',
        'Casher',
        'Séfarade',
      ]) {
        expect(find.text(removed), findsNothing, reason: removed);
      }
    });

    testWidgets('a failed load says so and retrying loads again', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi()..failLoad = true;
      await _open(tester, filters: api);
      expect(
        find.text("Vos filtres avancés n'ont pas pu être chargés."),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilterChip, 'Massorti'), findsNothing);
      // Age and distance stay usable.
      expect(find.text('Tranche d\'âge'), findsOneWidget);

      api.failLoad = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(api.loads, 2);
      expect(find.widgetWithText(FilterChip, 'Massorti'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets(
      'sends the chosen stored answers to the filters, nothing to the profile',
      (tester) async {
        final api = FakeDiscoverFiltersApi();
        final profile = _FakeProfileApi();
        await _open(tester, filters: api, profile: profile);

        await tester.tap(find.widgetWithText(FilterChip, 'Orthodoxe'));
        await tester.tap(find.widgetWithText(FilterChip, 'Glatt'));
        await tester.tap(find.text('Avec photo uniquement'));
        await tester.pump();
        await _apply(tester);

        expect(api.saved, hasLength(1));
        final sent = api.saved.single;
        expect(sent.denominations, containsAll(['Orthodox', 'Orthodoxe']));
        expect(sent.denominations, isNot(contains('Massorti')));
        expect(sent.kashrutLevels, ['Glatt']);
        expect(sent.shabbatObservances, isNull);
        expect(sent.onlyWithPhoto, isTrue);
        expect(sent.onlyVerified, isFalse);
        expect(profile.updates, isEmpty);
        expect(find.text('Filtres enregistrés'), findsOneWidget);
      },
    );

    testWidgets('age and distance go to the profile, and only those', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi();
      final profile = _FakeProfileApi();
      await _open(tester, filters: api, profile: profile);

      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pump();
      await _apply(tester);

      expect(profile.updates, hasLength(1));
      expect(profile.updates.single.keys.toSet(), {
        'ageMin',
        'ageMax',
        'distanceMax',
      });
      expect(api.saved, isEmpty);
    });

    testWidgets('a profile refusal shows our sentence and keeps the screen', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi();
      await _open(
        tester,
        filters: api,
        profile: _FakeProfileApi(updateFails: true),
      );
      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pump();
      await _apply(tester);

      expect(find.text('Failed to update profile'), findsNothing);
      expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
      expect(find.text('Appliquer les filtres'), findsOneWidget);
      expect(api.saved, isEmpty);
    });

    testWidgets('reset clears every criterion and sends the empty set', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi(
        filters: const DiscoverFilters(
          denominations: ['Massorti'],
          onlyWithPhoto: true,
        ),
      );
      await _open(tester, filters: api);
      await tester.tap(find.text('Réinitialiser'));
      await tester.pump();
      await _apply(tester);

      expect(api.saved.single, DiscoverFilters.none);
    });
  });

  group('without mazl+', () {
    testWidgets('the advanced criteria are locked and the offer is shown', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi(plus: false);
      await _open(tester, filters: api);

      expect(find.text('mazl+'), findsNWidgets(4));
      expect(find.text('Débloquer tous les filtres'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilterChip, 'Massorti'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text('Appliquer les filtres'), findsNothing);
      expect(api.saved, isEmpty);
    });

    testWidgets(
      '"Voir" opens the subscription screen, then asks the server again',
      (tester) async {
        final api = FakeDiscoverFiltersApi(plus: false);
        await _open(tester, filters: api);
        await tester.tap(find.text('Voir'));
        await tester.pumpAndSettle();
        expect(find.text('ECRAN MAZL+'), findsOneWidget);

        api.plus = true;
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();
        expect(api.loads, 2);
        expect(find.text('Débloquer tous les filtres'), findsNothing);
        expect(find.text('mazl+'), findsNothing);
      },
    );

    testWidgets('age and distance stay free', (tester) async {
      final profile = _FakeProfileApi();
      await _open(
        tester,
        filters: FakeDiscoverFiltersApi(plus: false),
        profile: profile,
      );
      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pump();
      await _apply(tester);
      expect(profile.updates, hasLength(1));
    });

    testWidgets('a 402 from the server opens the subscription screen', (
      tester,
    ) async {
      // The server says no although the app thought the member was mazl+
      // (the subscription expired meanwhile).
      final api = FakeDiscoverFiltersApi()..refusals.add(plusRequired());
      await _open(tester, filters: api);
      await tester.tap(find.widgetWithText(FilterChip, 'Massorti'));
      await tester.pump();
      await _apply(tester);

      expect(find.text('ECRAN MAZL+'), findsOneWidget);
      expect(find.text('Filtres enregistrés'), findsNothing);
    });
  });

  group('art. 9 consent', () {
    testWidgets(
      'a 409 opens the consent sheet, and once accepted the save is retried',
      (tester) async {
        final api = FakeDiscoverFiltersApi()..refusals.add(consentRequired());
        final privacy = FakePrivacyConsentApi();
        await _open(tester, filters: api, privacy: privacy);
        await tester.tap(find.widgetWithText(FilterChip, 'Massorti'));
        await tester.pump();
        await _apply(tester);

        expect(find.text(consentText), findsOneWidget);
        await _acceptConsent(tester);

        expect(privacy.calls, contains('put:true:2026-10-24'));
        expect(api.saved, hasLength(2));
        expect(api.saved.last.denominations, ['Massorti', 'Masorti']);
        expect(find.text('Filtres enregistrés'), findsOneWidget);
      },
    );

    testWidgets('declining the consent saves nothing and says why', (
      tester,
    ) async {
      final api = FakeDiscoverFiltersApi()..refusals.add(consentRequired());
      await _open(tester, filters: api);
      await tester.tap(find.widgetWithText(FilterChip, 'Massorti'));
      await tester.pump();
      await _apply(tester);

      await tester.tap(find.text('Continuer sans'));
      await tester.pumpAndSettle();

      expect(api.saved, hasLength(1));
      expect(find.textContaining('demandent votre accord'), findsOneWidget);
      expect(find.text('Appliquer les filtres'), findsOneWidget);
    });

    testWidgets('a second 409 after the consent does not loop', (tester) async {
      final api = FakeDiscoverFiltersApi()
        ..refusals.addAll([consentRequired(), consentRequired()]);
      await _open(tester, filters: api);
      await tester.tap(find.widgetWithText(FilterChip, 'Massorti'));
      await tester.pump();
      await _apply(tester);
      await _acceptConsent(tester);

      expect(api.saved, hasLength(2));
      expect(find.text('Appliquer les filtres'), findsOneWidget);
    });
  });

  testWidgets('another failure shows our sentence, not the diagnostic', (
    tester,
  ) async {
    final api = FakeDiscoverFiltersApi()
      ..refusals.add(ApiResponse.failure('boom', ApiErrorKind.server));
    await _open(tester, filters: api);
    await tester.tap(find.widgetWithText(FilterChip, 'Massorti'));
    await tester.pump();
    await _apply(tester);

    expect(find.text('boom'), findsNothing);
    expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
  });
}
