import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_us_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_space_sheets.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../../mocks/couple_backend_shapes.dart';
import '../../../mocks/fake_couple_transport.dart';
import 'text_fit.dart';

/// 360 px de large comme le plus petit téléphone, mais assez haut pour que
/// toute la liste soit construite d'un coup.
const _tallPhone = Size(360, 3000);

const _languages = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

FakeCoupleTransport _filledSpace() => FakeCoupleTransport()
  ..reply(
    'GET /api/couple/stats',
    ok({
      'stats': statsRow(),
      'achievements': [achievementRow()],
    }),
  )
  ..reply(
    'GET /api/couple/memories',
    ok({
      'memories': [memoryRow()],
    }),
  )
  ..reply(
    'GET /api/couple/bucket-list',
    ok({
      'items': [bucketRow()],
    }),
  )
  ..reply(
    'GET /api/couple/dates',
    ok({
      'dates': [dateRow()],
    }),
  );

FakeCoupleTransport _emptySpace() => FakeCoupleTransport()
  ..reply(
    'GET /api/couple/stats',
    ok({'stats': statsRow(), 'achievements': []}),
  )
  ..reply('GET /api/couple/memories', ok({'memories': []}))
  ..reply('GET /api/couple/bucket-list', ok({'items': []}))
  ..reply('GET /api/couple/dates', ok({'dates': []}));

Future<void> _pumpSpace(
  WidgetTester tester,
  FakeCoupleTransport transport, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    CoupleUsScreen(apiService: CoupleApiService(transport: transport)),
    locale: locale,
    brightness: brightness,
    size: _tallPhone,
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(loadAppFont);

  group('Notre espace', () {
    testWidgets('en anglais : titres, raccourcis et dates dans la langue', (
      tester,
    ) async {
      await _pumpSpace(tester, _filledSpace());

      expect(find.text('Our space'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('OUR MEMORIES'), findsOneWidget);
      expect(find.text('IMPORTANT DATES'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('Saved\nactivities'), findsOneWidget);
      expect(find.text('BUCKET LIST · 0/1'), findsOneWidget);
      expect(find.text('Dec 1, 2026'), findsOneWidget);
      expect(find.text('Notre espace'), findsNothing);
    });

    testWidgets('états vides en anglais', (tester) async {
      await _pumpSpace(tester, _emptySpace());

      expect(find.text('No memories yet'), findsOneWidget);
      expect(find.text('Your bucket list is empty'), findsOneWidget);
      expect(find.text('No important dates'), findsOneWidget);
      // No badge section: the server has no code that ever unlocks a badge.
      expect(find.text('No badges yet'), findsNothing);
      expect(find.text('OUR BADGES'), findsNothing);
    });

    testWidgets('une panne réseau se dit dans la langue, sans texte serveur', (
      tester,
    ) async {
      final transport = _filledSpace()
        ..fail('GET /api/couple/stats', const SocketException('down'));
      await _pumpSpace(tester, transport);

      expect(find.text("Couldn't load"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('Chargement impossible'), findsNothing);
    });

    testWidgets('en hébreu : de droite à gauche', (tester) async {
      await _pumpSpace(tester, _filledSpace(), locale: const Locale('he'));

      expect(find.text('המרחב שלנו'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('המרחב שלנו')),
        TextDirection.rtl,
      );
      // La roue des réglages passe de l'autre côté du titre.
      final title = tester.getCenter(find.text('המרחב שלנו'));
      final settings = tester.getCenter(find.byIcon(LucideIcons.settings));
      expect(settings.dx, lessThan(title.dx));
    });

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : aucun débordement à 360 px',
          (tester) async {
            await _pumpSpace(
              tester,
              _filledSpace(),
              locale: locale,
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);
          },
        );
      }
    }
  });

  group('feuilles d\'ajout', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      Widget Function(CoupleApiService) sheet, {
      Locale locale = const Locale('en'),
      Brightness brightness = Brightness.light,
      FakeCoupleTransport? transport,
    }) async {
      await pumpLocalized(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: sheet(
              CoupleApiService(transport: transport ?? FakeCoupleTransport()),
            ),
          ),
        ),
        locale: locale,
        brightness: brightness,
      );
    }

    testWidgets('souvenir, bucket list et date en anglais', (tester) async {
      await pumpSheet(tester, (api) => AddMemorySheet(apiService: api));
      expect(find.text('Add a memory'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await pumpSheet(tester, (api) => AddBucketItemSheet(apiService: api));
      expect(find.text('Add to the bucket list'), findsOneWidget);
      expect(find.text('What do you want to do together?'), findsOneWidget);

      await pumpSheet(tester, (api) => AddDateSheet(apiService: api));
      expect(find.text('Add an important date'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('la date de la feuille suit la langue (jour/mois/année)', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        (api) => AddDateSheet(apiService: api),
        locale: const Locale('fr'),
      );
      final now = DateTime.now();
      expect(find.textContaining('${now.year}'), findsOneWidget);
      final fr = tester.widget<Text>(find.textContaining('${now.year}')).data!;
      expect(fr, endsWith('${now.year}'));

      await pumpSheet(
        tester,
        (api) => AddDateSheet(apiService: api),
        locale: const Locale('en'),
      );
      final en = tester.widget<Text>(find.textContaining('${now.year}')).data!;
      expect(en, '${now.month}/${now.day}/${now.year}');
    });

    testWidgets(
      'un refus du serveur se dit en anglais, sans le texte du serveur',
      (tester) async {
        final transport = FakeCoupleTransport()
          ..reply('POST /api/couple/memories', error('Not in a couple'));
        await pumpSheet(
          tester,
          (api) => AddMemorySheet(apiService: api),
          transport: transport,
        );
        await tester.enterText(find.byType(TextField).first, 'Rome');
        await tester.pump();
        await tester.tap(find.text('Add'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text("Couldn't add it. Couple mode isn't active."),
          findsOneWidget,
        );
        expect(find.textContaining('Not in a couple'), findsNothing);
      },
    );

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : feuilles sans débordement',
          (tester) async {
            for (final build in <Widget Function(CoupleApiService)>[
              (api) => AddMemorySheet(apiService: api),
              (api) => AddBucketItemSheet(apiService: api),
              (api) => AddDateSheet(apiService: api),
            ]) {
              await pumpSheet(
                tester,
                build,
                locale: locale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
              expect(wordsTooWide(tester), isEmpty);
            }
          },
        );
      }
    }
  });
}
