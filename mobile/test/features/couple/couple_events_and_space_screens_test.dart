import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_events_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_space_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../helpers/l10n_helpers.dart';

Future<FakeCoupleTransport> _pump(
  WidgetTester tester,
  Widget Function(CoupleApiService) screen, {
  required void Function(FakeCoupleTransport) setUp,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final transport = FakeCoupleTransport();
  setUp(transport);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      home: screen(CoupleApiService(transport: transport)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return transport;
}

void main() {
  group('events list', () {
    const upcoming = 'GET /api/couple/events?limit=50&offset=0';
    const registered = 'GET /api/couple/events/registered';
    Widget screen(CoupleApiService api) => CoupleEventsScreen(apiService: api);

    testWidgets('a failing load shows an error, not "Aucun événement"', (
      tester,
    ) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          t.fail(upcoming, const SocketException('down'));
          t.reply(registered, ok({'events': []}));
        },
      );

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Aucun événement disponible'), findsNothing);

      transport.reply(
        upcoming,
        ok({
          'events': [eventRow(id: 3, title: 'Dîner de Shabbat')],
        }),
      );
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Dîner de Shabbat'), findsOneWidget);
    });

    testWidgets('registering posts to the server and reloads the lists', (
      tester,
    ) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply(
            upcoming,
            ok({
              'events': [eventRow(id: 3, title: 'Dîner de Shabbat')],
            }),
          );
          t.reply(registered, ok({'events': []}));
          t.reply(
            'POST /api/couple/events/3/register',
            ok({'registration': {}}),
          );
        },
      );

      await tester.tap(find.text('S\'inscrire'));
      await tester.pump();
      await tester.pump();

      expect(transport.calls, contains('POST /api/couple/events/3/register'));
      expect(transport.count(upcoming), 2);
    });

    testWidgets('a refused registration says so', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply(
            upcoming,
            ok({
              'events': [eventRow(id: 3)],
            }),
          );
          t.reply(registered, ok({'events': []}));
          t.reply('POST /api/couple/events/3/register', error('Event is full'));
        },
      );

      await tester.tap(find.text('S\'inscrire'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cet événement est complet.'), findsOneWidget);
    });

    testWidgets('a refused cancellation says so', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply(
            upcoming,
            ok({
              'events': [eventRow(id: 3)],
            }),
          );
          t.reply(
            registered,
            ok({
              'events': [registeredEventRow(id: 3)],
            }),
          );
          t.fail(
            'DELETE /api/couple/events/3/register',
            const SocketException('down'),
          );
        },
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oui, annuler'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Impossible d\'annuler'), findsOneWidget);
    });
  });

  group('couple space', () {
    Widget screen(CoupleApiService api) => CoupleSpaceScreen(apiService: api);

    void space(
      FakeCoupleTransport t, {
      List<Map<String, dynamic>> bucket = const [],
      List<Map<String, dynamic>> dates = const [],
      List<Map<String, dynamic>> memories = const [],
      Map<String, dynamic>? stats,
    }) {
      t.reply(
        'GET /api/couple/stats',
        ok({
          'stats': stats ?? statsRow(),
          'achievements': [achievementRow()],
        }),
      );
      t.reply('GET /api/couple/bucket-list', ok({'items': bucket}));
      t.reply('GET /api/couple/dates', ok({'dates': dates}));
      t.reply('GET /api/couple/memories', ok({'memories': memories}));
    }

    testWidgets('counters arriving as strings are displayed', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) => space(
          t,
          stats: statsRow(saved: '3', events: '1', memories: '5'),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Première activité'), findsOneWidget);
    });

    testWidgets('a failing load shows an error with a retry', (tester) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          space(t);
          t.fail('GET /api/couple/dates', const SocketException('down'));
        },
      );

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Aucune date importante'), findsNothing);

      space(transport);
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Aucune date importante'), findsOneWidget);
    });

    testWidgets(
      'the dates, the bucket list and the memories come from the server',
      (tester) async {
        await _pump(
          tester,
          screen,
          setUp: (t) {
            space(
              t,
              bucket: [bucketRow(id: 1, title: 'Voir les aurores boréales')],
              dates: [dateRow(id: 1, title: 'Notre anniversaire')],
              memories: [memoryRow(id: 1, title: 'Notre premier voyage')],
            );
          },
        );

        expect(find.text('Voir les aurores boréales'), findsOneWidget);
        expect(find.text('Notre anniversaire'), findsOneWidget);
        expect(find.text('1 déc. 2026'), findsOneWidget);
        expect(find.text('Notre premier voyage'), findsOneWidget);
      },
    );

    testWidgets('completing a bucket item posts to the server and refreshes', (
      tester,
    ) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          space(
            t,
            bucket: [bucketRow(id: 7, title: 'Voir les aurores boréales')],
          );
          t.reply('POST /api/couple/bucket-list/7/complete', ok({'item': []}));
        },
      );

      await _completeFirstBucketItem(tester);

      expect(
        transport.calls,
        contains('POST /api/couple/bucket-list/7/complete'),
      );
    });

    testWidgets('a refused completion says so', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          space(
            t,
            bucket: [bucketRow(id: 7, title: 'Voir les aurores boréales')],
          );
          t.fail(
            'POST /api/couple/bucket-list/7/complete',
            const SocketException('down'),
          );
        },
      );

      await _completeFirstBucketItem(tester);

      expect(find.textContaining('Impossible de valider'), findsOneWidget);
    });

    testWidgets('a refused add keeps the sheet open and shows why', (
      tester,
    ) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          space(t);
          t.reply(
            'POST /api/couple/bucket-list',
            error('null value in column "title"'),
          );
        },
      );

      await _openBucketSheet(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'Rome',
      );
      await tester.pump();
      await tester.tap(_sheetAddButton);
      await tester.pump();
      await tester.pump();

      expect(transport.calls, contains('POST /api/couple/bucket-list'));
      expect(find.textContaining('Ajout impossible'), findsOneWidget);
      expect(find.text('Ajouter à la bucket list'), findsOneWidget);
    });

    testWidgets('an accepted add closes the sheet and refreshes the list', (
      tester,
    ) async {
      var added = false;
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          space(t);
          t.on(
            'GET /api/couple/bucket-list',
            (_) => ok({
              'items': added ? [bucketRow(id: 2, title: 'Rome')] : [],
            }),
          );
          t.on('POST /api/couple/bucket-list', (body) {
            added = true;
            return ok({'item': []});
          });
        },
      );

      await _openBucketSheet(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'Rome',
      );
      await tester.pump();
      await tester.tap(_sheetAddButton);
      await tester.pumpAndSettle();

      expect(transport.bodies['POST /api/couple/bucket-list'], {
        'title': 'Rome',
      });
      expect(find.text('Ajouter à la bucket list'), findsNothing);
      expect(find.text('Rome'), findsOneWidget);
    });

    testWidgets('the add button waits for a title', (tester) async {
      await _pump(tester, screen, setUp: space);

      await _openBucketSheet(tester);

      final button = tester.widget<ElevatedButton>(_sheetAddButton);
      expect(button.onPressed, isNull);
    });
  });
}

Future<void> _openBucketSheet(WidgetTester tester) async {
  await tester.tap(find.text('Ajouter à\nla bucket list'));
  await tester.pumpAndSettle();
}

Finder get _sheetAddButton => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.widgetWithText(ElevatedButton, 'Ajouter'),
);

Future<void> _completeFirstBucketItem(WidgetTester tester) async {
  // The round check at the left of the item is the only GestureDetector in it.
  final item = find.ancestor(
    of: find.text('Voir les aurores boréales'),
    matching: find.byType(Row),
  );
  await tester.tap(
    find
        .descendant(of: item.first, matching: find.byType(GestureDetector))
        .first,
  );
  await tester.pump();
  await tester.pump();
}
