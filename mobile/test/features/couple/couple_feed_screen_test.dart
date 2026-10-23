import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activities_feed_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

const _feed = 'GET /api/couple/activities?limit=50&offset=0';

// The four activities the screen used to invent when the API was empty.
const _formerFakeTitles = [
  'Spa en duo',
  'Cours de cuisine casher',
  'Visite guidée du Marais juif',
  'Dîner romantique casher',
];

Future<FakeCoupleTransport> _pumpFeed(
  WidgetTester tester, {
  required void Function(FakeCoupleTransport) setUp,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final transport = FakeCoupleTransport();
  setUp(transport);
  await tester.pumpWidget(
    MaterialApp(
      home: CoupleActivitiesFeedScreen(
        apiService: CoupleApiService(transport: transport),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return transport;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// The round button of the action row: the app bar has its own bookmark, and
/// the action icons are the only ones drawn at 30 / 35 logical pixels.
Finder _actionButton(IconData icon) => find.byWidgetPredicate(
  (w) => w is Icon && w.icon == icon && (w.size ?? 0) >= 30,
);

void main() {
  group('empty and failing feed', () {
    testWidgets(
      'an empty feed shows an empty state and none of the former fake activities',
      (tester) async {
        await _pumpFeed(
          tester,
          setUp: (t) => t.reply(_feed, ok({'activities': []})),
        );

        expect(find.text('Aucune activité pour le moment'), findsOneWidget);
        for (final title in _formerFakeTitles) {
          expect(find.text(title), findsNothing);
        }
      },
    );

    testWidgets(
      'a failing feed shows an error with a retry, and no fake activity',
      (tester) async {
        final transport = await _pumpFeed(
          tester,
          setUp: (t) => t.fail(_feed, const SocketException('down')),
        );

        expect(find.text('Chargement impossible'), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);
        for (final title in _formerFakeTitles) {
          expect(find.text(title), findsNothing);
        }

        transport.reply(
          _feed,
          ok({
            'activities': [activityRow(id: 1, title: 'Atelier poterie')],
          }),
        );
        await tester.tap(find.text('Réessayer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Atelier poterie'), findsWidgets);
        expect(find.text('Chargement impossible'), findsNothing);
      },
    );

    testWidgets('a server error is an error state, not an empty feed', (
      tester,
    ) async {
      await _pumpFeed(
        tester,
        setUp: (t) => t.reply(_feed, error('connection terminated')),
      );

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Aucune activité pour le moment'), findsNothing);
    });
  });

  group('swipes call the server', () {
    testWidgets('pass posts to the pass route and removes the card', (
      tester,
    ) async {
      final transport = await _pumpFeed(
        tester,
        setUp: (t) {
          t.reply(
            _feed,
            ok({
              'activities': [activityRow(id: 1, title: 'Atelier poterie')],
            }),
          );
          t.reply('POST /api/couple/activities/1/pass', ok({}));
        },
      );

      await tester.tap(_actionButton(LucideIcons.x));
      await _settle(tester);

      expect(transport.calls, contains('POST /api/couple/activities/1/pass'));
      expect(transport.calls.where((c) => c.contains('/save')), isEmpty);
      expect(find.text('Aucune activité pour le moment'), findsOneWidget);
    });

    testWidgets('save posts to the save route and says so', (tester) async {
      final transport = await _pumpFeed(
        tester,
        setUp: (t) {
          t.reply(
            _feed,
            ok({
              'activities': [activityRow(id: 2, title: 'Atelier poterie')],
            }),
          );
          t.reply('POST /api/couple/activities/2/save', ok({}));
        },
      );

      await tester.tap(_actionButton(LucideIcons.bookmark));
      await _settle(tester);

      expect(transport.calls, contains('POST /api/couple/activities/2/save'));
      expect(find.text('Atelier poterie sauvegardé'), findsOneWidget);
    });

    testWidgets('a failed pass puts the card back and says why', (
      tester,
    ) async {
      await _pumpFeed(
        tester,
        setUp: (t) {
          t.reply(
            _feed,
            ok({
              'activities': [activityRow(id: 1, title: 'Atelier poterie')],
            }),
          );
          t.fail(
            'POST /api/couple/activities/1/pass',
            const SocketException('down'),
          );
        },
      );

      await tester.tap(_actionButton(LucideIcons.x));
      await _settle(tester);

      expect(find.textContaining('Impossible de passer'), findsOneWidget);
      expect(find.text('Atelier poterie'), findsWidgets);
      expect(find.text('Aucune activité pour le moment'), findsNothing);
    });

    testWidgets('a failed save puts the card back and says why', (
      tester,
    ) async {
      await _pumpFeed(
        tester,
        setUp: (t) {
          t.reply(
            _feed,
            ok({
              'activities': [activityRow(id: 2, title: 'Atelier poterie')],
            }),
          );
          t.reply(
            'POST /api/couple/activities/2/save',
            error('Not in a couple'),
          );
        },
      );

      await tester.tap(_actionButton(LucideIcons.bookmark));
      await _settle(tester);

      expect(find.textContaining('Impossible de sauvegarder'), findsOneWidget);
      expect(find.text('Atelier poterie sauvegardé'), findsNothing);
      expect(find.text('Atelier poterie'), findsWidgets);
    });
  });

  testWidgets('the category filter asks the server for that category', (
    tester,
  ) async {
    final transport = await _pumpFeed(
      tester,
      setUp: (t) {
        t.reply(_feed, ok({'activities': []}));
        t.reply(
          'GET /api/couple/activities?limit=50&offset=0&category=gastronomy',
          ok({
            'activities': [
              activityRow(
                id: 9,
                title: 'Cours de cuisine',
                category: 'gastronomy',
              ),
            ],
          }),
        );
      },
    );

    await tester.ensureVisible(find.textContaining('Gastro'));
    await tester.pump();
    await tester.tap(find.textContaining('Gastro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      transport.calls,
      contains(
        'GET /api/couple/activities?limit=50&offset=0&category=gastronomy',
      ),
    );
    expect(find.text('Cours de cuisine'), findsWidgets);
  });
}
