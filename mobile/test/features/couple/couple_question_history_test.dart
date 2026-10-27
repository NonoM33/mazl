import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_question_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import 'couple_flow_fakes.dart';
import 'l10n_space/text_fit.dart';
import '../duo/duo_geometry.dart';

// `/couple/questions`: the history of the answers. Shapes from
// docs/couple/ESPACE-COUPLE.md §5: only the questions the caller answered.

Map<String, dynamic> _entry(
  int id, {
  String? theirs = 'Sa reponse',
  String asked = '2026-11-03',
}) => {
  'id': id,
  'text': 'Question numero $id ?',
  'myAnswer': 'Ma reponse $id',
  'partnerAnswer': theirs,
  'askedOn': asked,
};

Map<String, dynamic> _history(List<Map<String, dynamic>> questions) =>
    ok({'questions': questions});

Future<FakeCoupleTransport> _pump(
  WidgetTester tester, {
  required void Function(FakeCoupleTransport) setUp,
  bool inCouple = true,
  Locale locale = kTestLocale,
  DuoPoseController? pose,
  Size size = const Size(420, 1600),
}) async {
  if (pose == null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues({});
  final api = FakeCoupleApi()..couple = inCouple ? contractCouple() : null;
  final service = CoupleService.forTesting(api: api);
  addTearDown(service.dispose);
  await tester.runAsync(service.refresh);
  final transport = FakeCoupleTransport();
  setUp(transport);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: pose == null ? null : duoAppBuilder(pose),
      home: CoupleQuestionHistoryScreen(
        api: CoupleDailyApi(transport: transport, callerId: () => 12),
        couple: service,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return transport;
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('les deux reponses de chaque question, par les prenoms', (
    tester,
  ) async {
    final t = await _pump(
      tester,
      setUp: (t) => t.reply(
        'GET /api/couple/12/questions',
        _history([_entry(2), _entry(1, asked: '2026-11-02')]),
      ),
    );

    expect(t.calls, ['GET /api/couple/12/questions']);
    expect(find.text('Vos réponses'), findsOneWidget);
    expect(find.text('Question numero 2 ?'), findsOneWidget);
    expect(find.text('Ma reponse 2'), findsOneWidget);
    expect(find.text('Sa reponse'), findsNWidgets(2));
    expect(find.text('VOUS'), findsNWidgets(2));
    expect(find.text('MYRIAM'), findsNWidgets(2));
    expect(find.text('3 NOVEMBRE 2026'), findsOneWidget);
    expect(find.text('2 NOVEMBRE 2026'), findsOneWidget);
  });

  testWidgets('une question sans reponse de l\'autre le dit', (tester) async {
    await _pump(
      tester,
      setUp: (t) => t.reply(
        'GET /api/couple/12/questions',
        _history([_entry(5, theirs: null)]),
      ),
    );

    expect(find.text('Ma reponse 5'), findsOneWidget);
    expect(find.text('Myriam n\'a pas répondu'), findsOneWidget);
  });

  testWidgets('route absente (404) : une phrase utile, pas d\'erreur', (
    tester,
  ) async {
    await _pump(
      tester,
      setUp: (t) => t.reply('GET /api/couple/12/questions', error('Not Found')),
    );

    expect(find.text('Pas encore de réponses'), findsOneWidget);
    expect(
      find.textContaining('Répondez à la question du jour'),
      findsOneWidget,
    );
    expect(find.text('Chargement impossible'), findsNothing);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('liste vide : la meme phrase', (tester) async {
    await _pump(
      tester,
      setUp: (t) => t.reply('GET /api/couple/12/questions', _history([])),
    );

    expect(find.text('Pas encore de réponses'), findsOneWidget);
  });

  testWidgets('sans couple : rien a lire, aucun appel', (tester) async {
    final t = await _pump(tester, inCouple: false, setUp: (_) {});

    expect(t.calls, isEmpty);
    expect(find.text('Pas encore de réponses'), findsOneWidget);
  });

  testWidgets('une panne : l\'erreur, et Reessayer relit', (tester) async {
    final t = await _pump(
      tester,
      setUp: (t) =>
          t.fail('GET /api/couple/12/questions', const SocketException('down')),
    );

    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Question numero 1 ?'), findsNothing);

    t.reply('GET /api/couple/12/questions', _history([_entry(1)]));
    await tester.tap(find.text('Réessayer'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Question numero 1 ?'), findsOneWidget);
    expect(find.text('Chargement impossible'), findsNothing);
    expect(t.count('GET /api/couple/12/questions'), 2);
  });

  testWidgets('la colonne de lecture est bornee sur une fenetre large', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(669, 951),
      setUp: (t) =>
          t.reply('GET /api/couple/12/questions', _history([_entry(1)])),
    );

    final card = tester.getRect(find.text('Question numero 1 ?'));
    expect(card.width, lessThanOrEqualTo(560));
  });

  group('iPhone Duo', () {
    final entries = [for (var i = 1; i <= 6; i++) _entry(i)];

    Future<void> book(WidgetTester tester, DuoPose pose) async {
      setDuoPose(tester, pose);
      final controller = DuoPoseController(pose);
      await _pump(
        tester,
        pose: controller,
        setUp: (t) =>
            t.reply('GET /api/couple/12/questions', _history(entries)),
      );
      await settleFold(tester);
    }

    testWidgets('livre : moitie des cartes par page, aucune coupee', (
      tester,
    ) async {
      await book(tester, DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;

      for (final id in [1, 2, 3]) {
        expect(
          tester.getRect(find.text('Question numero $id ?')).right,
          lessThanOrEqualTo(fold.left + 0.5),
        );
      }
      for (final id in [4, 5, 6]) {
        expect(
          tester.getRect(find.text('Question numero $id ?')).left,
          greaterThanOrEqualTo(fold.right - 0.5),
        );
      }
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
    });

    testWidgets('portable : rien dans le pli', (tester) async {
      await book(tester, DuoPose.halfOpenLaptop);

      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
    });
  });

  for (final locale in const [
    Locale('en'),
    Locale('he'),
    Locale('es'),
    Locale('ru'),
  ]) {
    testWidgets('${locale.languageCode} : tient a 360 px', (tester) async {
      await _pump(
        tester,
        locale: locale,
        size: const Size(360, 1600),
        setUp: (t) => t.reply(
          'GET /api/couple/12/questions',
          _history([_entry(1), _entry(2, theirs: null)]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(wordsTooWide(tester), isEmpty);
      expect(find.text('Question numero 1 ?'), findsOneWidget);
    });
  }
}
