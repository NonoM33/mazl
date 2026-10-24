import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/saved_activities_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../helpers/l10n_helpers.dart';

const _saved = 'GET /api/couple/saved';

Future<FakeCoupleTransport> _pumpSaved(
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      home: SavedActivitiesScreen(
        apiService: CoupleApiService(transport: transport),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return transport;
}

Future<void> _removeFirstRow(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.trash2).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Retirer'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('lists what the server says is saved, not the local storage', (
    tester,
  ) async {
    // A stale local list from the former SharedPreferences service.
    SharedPreferences.setMockInitialValues({
      'saved_activities':
          '[{"id": 99, "title": "Fantôme local", "description": "", "category": "culture"}]',
    });

    await _pumpSaved(
      tester,
      setUp: (t) {
        t.reply(
          _saved,
          ok({
            'activities': [
              savedActivityRow(id: 5, title: 'Atelier poterie'),
              savedActivityRow(id: 6, title: 'Dîner sur la Seine'),
            ],
          }),
        );
      },
    );

    expect(find.text('Atelier poterie'), findsOneWidget);
    expect(find.text('Dîner sur la Seine'), findsOneWidget);
    expect(find.text('Fantôme local'), findsNothing);
  });

  testWidgets('an empty server list is shown empty', (tester) async {
    await _pumpSaved(
      tester,
      setUp: (t) => t.reply(_saved, ok({'activities': []})),
    );

    expect(find.text('Aucune activité sauvegardée'), findsOneWidget);
  });

  testWidgets('a failing load shows an error and a retry that reloads', (
    tester,
  ) async {
    final transport = await _pumpSaved(
      tester,
      setUp: (t) => t.fail(_saved, const SocketException('down')),
    );

    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Aucune activité sauvegardée'), findsNothing);

    transport.reply(
      _saved,
      ok({
        'activities': [savedActivityRow(id: 5, title: 'Atelier poterie')],
      }),
    );
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Atelier poterie'), findsOneWidget);
  });

  testWidgets('removing calls DELETE /api/couple/saved/:id and drops the row', (
    tester,
  ) async {
    final transport = await _pumpSaved(
      tester,
      setUp: (t) {
        t.reply(
          _saved,
          ok({
            'activities': [
              savedActivityRow(id: 5, title: 'Atelier poterie'),
              savedActivityRow(id: 6, title: 'Dîner sur la Seine'),
            ],
          }),
        );
        t.reply('DELETE /api/couple/saved/5', ok({}));
      },
    );

    await _removeFirstRow(tester);

    expect(transport.calls, contains('DELETE /api/couple/saved/5'));
    expect(find.text('Atelier poterie'), findsNothing);
    expect(find.text('Dîner sur la Seine'), findsOneWidget);
  });

  testWidgets('a refused removal brings the row back and says why', (
    tester,
  ) async {
    await _pumpSaved(
      tester,
      setUp: (t) {
        t.reply(
          _saved,
          ok({
            'activities': [savedActivityRow(id: 5, title: 'Atelier poterie')],
          }),
        );
        t.fail('DELETE /api/couple/saved/5', const SocketException('down'));
      },
    );

    await _removeFirstRow(tester);

    expect(find.text('Atelier poterie'), findsOneWidget);
    expect(find.textContaining('Impossible de retirer'), findsOneWidget);
  });
}
