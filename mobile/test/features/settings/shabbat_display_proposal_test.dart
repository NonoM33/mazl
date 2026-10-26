import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/core/services/rest_display_content.dart';
import 'package:mazl/core/services/shabbat_display_proposal.dart';
import 'package:mazl/presentation/features/settings/shabbat_place.dart';
import 'package:mazl/presentation/features/settings/widgets/shabbat_display_proposal_host.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// La proposition de lancer l'affichage : seulement sur un iPhone Duo posé en
// tente (fermé, en paysage), dans les quatre heures qui précèdent l'allumage
// de Shabbat ou d'une fête. Hebcal, Paris, vendredi 9 janvier 2026 : allumage
// à 15:55 UTC.

const _title = 'Poser le téléphone en tente pour ce soir ?';
const _launch = 'Lancer l\'affichage';
const _later = 'Pas maintenant';

final _resolver = RestDisplayResolver();

// Trois heures avant l'allumage, puis presque sept heures avant.
final _fridayAfternoon = DateTime.utc(2026, 1, 9, 13);
final _fridayMorning = DateTime.utc(2026, 1, 9, 9, 10);
final _shabbatDay = DateTime.utc(2026, 1, 10, 11);
final _wednesday = DateTime.utc(2026, 1, 7, 11);
// Pessah : allumage du mercredi 1er avril 2026, vers 17:40 UTC.
final _pesachAfternoon = DateTime.utc(2026, 4, 1, 14, 30);
final _nextFriday = DateTime.utc(2026, 1, 16, 13);

class _Dismissals implements ProposalDismissals {
  _Dismissals([this.answered]);

  DateTime? answered;
  final List<DateTime> answers = [];

  @override
  Future<DateTime?> lastAnswered() async => answered;

  @override
  Future<void> answer(DateTime entry) async {
    answered = entry;
    answers.add(entry);
  }
}

class _Harness {
  _Harness({DateTime? now, ProposalDismissals? dismissals})
    : now = now ?? _fridayAfternoon,
      dismissals = dismissals ?? _Dismissals();

  DateTime now;
  final ProposalDismissals dismissals;
  int launches = 0;
  int placeReads = 0;

  Widget host() => ShabbatDisplayProposalHost(
    onLaunch: () => launches++,
    clock: () => now,
    dismissals: dismissals,
    placeLoader: () async {
      placeReads++;
      return const ShabbatPlace(
        location: ShabbatLocation.paris,
        isDefault: true,
      );
    },
    child: const Scaffold(body: Center(child: Text('PAGE'))),
  );
}

Future<DuoPoseController> _pumpInPose(
  WidgetTester tester,
  DuoPose pose,
  _Harness harness, {
  Locale locale = kTestLocale,
}) async {
  final controller = DuoPoseController(pose);
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: harness.host(),
    ),
  );
  await settleFold(tester);
  await tester.pump();
  return controller;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

  group('la règle', () {
    RestDisplayContent at(DateTime now) => _resolver.resolve(now: now);
    bool propose(
      DateTime now, {
      FoldState? fold,
      Size size = const Size(678, 466),
    }) => shouldProposeShabbatDisplay(
      content: at(now),
      now: now,
      fold: fold ?? DuoPose.tent.foldState,
      size: size,
    );

    test('en tente, trois heures avant l\'allumage : oui', () {
      expect(propose(_fridayAfternoon), isTrue);
    });

    test('presque sept heures avant : pas encore', () {
      expect(propose(_fridayMorning), isFalse);
    });

    test('à la limite des quatre heures', () {
      // 15:55:31 UTC moins 4 h.
      expect(propose(DateTime.utc(2026, 1, 9, 11, 56)), isTrue);
      expect(propose(DateTime.utc(2026, 1, 9, 11, 54)), isFalse);
    });

    test('Shabbat commencé ou en cours : non', () {
      expect(propose(DateTime.utc(2026, 1, 9, 16)), isFalse);
      expect(propose(_shabbatDay), isFalse);
    });

    test('un jour ordinaire : non', () {
      expect(propose(_wednesday), isFalse);
    });

    test('la veille d\'une fête : oui', () {
      expect(propose(_pesachAfternoon), isTrue);
    });

    test('fermé mais debout (portrait) : non', () {
      expect(
        propose(
          _fridayAfternoon,
          fold: DuoPose.closed.foldState,
          size: DuoPose.closed.size,
        ),
        isFalse,
      );
    });

    test('ouvert, même en paysage : non', () {
      for (final pose in [
        DuoPose.openLandscape,
        DuoPose.halfOpenBook,
        DuoPose.halfOpenLaptop,
        DuoPose.splitView,
      ]) {
        expect(
          propose(_fridayAfternoon, fold: pose.foldState, size: pose.size),
          isFalse,
          reason: pose.name,
        );
      }
    });

    test('un autre téléphone, en paysage : non', () {
      expect(propose(_fridayAfternoon, fold: FoldState.unknown), isFalse);
    });

    test('là où le soleil ne se couche pas : non (aucune heure)', () {
      final polar = _resolver.resolve(
        now: DateTime.utc(2026, 6, 16, 12),
        location: const ShabbatLocation(
          name: 'Nord',
          latitude: 78.2232,
          longitude: 15.6267,
        ),
      );

      expect(
        shouldProposeShabbatDisplay(
          content: polar,
          now: DateTime.utc(2026, 6, 16, 12),
          fold: DuoPose.tent.foldState,
          size: DuoPose.tent.size,
        ),
        isFalse,
      );
    });
  });

  group('la carte', () {
    testWidgets('en tente, le vendredi après-midi : elle se montre, et ses '
        'boutons sont dans la zone sûre', (tester) async {
      await _pumpInPose(tester, DuoPose.tent, _Harness());

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_launch), findsOneWidget);
      expect(find.text(_later), findsOneWidget);
      expectFitsDuoPose(tester, DuoPose.tent, 'proposition');
    });

    testWidgets('elle tient aussi en russe et en hébreu', (tester) async {
      for (final locale in [const Locale('ru'), const Locale('he')]) {
        await _pumpInPose(tester, DuoPose.tent, _Harness(), locale: locale);

        expect(find.byType(TextButton), findsNWidgets(2));
        expectFitsDuoPose(
          tester,
          DuoPose.tent,
          'proposition ${locale.languageCode}',
        );
      }
    });

    for (final pose in DuoPose.values.where((p) => p != DuoPose.tent)) {
      testWidgets('${pose.name} : aucune proposition', (tester) async {
        final harness = _Harness();
        await _pumpInPose(tester, pose, harness);

        expect(find.text(_title), findsNothing);
        expect(harness.placeReads, 0, reason: 'le lieu n\'est pas même lu');
      });
    }

    testWidgets('un autre téléphone en paysage : aucune proposition, aucun '
        'appel', (tester) async {
      final harness = _Harness();
      tester.view.physicalSize = const Size(2556, 1179);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          home: harness.host(),
        ),
      );
      await tester.pump();

      expect(find.text(_title), findsNothing);
      expect(harness.placeReads, 0);
    });

    testWidgets('trop tôt, ou un jour ordinaire : rien, et pas d\'appel '
        'inutile', (tester) async {
      final early = _Harness(now: _fridayMorning);
      await _pumpInPose(tester, DuoPose.tent, early);
      expect(find.text(_title), findsNothing);

      final ordinary = _Harness(now: _wednesday);
      await _pumpInPose(tester, DuoPose.tent, ordinary);
      expect(find.text(_title), findsNothing);
      expect(ordinary.placeReads, 0, reason: 'loin de vendredi');
    });

    testWidgets('pendant Shabbat : rien', (tester) async {
      await _pumpInPose(tester, DuoPose.tent, _Harness(now: _shabbatDay));

      expect(find.text(_title), findsNothing);
    });

    testWidgets('la veille de Pessah : elle se montre', (tester) async {
      await _pumpInPose(tester, DuoPose.tent, _Harness(now: _pesachAfternoon));

      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('la fenêtre s\'ouvre avec le temps', (tester) async {
      final harness = _Harness(now: _fridayMorning);
      await _pumpInPose(tester, DuoPose.tent, harness);
      expect(find.text(_title), findsNothing);

      harness.now = DateTime.utc(2026, 1, 9, 12, 30);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();

      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('elle suit la pose : ouvrir le téléphone la retire, le '
        'refermer la rend', (tester) async {
      final harness = _Harness();
      final controller = await _pumpInPose(tester, DuoPose.tent, harness);
      expect(find.text(_title), findsOneWidget);

      await controller.moveTo(tester, DuoPose.openLandscape);
      await tester.pump();
      expect(find.text(_title), findsNothing);

      await controller.moveTo(tester, DuoPose.tent);
      await tester.pump();
      expect(find.text(_title), findsOneWidget);
    });
  });

  group('la réponse du membre', () {
    testWidgets('lancer : l\'affichage s\'ouvre, la carte ne revient pas', (
      tester,
    ) async {
      final harness = _Harness();
      await _pumpInPose(tester, DuoPose.tent, harness);

      await tester.tap(find.text(_launch));
      await tester.pump();

      expect(harness.launches, 1);
      expect(find.text(_title), findsNothing);
      expect((harness.dismissals as _Dismissals).answers, hasLength(1));

      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
      expect(find.text(_title), findsNothing);
    });

    testWidgets('pas maintenant : rien ne se lance, la carte ne revient ni '
        'à la minute suivante ni au prochain lancement', (tester) async {
      final harness = _Harness();
      await _pumpInPose(tester, DuoPose.tent, harness);

      await tester.tap(find.text(_later));
      await tester.pump();

      expect(harness.launches, 0);
      expect(find.text(_title), findsNothing);
      await tester.pump(const Duration(minutes: 3));
      await tester.pump();
      expect(find.text(_title), findsNothing);

      // Un nouveau lancement de l'app : la réponse est retenue.
      final relaunched = _Harness(dismissals: harness.dismissals);
      await _pumpInPose(tester, DuoPose.tent, relaunched);
      expect(find.text(_title), findsNothing);
    });

    testWidgets('le vendredi suivant, elle revient', (tester) async {
      final answered = _Dismissals(DateTime.utc(2026, 1, 9, 15, 55, 31));
      await _pumpInPose(
        tester,
        DuoPose.tent,
        _Harness(now: _nextFriday, dismissals: answered),
      );

      expect(find.text(_title), findsOneWidget);
    });
  });
}
