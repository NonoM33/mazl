import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:mazl/presentation/features/settings/widgets/settings_couple_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../couple/couple_flow_fakes.dart';
import '../../helpers/l10n_helpers.dart';

/// Never disposed: the app's services are singletons, and a ProviderScope
/// disposes the ones it creates, which would break the next test.
final _sharedContainer = ProviderContainer();

const _discoveryLabels = [
  'Localisation',
  'Distance maximale',
  "Tranche d'âge",
  'Nouveaux matchs',
  'Super Likes',
];

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required CoupleService service,
  Size size = const Size(390, 2400),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await service.initialize();
  CoupleService.instanceForTesting = service;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _sharedContainer,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const SettingsScreen(),
      ),
    ),
  );
  await _pumpFor(tester, const Duration(milliseconds: 500));
}

void main() {
  late FakeCoupleApi api;
  late CoupleService service;
  var disposed = false;

  /// A pending request makes the service poll: stop it before the test ends.
  Future<void> stopService(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    disposed = true;
  }

  setUp(() {
    disposed = false;
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(
      api: api,
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() {
    if (!disposed) service.dispose();
  });

  group('coupleDurationLabel', () {
    test('le jour même : Depuis aujourd\'hui', () {
      expect(
        coupleDurationLabel(
          lookupAppLocalizations(kTestLocale),
          DateTime(2026, 10, 23, 8),
          DateTime(2026, 10, 23, 22),
        ),
        "Depuis aujourd'hui",
      );
    });

    test('le lendemain : 1 jour', () {
      expect(
        coupleDurationLabel(
          lookupAppLocalizations(kTestLocale),
          DateTime(2026, 10, 22, 10),
          DateTime(2026, 10, 23, 10),
        ),
        '1 jour',
      );
    });

    test('+5 jours : 5 jours', () {
      expect(
        coupleDurationLabel(lookupAppLocalizations(kTestLocale), DateTime(2026, 10, 18), DateTime(2026, 10, 23)),
        '5 jours',
      );
    });

    test('compte en jours calendaires : 23 h 30 puis 00 h 10 donne 1 jour', () {
      expect(
        coupleDurationLabel(
          lookupAppLocalizations(kTestLocale),
          DateTime(2026, 10, 22, 23, 30),
          DateTime(2026, 10, 23, 0, 10),
        ),
        '1 jour',
      );
    });

    test('un changement d\'heure ne décale pas le compte', () {
      expect(
        coupleDurationLabel(lookupAppLocalizations(kTestLocale), DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
        '2 jours',
      );
    });

    test('une date de début dans le futur ne donne pas de durée négative', () {
      expect(
        coupleDurationLabel(lookupAppLocalizations(kTestLocale), DateTime(2026, 10, 25), DateTime(2026, 10, 23)),
        "Depuis aujourd'hui",
      );
    });
  });

  group('réglages en mode couple', () {
    testWidgets('actif : la découverte et deux notifications disparaissent', (
      tester,
    ) async {
      api.couple = contractCouple();
      await _pumpSettings(tester, service: service);

      for (final label in _discoveryLabels) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Découverte'.toUpperCase()), findsNothing);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Vérification du profil'), findsOneWidget);
      expect(find.text('Mode couple actif'), findsOneWidget);
      expect(find.text('Quitter le mode couple'), findsOneWidget);
    });

    testWidgets('inactif : tout reste comme avant', (tester) async {
      await _pumpSettings(tester, service: service);

      for (final label in _discoveryLabels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Vérification du profil'), findsOneWidget);
      expect(find.text('Activer'), findsOneWidget);
      expect(find.text('Quitter le mode couple'), findsNothing);
    });

    testWidgets('la section Découverte revient quand le couple prend fin', (
      tester,
    ) async {
      api.couple = contractCouple();
      await _pumpSettings(tester, service: service);
      expect(find.text('Localisation'), findsNothing);

      await service.leaveCouple();
      await _pumpFor(tester, const Duration(milliseconds: 300));

      expect(find.text('Localisation'), findsOneWidget);
    });

    testWidgets(
      'à 360 px, aucun libellé de bouton de la carte ne passe sur deux lignes',
      (tester) async {
        api.couple = contractCouple();
        await _pumpSettings(
          tester,
          service: service,
          size: const Size(360, 740),
        );
        // The Language row pushed the card below the fold of a small phone.
        await tester.scrollUntilVisible(
          find.text('Quitter le mode couple'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        for (final label in [
          'Espace couple',
          'Calendrier',
          'Quitter le mode couple',
        ]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          // Unwrapped height = one line; the rendered height must not exceed it.
          final oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
          expect(
            paragraph.size.height,
            lessThanOrEqualTo(oneLine + 0.5),
            reason: label,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'la sortie garde la même feuille de confirmation et le même appel',
      (tester) async {
        api.couple = contractCouple();
        await _pumpSettings(tester, service: service);

        await tester.tap(find.text('Quitter le mode couple'));
        await _pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.text('Quitter'), findsOneWidget);
        expect(find.text('Annuler'), findsOneWidget);

        await tester.tap(find.text('Quitter'));
        await _pumpFor(tester, const Duration(milliseconds: 600));
        expect(api.calls, contains('end:12'));
      },
    );
  });

  group('demande en attente', () {
    testWidgets('la carte annonce la demande au lieu d\'Activer', (
      tester,
    ) async {
      api.sent = [contractSentRequest()];
      await _pumpSettings(tester, service: service);

      expect(find.text('Demande envoyée à Myriam'), findsOneWidget);
      expect(find.text('Annuler la demande'), findsOneWidget);
      expect(find.text('Activer'), findsNothing);
      await stopService(tester);
    });

    testWidgets(
      'Annuler la demande appelle cancelCoupleRequest puis rafraîchit la carte',
      (tester) async {
        api.sent = [contractSentRequest()];
        await _pumpSettings(tester, service: service);

        await tester.tap(find.text('Annuler la demande'));
        await _pumpFor(tester, const Duration(milliseconds: 500));

        expect(api.calls, contains('cancel:77'));
        expect(service.pendingRequest, isNull);
        expect(find.text('Demande envoyée à Myriam'), findsNothing);
        expect(find.text('Activer'), findsOneWidget);
      },
    );
  });
}
