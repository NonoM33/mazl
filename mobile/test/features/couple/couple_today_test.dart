import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_call.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_today_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';

// The server answers below are written from docs/couple/ESPACE-COUPLE.md §2,
// not from the decoders.

Map<String, dynamic> _today({
  Map<String, dynamic>? question = const {
    'id': 8,
    'text': "Quel petit geste de l'autre vous a touché cette semaine ?",
    'myAnswered': false,
    'partnerAnswered': true,
  },
  List<Map<String, dynamic>>? upcoming,
  Map<String, dynamic>? outing,
  String? mine,
  String? partner,
  bool checkinDue = false,
  bool premium = true,
}) => {
  'success': true,
  'data': {
    'days': 214,
    'partner': {'id': 45, 'name': 'David', 'picture': null},
    'question': question,
    'upcoming':
        upcoming ??
        [
          {
            'kind': 'event',
            'title': 'Soirée jazz',
            'at': '2026-11-02T18:00:00.000Z',
            'subtitle': 'Dimanche, 12 h 30 · Neuilly',
            'refId': 3,
          },
          {
            'kind': 'date',
            'title': 'Un an de votre rencontre',
            'at': '2026-11-09T09:00:00.000Z',
            'subtitle': null,
            'refId': 1,
          },
        ],
    'outing': outing,
    'mood': {'mine': mine, 'partner': partner},
    'checkin': {'due': checkinDue, 'period': '2026-11'},
    'premium': {
      'active': premium,
      'paidBy': premium ? 'me' : null,
      'renewsAt': null,
    },
  },
};

Map<String, dynamic> _outing({String kind = 'activity', int id = 21}) => {
  'id': id,
  'kind': kind,
  'title': 'Concert de jazz et dîner casher',
  'subtitle': 'Paris 11e · à 2 km de vous',
  'imageUrl': null,
  'city': 'Paris',
  'startsAt': '2026-11-05T19:00:00.000',
  'priceCents': null,
  'kosher': true,
  'saved': false,
};

// Friday, 30 October 2026 and the Wednesday before it.
DateTime _friday() => DateTime(2026, 10, 30, 10);
DateTime _wednesday() => DateTime(2026, 10, 28, 10);

class _Harness {
  _Harness(this.transport, this.visited);
  final FakeCoupleTransport transport;
  final List<String> visited;
}

Future<_Harness> _pump(
  WidgetTester tester,
  void Function(FakeCoupleTransport) setUp, {
  DuoPose? pose,
  DateTime Function()? clock,
  Brightness brightness = Brightness.light,
  Locale locale = kTestLocale,
}) async {
  if (pose != null) {
    setDuoPose(tester, pose);
  } else {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }
  final transport = FakeCoupleTransport();
  setUp(transport);
  final visited = <String>[];
  final controller = DuoPoseController(pose ?? DuoPose.openPortrait);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => CoupleTodayScreen(
          api: CoupleDailyApi(transport: transport, callerId: () => 12),
          clock: clock ?? _wednesday,
        ),
      ),
      GoRoute(
        path: '/:a',
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('page ${state.uri}'))),
      ),
      GoRoute(
        path: '/:a/:b',
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('page ${state.uri}'))),
      ),
      GoRoute(
        path: '/:a/:b/:c',
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('page ${state.uri}'))),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light
          ? AppTheme.lightTheme
          : AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: pose == null ? null : duoAppBuilder(controller),
      routerConfig: router,
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
  return _Harness(transport, visited);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

CouplePill _pill(WidgetTester tester, String label) =>
    tester.widget<CouplePill>(find.widgetWithText(CouplePill, label));

void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AuthService().debugSignIn(
      AuthUser(
        id: '12',
        email: 'lea@example.com',
        displayName: 'Léa Exemple',
        provider: AuthProvider.apple,
        jwtToken: 'jwt',
      ),
    );
  });

  group('content', () {
    testWidgets('greeting, day count, question and mood from the server', (
      tester,
    ) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/today', _today()));

      expect(find.text('MAZL COUPLE · JOUR 214'), findsOneWidget);
      expect(find.text('Bonjour Léa\net David.'), findsOneWidget);
      expect(find.text('QUESTION DU JOUR'), findsOneWidget);
      expect(
        find.text("Quel petit geste de l'autre vous a touché cette semaine ?"),
        findsOneWidget,
      );
      for (final pill in ['Très bien', 'Bien', 'Bof', 'On doit parler']) {
        expect(find.text(pill), findsOneWidget);
      }
    });

    testWidgets('the upcoming list shows month, day, title and subtitle', (
      tester,
    ) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/today', _today()));

      expect(find.text('À VENIR'), findsOneWidget);
      expect(find.text('NOV'), findsNWidgets(2));
      expect(find.text('Soirée jazz'), findsOneWidget);
      expect(find.text('Dimanche, 12 h 30 · Neuilly'), findsOneWidget);
      expect(find.text('Un an de votre rencontre'), findsOneWidget);
      // No subtitle from the server: how far it is, from the clock.
      expect(find.text('Dans 12 jours'), findsOneWidget);
    });

    testWidgets('an empty upcoming list says something useful', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(upcoming: const [])),
      );

      expect(
        find.textContaining('Rien de prévu dans les 45 prochains jours'),
        findsOneWidget,
      );
    });

    testWidgets('the idea card names the weekday of its date', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(outing: _outing())),
      );

      // 5 November 2026 is a Thursday.
      expect(find.text('IDÉE POUR JEUDI'), findsOneWidget);
      expect(find.text('Concert de jazz et dîner casher'), findsOneWidget);
      expect(find.text('Paris 11e · à 2 km de vous'), findsOneWidget);
    });

    testWidgets('an idea without a date has the generic eyebrow', (
      tester,
    ) async {
      final outing = _outing()..['startsAt'] = null;
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(outing: outing)),
      );

      expect(find.text('UNE IDÉE POUR VOUS'), findsOneWidget);
    });

    testWidgets('Shabbat: tonight on Friday, Friday on the other days', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today()),
        clock: _friday,
      );
      expect(find.text('Shabbat ensemble ce soir'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              RegExp(
                r'^Allumage des bougies à \d{1,2} h \d{2} · Paris$',
              ).hasMatch(w.data ?? ''),
        ),
        findsOneWidget,
      );

      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today()),
        clock: _wednesday,
      );
      expect(find.text('Shabbat ensemble vendredi'), findsOneWidget);
    });
  });

  group('question status line', () {
    Future<void> pumpWith(
      WidgetTester tester, {
      required bool mine,
      required bool partner,
    }) => _pump(
      tester,
      (t) => t.reply(
        'GET /api/couple/today',
        _today(
          question: {
            'id': 8,
            'text': 'Une question',
            'myAnswered': mine,
            'partnerAnswered': partner,
          },
        ),
      ),
    );

    testWidgets('the partner answered, not me: your turn, Répondre', (
      tester,
    ) async {
      await pumpWith(tester, mine: false, partner: true);
      expect(find.text('David a répondu · à vous'), findsOneWidget);
      expect(find.text('Répondre'), findsOneWidget);
    });

    testWidgets('I answered, the partner did not: waiting, Voir', (
      tester,
    ) async {
      await pumpWith(tester, mine: true, partner: false);
      expect(
        find.text('Vous avez répondu · en attente de David'),
        findsOneWidget,
      );
      expect(find.text('Voir'), findsOneWidget);
      expect(find.text('Répondre'), findsNothing);
    });

    testWidgets('nobody answered: waiting for the partner', (tester) async {
      await pumpWith(tester, mine: false, partner: false);
      expect(find.text('En attente de David'), findsOneWidget);
      expect(find.text('Répondre'), findsOneWidget);
    });

    testWidgets('both answered', (tester) async {
      await pumpWith(tester, mine: true, partner: true);
      expect(find.text('Vous avez répondu tous les deux'), findsOneWidget);
      expect(find.text('Voir'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Répondre opens the question and the page reloads on return', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today()),
      );
      expect(h.transport.count('GET /api/couple/today'), 1);

      await tester.tap(find.text('Répondre'));
      await _settle(tester);
      expect(find.text('page /couple/question'), findsOneWidget);

      // The member answered: the server now says so.
      h.transport.reply(
        'GET /api/couple/today',
        _today(
          question: {
            'id': 8,
            'text': 'Une question',
            'myAnswered': true,
            'partnerAnswered': true,
          },
        ),
      );
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await _settle(tester);

      expect(h.transport.count('GET /api/couple/today'), 2);
      expect(find.text('Vous avez répondu tous les deux'), findsOneWidget);
      expect(find.text('Voir'), findsOneWidget);
    });

    testWidgets('the Shabbat chevron goes to the agenda', (tester) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/today', _today()));

      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await _settle(tester);

      expect(find.text('page /couple/agenda'), findsOneWidget);
    });

    testWidgets('an event row and an idea open their own pages', (
      tester,
    ) async {
      await _pump(
        tester,
        (t) =>
            t.reply('GET /api/couple/today', _today(outing: _outing(id: 21))),
      );

      await tester.tap(find.text('Soirée jazz'));
      await _settle(tester);
      expect(find.text('page /couple/events/3'), findsOneWidget);
    });

    testWidgets('an idea of kind activity opens the activity', (tester) async {
      await _pump(
        tester,
        (t) =>
            t.reply('GET /api/couple/today', _today(outing: _outing(id: 21))),
      );

      await tester.tap(find.text('Concert de jazz et dîner casher'));
      await _settle(tester);
      expect(find.text('page /couple/activities/21'), findsOneWidget);
    });

    testWidgets('an idea of kind event opens the event', (tester) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/today',
          _today(outing: _outing(kind: 'event', id: 9)),
        ),
      );

      await tester.tap(find.text('Concert de jazz et dîner casher'));
      await _settle(tester);
      expect(find.text('page /couple/events/9'), findsOneWidget);
    });

    testWidgets('the check-in line shows only when it is due', (tester) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/today', _today()));
      expect(find.textContaining('vous attend'), findsNothing);

      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(checkinDue: true)),
      );
      expect(find.text('Le bilan de novembre vous attend'), findsOneWidget);

      await tester.tap(find.text('Le bilan de novembre vous attend'));
      await _settle(tester);
      expect(find.text('page /couple/checkin'), findsOneWidget);
    });

    testWidgets('MAZL Couple line: only without a subscription', (
      tester,
    ) async {
      await _pump(tester, (t) => t.reply('GET /api/couple/today', _today()));
      expect(find.text('Découvrir MAZL Couple'), findsNothing);

      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(premium: false)),
      );
      expect(find.text('Découvrir MAZL Couple'), findsOneWidget);

      await tester.tap(find.text('Découvrir MAZL Couple'));
      await _settle(tester);
      expect(find.text('page /couple/premium'), findsOneWidget);
    });
  });

  group('mood', () {
    testWidgets('the current choice comes from the server', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today(mine: 'good')),
      );

      expect(_pill(tester, 'Bien').selected, isTrue);
      expect(_pill(tester, 'Très bien').selected, isFalse);
    });

    testWidgets('On doit parler posts {"mood":"talk"} and says who was told', (
      tester,
    ) async {
      final h = await _pump(tester, (t) {
        t.reply('GET /api/couple/today', _today());
        t.reply('POST /api/couple/mood', {'success': true});
      });
      expect(find.textContaining('prévenu'), findsNothing);

      await tester.tap(find.text('On doit parler'));
      await _settle(tester);

      expect(h.transport.calls, contains('POST /api/couple/mood'));
      expect(h.transport.bodies['POST /api/couple/mood'], {'mood': 'talk'});
      expect(
        find.text('Nous avons prévenu David, sans un mot.'),
        findsOneWidget,
      );
    });

    testWidgets('a failing POST puts the previous choice back and says so', (
      tester,
    ) async {
      final h = await _pump(tester, (t) {
        t.reply('GET /api/couple/today', _today(mine: 'great'));
        t.reply('POST /api/couple/mood', {
          'success': false,
          'error': 'server down',
        });
      });

      await tester.tap(find.text('Bof'));
      await _settle(tester);

      expect(h.transport.bodies['POST /api/couple/mood'], {'mood': 'meh'});
      expect(_pill(tester, 'Très bien').selected, isTrue);
      expect(_pill(tester, 'Bof').selected, isFalse);
      expect(
        find.text('Impossible d\'enregistrer votre humeur. Réessayez.'),
        findsOneWidget,
      );
    });

    testWidgets("the partner's mood is nowhere on the page", (tester) async {
      await _pump(
        tester,
        (t) => t.reply(
          'GET /api/couple/today',
          _today(mine: 'good', partner: 'talk'),
        ),
      );

      // « On doit parler » is the label of a button; no sentence says that
      // David chose anything, and our own mood (good) shows no notice.
      expect(find.textContaining('prévenu'), findsNothing);
      expect(find.textContaining('David a répondu'), findsOneWidget);
      expect(find.textContaining('David'), findsNWidgets(2)); // greeting + line
    });
  });

  group('states', () {
    testWidgets('route missing: the page is built from the couple', (
      tester,
    ) async {
      final api = FakeCoupleApi()
        ..couple = contractCouple(partnerName: 'Myriam')
        ..premium = {'active': false, 'paidBy': null, 'renewsAt': null};
      final service = CoupleService.forTesting(
        api: api,
        pollInterval: const Duration(hours: 1),
      );
      CoupleService.instanceForTesting = service;
      addTearDown(service.dispose);
      await service.refresh();

      await _pump(
        tester,
        (t) => t.on(
          'GET /api/couple/today',
          (_) => decodeCoupleBody(404, '<html>Not Found</html>'),
        ),
      );

      expect(find.text('Chargement impossible'), findsNothing);
      final days = DateTime.now()
          .difference(DateTime.parse('2026-10-20T10:00:00.000Z'))
          .inDays;
      expect(find.text('MAZL COUPLE · JOUR $days'), findsOneWidget);
      expect(find.text('Bonjour Léa\net Myriam.'), findsOneWidget);
      // No question, no upcoming list content, no idea; but a subscription line.
      expect(find.text('QUESTION DU JOUR'), findsNothing);
      expect(find.textContaining('Rien de prévu'), findsOneWidget);
      expect(find.text('Découvrir MAZL Couple'), findsOneWidget);
    });

    testWidgets('another failure shows an error and Réessayer works', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', {
          'success': false,
          'error': 'boom',
        }),
      );
      expect(find.text('Chargement impossible'), findsOneWidget);

      h.transport.reply('GET /api/couple/today', _today());
      await tester.tap(find.text('Réessayer'));
      await _settle(tester);

      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('MAZL COUPLE · JOUR 214'), findsOneWidget);
    });

    testWidgets('pull to refresh reads the page again', (tester) async {
      final h = await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', _today()),
      );

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await _settle(tester);

      expect(h.transport.count('GET /api/couple/today'), 2);
    });
  });

  group('iPhone Duo', () {
    final payload = _today(outing: _outing(), checkinDue: true, premium: false);

    testWidgets('book: greeting and question on the first page, the rest on '
        'the other, nothing in the curve', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', payload),
        pose: DuoPose.halfOpenBook,
      );
      final fold = DuoPose.halfOpenBook.fold!;
      Rect rect(String text) => tester.getRect(find.text(text).first);

      expect(rect('QUESTION DU JOUR').right, lessThanOrEqualTo(fold.left));
      expect(rect('Répondre').right, lessThanOrEqualTo(fold.left));
      expect(
        rect('Shabbat ensemble vendredi').right,
        lessThanOrEqualTo(fold.left),
      );
      expect(rect('À VENIR').left, greaterThanOrEqualTo(fold.right));
      expect(rect('On doit parler').left, greaterThanOrEqualTo(fold.right));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expect(tappableProblems(tester, DuoPose.halfOpenBook), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('laptop: greeting and question above the fold, the rest '
        'below, nothing in the curve', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', payload),
        pose: DuoPose.halfOpenLaptop,
      );
      final fold = DuoPose.halfOpenLaptop.fold!;
      Rect rect(String text) => tester.getRect(find.text(text).first);

      expect(rect('Répondre').bottom, lessThanOrEqualTo(fold.top));
      expect(rect('À VENIR').top, greaterThanOrEqualTo(fold.bottom));
      expect(foldCrossingProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expect(tappableProblems(tester, DuoPose.halfOpenLaptop), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the mood choice survives folding and unfolding', (
      tester,
    ) async {
      setDuoPose(tester, DuoPose.openLandscape);
      final transport = FakeCoupleTransport()
        ..reply('GET /api/couple/today', payload)
        ..reply('POST /api/couple/mood', {'success': true});
      final controller = DuoPoseController(DuoPose.openLandscape);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          builder: duoAppBuilder(controller),
          home: CoupleTodayScreen(
            api: CoupleDailyApi(transport: transport, callerId: () => 12),
            clock: _wednesday,
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('On doit parler'));
      await _settle(tester);
      expect(find.textContaining('prévenu'), findsOneWidget);

      controller.value = DuoPose.halfOpenBook;
      setDuoPose(tester, DuoPose.halfOpenBook);
      await _settle(tester);
      expect(find.textContaining('prévenu'), findsOneWidget);

      controller.value = DuoPose.halfOpenLaptop;
      setDuoPose(tester, DuoPose.halfOpenLaptop);
      await _settle(tester);
      expect(find.textContaining('prévenu'), findsOneWidget);
      // Folding is not reading again.
      expect(transport.count('GET /api/couple/today'), 1);
    });

    testWidgets('dark theme renders without overflow', (tester) async {
      await _pump(
        tester,
        (t) => t.reply('GET /api/couple/today', payload),
        pose: DuoPose.openLandscape,
        brightness: Brightness.dark,
      );
      expect(tappableProblems(tester, DuoPose.openLandscape), isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final pose in DuoPose.values) {
      testWidgets('every block fits ${pose.name}', (tester) async {
        await _pump(
          tester,
          (t) => t.reply('GET /api/couple/today', payload),
          pose: pose,
        );
        expect(find.text('Répondre'), findsOneWidget);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    for (final code in ['en', 'he', 'es', 'ru']) {
      for (final pose in [DuoPose.closed, DuoPose.halfOpenBook]) {
        testWidgets('today in $code fits ${pose.name}', (tester) async {
          await _pump(
            tester,
            (t) => t.reply('GET /api/couple/today', payload),
            pose: pose,
            locale: Locale(code),
          );
          expect(foldCrossingProblems(tester, pose), isEmpty);
          expect(tappableProblems(tester, pose), isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
