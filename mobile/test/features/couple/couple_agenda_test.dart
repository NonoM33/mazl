import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_agenda_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../duo/duo_geometry.dart';
import 'couple_flow_fakes.dart';

// The agenda tab, written against docs/couple/ESPACE-COUPLE.md §3: rituals
// `{ success, data: { rituals } }`, dates `{ success, dates }`. The clock is
// 2 November 2026 (a Monday): November 2026 starts on a Sunday and spreads
// over six rows.

final DateTime _now = DateTime(2026, 11, 2, 9);

Map<String, dynamic> _ritual({
  int id = 1,
  String kind = 'shabbat',
  String title = 'Shabbat ensemble',
  int? weekday = 5,
  String? time,
  bool enabled = true,
  int remind = 60,
}) => {
  'id': id,
  'couple_id': 12,
  'kind': kind,
  'title': title,
  'weekday': weekday,
  'time': time,
  'enabled': enabled,
  'remind_minutes': remind,
};

List<Map<String, dynamic>> _threeRituals() => [
  _ritual(),
  _ritual(
    id: 2,
    kind: 'weekly',
    title: 'Soirée sans écran',
    weekday: 2,
    time: '20:00',
    enabled: false,
  ),
  _ritual(
    id: 3,
    kind: 'weekly',
    title: 'Appeler les parents',
    weekday: 0,
    time: '18:00',
    enabled: false,
    remind: 30,
  ),
];

Map<String, dynamic> _date({
  int id = 1,
  String title = 'Un an de votre rencontre',
  String date = '2026-11-09T00:00:00.000Z',
  bool recurring = true,
  int? remind = 14,
}) => {
  ...dateRow(id: id, title: title),
  'date': date,
  'is_recurring': recurring,
  'remind_days_before': remind,
};

List<JewishHoliday> _holidays() => [
  JewishHoliday(
    id: JewishHolidayId.hanukkah,
    date: DateTime(2026, 11, 18),
    endDate: DateTime(2026, 11, 19),
    type: HolidayType.minor,
  ),
];

void _server(
  FakeCoupleTransport t, {
  List<Map<String, dynamic>>? rituals,
  List<Map<String, dynamic>>? dates,
}) {
  t.reply(
    'GET /api/couple/rituals',
    ok({
      'data': {'rituals': rituals ?? _threeRituals()},
    }),
  );
  t.reply(
    'GET /api/couple/dates',
    ok({
      'dates': dates ?? [_date()],
    }),
  );
}

class _Harness {
  _Harness(this.transport, this.router);
  final FakeCoupleTransport transport;
  final GoRouter router;
}

AppLocalizations _l10n([String code = 'fr']) =>
    lookupAppLocalizations(Locale(code));

Widget _app(
  FakeCoupleTransport transport,
  Locale locale,
  GoRouter router,
  DuoPoseController? pose,
) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  routerConfig: router,
  builder: pose == null ? null : duoAppBuilder(pose),
);

Future<_Harness> _pump(
  WidgetTester tester, {
  void Function(FakeCoupleTransport)? setUp,
  Locale locale = kTestLocale,
  DuoPoseController? pose,
}) async {
  if (pose == null) {
    tester.view.physicalSize = const Size(560, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  } else {
    setDuoPose(tester, pose.value);
  }
  final transport = FakeCoupleTransport();
  (setUp ?? _server)(transport);
  final screen = CoupleAgendaScreen(
    api: CoupleDailyApi(transport: transport, callerId: () => 12),
    contentApi: CoupleApiService(transport: transport),
    now: () => _now,
    holidays: _holidays,
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            pose == null ? screen : ContentMaxWidth(child: screen),
      ),
      GoRoute(
        path: '/couple/concierge',
        builder: (_, _) => const Scaffold(body: Text('page-concierge')),
      ),
      GoRoute(
        path: '/couple/premium',
        builder: (_, _) => const Scaffold(body: Text('page-premium')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(_app(transport, locale, router, pose));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (pose != null) await settleFold(tester);
  return _Harness(transport, router);
}

Finder _dot(String kind, String day) =>
    find.byKey(Key('agenda-dot-$kind-$day'));
Finder _cell(String day) => find.byKey(Key('agenda-cell-$day'));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CoupleService.instanceForTesting = CoupleService.forTesting(
      api: FakeCoupleApi(),
    );
  });

  group('content', () {
    testWidgets('the month, the title, the rituals and the next date', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('NOVEMBRE 2026'), findsOneWidget);
      expect(find.text('Agenda à deux'), findsOneWidget);
      expect(find.text('VOS RITUELS'), findsOneWidget);
      expect(find.text('DATES IMPORTANTES'), findsOneWidget);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
      expect(
        find.text('Chaque vendredi · rappel une heure avant les bougies'),
        findsOneWidget,
      );
      expect(
        find.text('Chaque mardi à 20:00 · rappel une heure avant'),
        findsOneWidget,
      );
      expect(
        find.text('Chaque dimanche à 18:00 · rappel 30 minutes avant'),
        findsOneWidget,
      );
      expect(
        find.text('Un an de votre rencontre · 9 novembre'),
        findsOneWidget,
      );
      expect(find.text('Rappel 14 jours avant'), findsOneWidget);
      expect(find.text('dans 7 jours'), findsOneWidget);
      expect(find.text('Préparer avec la conciergerie'), findsOneWidget);
      expect(find.text('Ajouter un moment'), findsOneWidget);
    });

    testWidgets('today is an ink disc, the chosen day an accent disc', (
      tester,
    ) async {
      await _pump(tester);
      final scheme = AppTheme.lightTheme.colorScheme;
      Color? fill(String day) {
        final box = tester.widget<Container>(
          find.byKey(Key('agenda-day-$day')),
        );
        return (box.decoration as BoxDecoration?)?.color;
      }

      expect(fill('2026-11-02'), scheme.onSurface);
      expect(fill('2026-11-05'), isNull);
      await tester.tap(_cell('2026-11-05'));
      await tester.pump();
      expect(fill('2026-11-05'), scheme.primary);
    });
  });

  group('the dots', () {
    testWidgets('a date, a holiday and a ritual have three different dots', (
      tester,
    ) async {
      await _pump(tester);

      // 9 November: the date of the couple, a Monday (no ritual).
      expect(_dot('importantDate', '2026-11-09'), findsOneWidget);
      expect(_dot('holiday', '2026-11-09'), findsNothing);
      expect(_dot('ritual', '2026-11-09'), findsNothing);
      // 18 and 19 November: the two days of the holiday (a Wednesday and a
      // Thursday: no ritual).
      for (final day in ['2026-11-18', '2026-11-19']) {
        expect(_dot('holiday', day), findsOneWidget, reason: day);
        expect(_dot('importantDate', day), findsNothing, reason: day);
      }
      expect(_dot('holiday', '2026-11-20'), findsNothing);
      // A plain Tuesday carries nothing.
      expect(
        find.byKey(const Key('agenda-dot-ritual-2026-11-03')),
        findsNothing,
      );

      // The three dots do not look alike: full accent, accent ring, full ink.
      Decoration? deco(Finder f) => tester
          .widget<Container>(
            find.descendant(of: f, matching: find.byType(Container)).first,
          )
          .decoration;
      final date = deco(_dot('importantDate', '2026-11-09')) as BoxDecoration;
      final holiday = deco(_dot('holiday', '2026-11-18')) as BoxDecoration;
      final ritual = deco(_dot('ritual', '2026-11-06')) as BoxDecoration;
      final scheme = AppTheme.lightTheme.colorScheme;
      expect(date.color, scheme.primary);
      expect(date.border, isNull);
      expect(holiday.color, isNull);
      expect(holiday.border, isNotNull);
      expect(ritual.color, scheme.onSurface);
    });

    testWidgets(
      'the enabled rituals mark their weekday: Shabbat, the Fridays',
      (tester) async {
        await _pump(tester);

        for (final friday in ['06', '13', '20', '27']) {
          expect(_dot('ritual', '2026-11-$friday'), findsOneWidget);
        }
        // Nothing on the other days of that week, nor on Sundays and Tuesdays
        // (their rituals are off).
        for (final other in ['01', '02', '03', '04', '05', '07', '08', '10']) {
          expect(_dot('ritual', '2026-11-$other'), findsNothing, reason: other);
        }
      },
    );

    testWidgets('a day that holds two things shows both dots', (tester) async {
      await _pump(
        tester,
        setUp: (t) =>
            _server(t, dates: [_date(date: '2026-11-13T00:00:00.000Z')]),
      );

      expect(_dot('importantDate', '2026-11-13'), findsOneWidget);
      expect(_dot('ritual', '2026-11-13'), findsOneWidget);
    });

    testWidgets('a yearly date marks the same day every year', (tester) async {
      await _pump(
        tester,
        setUp: (t) =>
            _server(t, dates: [_date(date: '2024-11-09T00:00:00.000Z')]),
      );

      expect(_dot('importantDate', '2026-11-09'), findsOneWidget);
    });

    testWidgets('a one-off date marks its own day only', (tester) async {
      await _pump(
        tester,
        setUp: (t) => _server(
          t,
          dates: [_date(date: '2024-11-09T00:00:00.000Z', recurring: false)],
        ),
      );

      expect(_dot('importantDate', '2026-11-09'), findsNothing);
    });
  });

  group('the chosen day', () {
    testWidgets('shows what the day holds', (tester) async {
      await _pump(tester);

      await tester.tap(_cell('2026-11-09'));
      await tester.pump();
      expect(find.byKey(const Key('agenda-day-detail')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('agenda-day-detail')),
          matching: find.text('Un an de votre rencontre'),
        ),
        findsOneWidget,
      );

      await tester.tap(_cell('2026-11-18'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('agenda-day-detail')),
          matching: find.text(_l10n().jewishCalendarHolidayHanukkahName),
        ),
        findsOneWidget,
      );

      await tester.tap(_cell('2026-11-06'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('agenda-day-detail')),
          matching: find.text('Shabbat ensemble'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an empty day says so; touching it again closes it', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(_cell('2026-11-04'));
      await tester.pump();
      expect(find.text('Rien ce jour-là'), findsOneWidget);

      await tester.tap(_cell('2026-11-04'));
      await tester.pump();
      expect(find.byKey(const Key('agenda-day-detail')), findsNothing);
    });
  });

  group('months', () {
    testWidgets('the arrows move the month and its dots', (tester) async {
      await _pump(tester);

      await tester.tap(find.bySemanticsLabel('Mois suivant'));
      await tester.pump();
      expect(find.text('DÉCEMBRE 2026'), findsOneWidget);
      expect(_dot('ritual', '2026-12-04'), findsOneWidget);
      expect(_dot('importantDate', '2026-12-09'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Mois précédent'));
      await tester.tap(find.bySemanticsLabel('Mois précédent'));
      await tester.pump();
      expect(find.text('OCTOBRE 2026'), findsOneWidget);
      expect(_dot('ritual', '2026-10-30'), findsOneWidget);
    });

    testWidgets('the arrows are 44 pt wide and 44 pt high', (tester) async {
      await _pump(tester);
      for (final label in ['Mois suivant', 'Mois précédent']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
      }
    });
  });

  group('the week', () {
    double dx(WidgetTester tester, String day) =>
        tester.getCenter(_cell(day)).dx;

    testWidgets('starts on Monday in French', (tester) async {
      await _pump(tester);
      // 2 Nov is a Monday: leftmost; 1 Nov, a Sunday: rightmost.
      expect(dx(tester, '2026-11-02'), lessThan(dx(tester, '2026-11-03')));
      expect(dx(tester, '2026-11-01'), greaterThan(dx(tester, '2026-11-07')));
      expect(
        tester.getCenter(find.text('L').first).dx,
        lessThan(tester.getCenter(find.text('D').first).dx),
      );
    });

    testWidgets('starts on Sunday in English', (tester) async {
      await _pump(tester, locale: const Locale('en'));
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(dx(tester, '2026-11-01'), lessThan(dx(tester, '2026-11-02')));
      expect(dx(tester, '2026-11-07'), greaterThan(dx(tester, '2026-11-01')));
      // The first column is the Sunday one: 1 November is in the first row.
      expect(
        tester.getTopLeft(_cell('2026-11-01')).dy,
        tester.getTopLeft(_cell('2026-11-07')).dy,
      );
    });

    testWidgets('starts on Sunday in Hebrew, from the right', (tester) async {
      await _pump(tester, locale: const Locale('he'));
      expect(tester.takeException(), isNull);
      // Right to left: the Sunday is the rightmost column of the first row.
      expect(dx(tester, '2026-11-01'), greaterThan(dx(tester, '2026-11-02')));
      expect(dx(tester, '2026-11-07'), lessThan(dx(tester, '2026-11-01')));
      expect(
        tester.getTopLeft(_cell('2026-11-01')).dy,
        tester.getTopLeft(_cell('2026-11-07')).dy,
      );
      expect(textDirectionAt(tester, _cell('2026-11-01')), TextDirection.rtl);
      // The rituals and the dates are written in Hebrew too.
      expect(find.text(_l10n('he').coupleAgendaTitle), findsOneWidget);
      expect(find.text(_l10n('he').coupleAgendaAddMoment), findsOneWidget);
    });
  });

  group('rituals', () {
    testWidgets('the switch sends PATCH /api/couple/rituals/:id', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          _server(t);
          t.reply(
            'PATCH /api/couple/rituals/2',
            ok({
              'data': _ritual(
                id: 2,
                kind: 'weekly',
                title: 'Soirée sans écran',
                weekday: 2,
                time: '20:00',
              ),
            }),
          );
        },
      );
      // Tuesday is not marked yet.
      expect(_dot('ritual', '2026-11-03'), findsNothing);

      await tester.tap(find.byKey(const Key('agenda-ritual-2')));
      await tester.pump();

      expect(h.transport.calls, contains('PATCH /api/couple/rituals/2'));
      expect(h.transport.bodies['PATCH /api/couple/rituals/2'], {
        'enabled': true,
      });
      // The Tuesdays are marked at once.
      expect(_dot('ritual', '2026-11-03'), findsOneWidget);
      expect(_dot('ritual', '2026-11-24'), findsOneWidget);
    });

    testWidgets(
      'the whole row is the control, the switch announces its state',
      (tester) async {
        await _pump(tester);
        final handle = tester.ensureSemantics();

        final row = tester.getRect(find.byKey(const Key('agenda-ritual-1')));
        expect(row.height, greaterThanOrEqualTo(44));
        // The switch is a toggle that says it is on (Shabbat), then off.
        expect(
          tester.getSemantics(
            find.bySemanticsLabel(RegExp('^Shabbat ensemble')),
          ),
          isSemantics(hasToggledState: true, isToggled: true),
        );
        expect(
          tester.getSemantics(
            find.bySemanticsLabel(RegExp('^Soirée sans écran')),
          ),
          isSemantics(hasToggledState: true, isToggled: false),
        );
        handle.dispose();
      },
    );

    testWidgets('a refusal puts the switch back and says why', (tester) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          _server(t);
          t.fail('PATCH /api/couple/rituals/1', const SocketException('down'));
        },
      );
      expect(_dot('ritual', '2026-11-06'), findsOneWidget);

      await tester.tap(find.byKey(const Key('agenda-ritual-1')));
      await tester.pump();
      await tester.pump();

      expect(h.transport.count('PATCH /api/couple/rituals/1'), 1);
      // Back where it was: Shabbat is still on, the Fridays still marked.
      expect(_dot('ritual', '2026-11-06'), findsOneWidget);
      expect(find.textContaining('Modification impossible'), findsOneWidget);
    });

    testWidgets('a route the server does not have yet is an empty state', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) {
          t.reply('GET /api/couple/rituals', {
            'success': false,
            'error': 'not_found',
          });
          t.reply(
            'GET /api/couple/dates',
            ok({
              'dates': [_date()],
            }),
          );
        },
      );

      expect(find.byKey(const Key('agenda-rituals-empty')), findsOneWidget);
      expect(find.text('Pas encore de rituel'), findsOneWidget);
      expect(find.text('Ajouter un rituel'), findsOneWidget);
      expect(find.text('Chargement impossible'), findsNothing);
      expect(
        find.text('Un an de votre rencontre · 9 novembre'),
        findsOneWidget,
      );
    });

    testWidgets('adding a ritual posts it and reloads the list', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          _server(t, rituals: []);
          t.reply(
            'POST /api/couple/rituals',
            ok({
              'data': {
                'ritual': _ritual(
                  id: 9,
                  kind: 'custom',
                  title: 'Café du dimanche',
                  weekday: 3,
                ),
              },
            }),
          );
        },
      );
      h.transport.reply(
        'GET /api/couple/rituals',
        ok({
          'data': {'rituals': []},
        }),
      );

      await tester.tap(find.text('Ajouter un rituel'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Café du dimanche');
      await tester.pump();
      // Wednesday, then confirm.
      await tester.tap(find.text('Mercredi'));
      await tester.pump();
      h.transport.reply(
        'GET /api/couple/rituals',
        ok({
          'data': {
            'rituals': [
              _ritual(
                id: 9,
                kind: 'custom',
                title: 'Café du dimanche',
                weekday: 3,
              ),
            ],
          },
        }),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ajouter'));
      await _settle(tester);

      expect(h.transport.bodies['POST /api/couple/rituals'], {
        'kind': 'custom',
        'title': 'Café du dimanche',
        'weekday': 3,
        'remind_minutes': 60,
        'enabled': true,
      });
      expect(h.transport.count('GET /api/couple/rituals'), 2);
      expect(find.text('Café du dimanche'), findsOneWidget);
      expect(_dot('ritual', '2026-11-04'), findsOneWidget);
    });
  });

  group('dates', () {
    testWidgets('adding a date posts it, then reloads the dates', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          _server(t, dates: []);
          t.reply('POST /api/couple/dates', ok({}));
        },
      );
      expect(find.text('Aucune date importante'), findsOneWidget);
      h.transport.reply(
        'GET /api/couple/dates',
        ok({
          'dates': [
            _date(
              id: 4,
              title: 'Notre mariage',
              date: '2026-11-21T00:00:00.000Z',
            ),
          ],
        }),
      );

      await tester.tap(find.text('Ajouter un moment'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Notre mariage');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ajouter'));
      await _settle(tester);

      expect(h.transport.calls, contains('POST /api/couple/dates'));
      expect(
        h.transport.bodies['POST /api/couple/dates']?['title'],
        'Notre mariage',
      );
      expect(h.transport.count('GET /api/couple/dates'), 2);
      expect(find.text('Aucune date importante'), findsNothing);
      expect(find.text('Notre mariage · 21 novembre'), findsOneWidget);
      expect(_dot('importantDate', '2026-11-21'), findsOneWidget);
    });

    testWidgets('the closest date is the card, the others are rows', (
      tester,
    ) async {
      await _pump(
        tester,
        setUp: (t) => _server(
          t,
          dates: [
            _date(
              id: 2,
              title: 'Anniversaire de Léa',
              date: '1990-12-24T00:00:00.000Z',
              remind: null,
            ),
            _date(),
          ],
        ),
      );

      expect(find.byKey(const Key('agenda-next-date')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('agenda-next-date')),
          matching: find.text('Un an de votre rencontre · 9 novembre'),
        ),
        findsOneWidget,
      );
      expect(find.text('Anniversaire de Léa'), findsOneWidget);
      expect(find.text('24 décembre · dans 52 jours'), findsOneWidget);
    });

    testWidgets('the concierge button opens the concierge', (tester) async {
      final h = await _pump(tester);

      await tester.tap(find.text('Préparer avec la conciergerie'));
      await _settle(tester);

      expect(find.text('page-concierge'), findsOneWidget);
      expect(
        h.router.routeInformationProvider.value.uri.path,
        '/couple/concierge',
      );
    });
  });

  group('MAZL Couple', () {
    testWidgets('without it, a quiet line leads to the subscription', (
      tester,
    ) async {
      await _pump(tester);

      expect(
        find.text('Les rappels font partie de MAZL Couple'),
        findsOneWidget,
      );
      // The switches work all the same.
      expect(find.byKey(const Key('agenda-ritual-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('agenda-premium-reminders')));
      await _settle(tester);
      expect(find.text('page-premium'), findsOneWidget);
    });

    testWidgets('with it, the line is gone', (tester) async {
      final api = FakeCoupleApi()
        ..couple = contractCouple()
        ..premium = {'active': true, 'paidBy': 'me', 'renewsAt': null};
      final service = CoupleService.forTesting(api: api);
      CoupleService.instanceForTesting = service;
      await tester.runAsync(service.refresh);
      expect(service.premium.active, isTrue);

      await _pump(tester);

      expect(find.text('Les rappels font partie de MAZL Couple'), findsNothing);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
    });
  });

  group('failures', () {
    testWidgets('the rituals failing do not hide the dates', (tester) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          t.fail('GET /api/couple/rituals', const SocketException('down'));
          t.reply(
            'GET /api/couple/dates',
            ok({
              'dates': [_date()],
            }),
          );
        },
      );

      expect(find.textContaining('Rituels indisponibles'), findsOneWidget);
      expect(
        find.text('Un an de votre rencontre · 9 novembre'),
        findsOneWidget,
      );
      expect(_dot('importantDate', '2026-11-09'), findsOneWidget);

      h.transport.reply(
        'GET /api/couple/rituals',
        ok({
          'data': {'rituals': _threeRituals()},
        }),
      );
      await tester.tap(find.text('Réessayer'));
      await _settle(tester);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
      expect(find.textContaining('Rituels indisponibles'), findsNothing);
    });

    testWidgets('the dates failing do not hide the rituals', (tester) async {
      await _pump(
        tester,
        setUp: (t) {
          t.reply(
            'GET /api/couple/rituals',
            ok({
              'data': {'rituals': _threeRituals()},
            }),
          );
          t.fail('GET /api/couple/dates', const SocketException('down'));
        },
      );

      expect(find.textContaining('Dates indisponibles'), findsOneWidget);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
      expect(_dot('ritual', '2026-11-06'), findsOneWidget);
    });

    testWidgets('both failing is an error with a retry', (tester) async {
      final h = await _pump(
        tester,
        setUp: (t) {
          t.fail('GET /api/couple/rituals', const SocketException('down'));
          t.fail('GET /api/couple/dates', const SocketException('down'));
        },
      );

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Shabbat ensemble'), findsNothing);

      _server(h.transport);
      await tester.tap(find.text('Réessayer'));
      await _settle(tester);
      expect(find.text('Chargement impossible'), findsNothing);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
    });

    testWidgets('while loading, a spinner', (tester) async {
      tester.view.physicalSize = const Size(560, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final transport = FakeCoupleTransport();
      _server(transport);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          home: CoupleAgendaScreen(
            api: CoupleDailyApi(transport: transport, callerId: () => 12),
            contentApi: CoupleApiService(transport: transport),
            now: () => _now,
            holidays: _holidays,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Shabbat ensemble'), findsNothing);
      await _settle(tester);
      expect(find.text('Shabbat ensemble'), findsOneWidget);
    });
  });

  group('iPhone Duo', () {
    DuoPoseController poseOf(DuoPose pose) => DuoPoseController(pose);

    void nothingInTheCurve(WidgetTester tester, DuoPose pose) {
      expect(foldCrossingProblems(tester, pose), isEmpty);
      expect(tester.takeException(), isNull);
      expect(tappableProblems(tester, pose), isEmpty);
    }

    testWidgets('book: the month and the button on the first page, the '
        'rituals and the dates on the other', (tester) async {
      await _pump(tester, pose: poseOf(DuoPose.halfOpenBook));
      final fold = DuoPose.halfOpenBook.fold!;

      for (final left in [
        find.text('Agenda à deux'),
        _cell('2026-11-15'),
        find.text('Ajouter un moment'),
        find.text('Date importante'),
      ]) {
        expect(
          tester.getRect(left.first).right,
          lessThanOrEqualTo(fold.left + 0.5),
        );
      }
      for (final right in [
        find.text('Shabbat ensemble'),
        find.text('Un an de votre rencontre · 9 novembre'),
        find.text('Ajouter un rituel'),
      ]) {
        expect(
          tester.getRect(right.first).left,
          greaterThanOrEqualTo(fold.right - 0.5),
        );
      }
      nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });

    testWidgets('laptop: the whole month above the fold, the rituals below', (
      tester,
    ) async {
      await _pump(tester, pose: poseOf(DuoPose.halfOpenLaptop));
      final fold = DuoPose.halfOpenLaptop.fold!;

      expect(
        tester.getRect(find.text('Agenda à deux')).bottom,
        lessThanOrEqualTo(fold.top),
      );
      // The sixth row of the month (the 30th) is above the fold, 44 pt high.
      final last = tester.getRect(_cell('2026-11-30'));
      expect(last.bottom, lessThanOrEqualTo(fold.top + 0.5));
      expect(last.height, greaterThanOrEqualTo(44));
      expect(
        tester.getRect(find.text('Shabbat ensemble')).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      expect(
        tester.getRect(find.text('Ajouter un moment')).top,
        greaterThanOrEqualTo(fold.bottom - 0.5),
      );
      nothingInTheCurve(tester, DuoPose.halfOpenLaptop);
    });

    testWidgets('one main button in every pose, visible without scrolling '
        'when the page is short', (tester) async {
      for (final pose in [
        DuoPose.closed,
        DuoPose.tent,
        DuoPose.halfOpenBook,
        DuoPose.halfOpenLaptop,
        DuoPose.openLandscape,
      ]) {
        await _pump(tester, pose: poseOf(pose));
        expect(
          find.text('Ajouter un moment'),
          findsOneWidget,
          reason: pose.name,
        );
      }
      await _pump(tester, pose: poseOf(DuoPose.tent));
      final rect = tester.getRect(find.text('Ajouter un moment'));
      expect(rect.bottom, lessThanOrEqualTo(DuoPose.tent.safeRect.bottom));
    });

    testWidgets('the chosen day and the month survive folding and unfolding', (
      tester,
    ) async {
      final pose = poseOf(DuoPose.halfOpenBook);
      await _pump(tester, pose: pose);
      await tester.tap(find.bySemanticsLabel('Mois suivant'));
      await tester.pump();
      await tester.tap(_cell('2026-12-04'));
      await tester.pump();
      expect(find.byKey(const Key('agenda-day-detail')), findsOneWidget);

      for (final next in [
        DuoPose.halfOpenLaptop,
        DuoPose.openLandscape,
        DuoPose.closed,
        DuoPose.halfOpenBook,
      ]) {
        await pose.moveTo(tester, next);
        await _settle(tester);
        expect(find.text('DÉCEMBRE 2026'), findsOneWidget, reason: next.name);
        expect(
          find.byKey(const Key('agenda-day-detail')),
          findsOneWidget,
          reason: next.name,
        );
        expect(
          find.byKey(const Key('agenda-ritual-1')),
          findsOneWidget,
          reason: next.name,
        );
      }
    });

    testWidgets('Hebrew, held like a book: the month on the right page', (
      tester,
    ) async {
      await _pump(
        tester,
        pose: poseOf(DuoPose.halfOpenBook),
        locale: const Locale('he'),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.text(_l10n('he').coupleAgendaTitle)).left,
        greaterThanOrEqualTo(fold.right - 0.5),
      );
      nothingInTheCurve(tester, DuoPose.halfOpenBook);
    });
  });
}
