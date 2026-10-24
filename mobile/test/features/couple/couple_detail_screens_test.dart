import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activity_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_event_detail_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../helpers/l10n_helpers.dart';

Future<FakeCoupleTransport> _pump(
  WidgetTester tester,
  Widget Function(CoupleApiService) screen, {
  required void Function(FakeCoupleTransport) setUp,
}) async {
  // Wide enough for the test font (every glyph is one em wide), so only real
  // layout bugs overflow.
  tester.view.physicalSize = const Size(900, 1400);
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
  group('activity detail', () {
    Widget screen(CoupleApiService api, [String id = '4']) =>
        CoupleActivityDetailScreen(activityId: id, apiService: api);

    testWidgets('a missing activity shows "introuvable", not a blank page', (
      tester,
    ) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply('GET /api/couple/activities/4', error('Activity not found'));
          t.reply('GET /api/couple/saved', ok({'activities': []}));
        },
      );

      expect(find.text('Activité introuvable'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('a network error shows an error with a retry that reloads', (
      tester,
    ) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          t.fail('GET /api/couple/activities/4', const SocketException('down'));
          t.reply('GET /api/couple/saved', ok({'activities': []}));
        },
      );

      expect(find.text('Chargement impossible'), findsOneWidget);

      transport.reply(
        'GET /api/couple/activities/4',
        ok({'activity': activityRow(id: 4, title: 'Atelier poterie')}),
      );
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Atelier poterie'), findsWidgets);
    });

    testWidgets(
      'an id that is not a number is "introuvable" without any request',
      (tester) async {
        final transport = await _pump(
          tester,
          (api) => screen(api, 'abc'),
          setUp: (_) {},
        );

        expect(find.text('Activité introuvable'), findsOneWidget);
        expect(transport.calls, isEmpty);
      },
    );

    testWidgets('knows from the server that the activity is already saved', (
      tester,
    ) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply(
            'GET /api/couple/activities/4',
            ok({'activity': activityRow(id: 4, title: 'Atelier poterie')}),
          );
          t.reply(
            'GET /api/couple/saved',
            ok({
              'activities': [savedActivityRow(id: 4, title: 'Atelier poterie')],
            }),
          );
        },
      );

      expect(find.byIcon(LucideIcons.bookMarked), findsOneWidget);
    });

    testWidgets(
      'saving posts to the server, a refusal rolls the bookmark back',
      (tester) async {
        final transport = await _pump(
          tester,
          screen,
          setUp: (t) {
            t.reply(
              'GET /api/couple/activities/4',
              ok({'activity': activityRow(id: 4, title: 'Atelier poterie')}),
            );
            t.reply('GET /api/couple/saved', ok({'activities': []}));
            t.fail(
              'POST /api/couple/activities/4/save',
              const SocketException('down'),
            );
          },
        );

        await tester.tap(find.byIcon(LucideIcons.bookmark));
        await tester.pump();
        await tester.pump();

        expect(transport.calls, contains('POST /api/couple/activities/4/save'));
        expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
        expect(find.byIcon(LucideIcons.bookMarked), findsNothing);
        expect(
          find.textContaining('Impossible de sauvegarder'),
          findsOneWidget,
        );
      },
    );
  });

  group('event detail', () {
    Widget screen(CoupleApiService api, [String id = '3']) =>
        CoupleEventDetailScreen(eventId: id, apiService: api);

    void event(
      FakeCoupleTransport t, {
      required bool registered,
      int current = 3,
      int? max = 20,
    }) {
      t.reply(
        'GET /api/couple/events/3',
        ok({
          'event': eventRow(id: 3, currentCouples: current, maxCouples: max),
        }),
      );
      t.reply(
        'GET /api/couple/events/registered',
        ok({
          'events': registered ? [registeredEventRow(id: 3)] : [],
        }),
      );
    }

    testWidgets('a missing event shows "introuvable"', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.reply('GET /api/couple/events/3', error('Event not found'));
          t.reply('GET /api/couple/events/registered', ok({'events': []}));
        },
      );

      expect(find.text('Événement introuvable'), findsOneWidget);
    });

    testWidgets('a network error shows an error with a retry', (tester) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          t.fail('GET /api/couple/events/3', TimeoutException('slow'));
          t.reply('GET /api/couple/events/registered', ok({'events': []}));
        },
      );

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets(
      'registering posts to the register route and flips the button',
      (tester) async {
        final transport = await _pump(
          tester,
          screen,
          setUp: (t) {
            event(t, registered: false);
            t.reply(
              'POST /api/couple/events/3/register',
              ok({'registration': {}}),
            );
          },
        );

        expect(find.text('S\'inscrire'), findsOneWidget);
        await tester.tap(find.text('S\'inscrire'));
        await tester.pump();
        await tester.pump();

        expect(transport.calls, contains('POST /api/couple/events/3/register'));
        expect(find.text('Annuler mon inscription'), findsOneWidget);
        expect(find.textContaining('Inscrits à'), findsOneWidget);
      },
    );

    testWidgets(
      'an event the couple is registered to offers the cancellation',
      (tester) async {
        final transport = await _pump(
          tester,
          screen,
          setUp: (t) {
            event(t, registered: true);
            t.reply('DELETE /api/couple/events/3/register', ok({}));
          },
        );

        await tester.tap(find.text('Annuler mon inscription'));
        await tester.pump();
        await tester.pump();

        expect(
          transport.calls,
          contains('DELETE /api/couple/events/3/register'),
        );
        expect(find.text('S\'inscrire'), findsOneWidget);
      },
    );

    testWidgets('a refused registration keeps the button and says why', (
      tester,
    ) async {
      await _pump(
        tester,
        screen,
        setUp: (t) {
          event(t, registered: false);
          t.fail(
            'POST /api/couple/events/3/register',
            const SocketException('down'),
          );
        },
      );

      await tester.tap(find.text('S\'inscrire'));
      await tester.pump();
      await tester.pump();

      expect(find.text('S\'inscrire'), findsOneWidget);
      expect(find.text('Inscription impossible. Réessayez.'), findsOneWidget);
    });

    testWidgets('a full event cannot be joined', (tester) async {
      final transport = await _pump(
        tester,
        screen,
        setUp: (t) {
          event(t, registered: false, current: 20, max: 20);
        },
      );

      expect(find.text('Complet'), findsWidgets);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Complet'));
      await tester.pump();

      expect(transport.calls.where((c) => c.startsWith('POST')), isEmpty);
    });
  });
}
