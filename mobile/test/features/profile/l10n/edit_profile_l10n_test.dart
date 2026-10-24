import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/presentation/features/profile/screens/edit_profile_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import '../../../presentation/privacy/privacy_fakes.dart';

/// The practice fields sit behind the article 9 consent: it is given here.
final _consentGiven = privacyConsentApiProvider.overrideWithValue(
  FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
);

const _en = Locale('en');
const _he = Locale('he');
const _ru = Locale('ru');

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Un serveur de profil de démonstration (jamais le vrai réseau).
MockClient _server({
  String? kashrut = 'A la maison',
  String? denomination = 'Modern Orthodox',
  String? shabbat = 'Partiellement',
  int meStatus = 200,
  List<Map<String, Object?>> myPrompts = const [],
}) => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/auth/me') {
    if (meStatus != 200) return _json({'success': false}, meStatus);
    return _json({
      'success': true,
      'user': {
        'id': 1,
        'email': 'jeanne@example.com',
        'name': 'Jeanne Exemple',
      },
      'profile': {
        'id': 1,
        'user_id': 1,
        'display_name': 'Jeanne Exemple',
        'location': 'Paris',
        'bio': '',
        'denomination': denomination,
        'kashrut_level': kashrut,
        'shabbat_observance': shabbat,
        'relationship_intention': 'serious',
      },
    });
  }
  if (path == '/api/profile/photos') {
    return _json({'success': true, 'photos': []});
  }
  if (path == '/api/prompts') {
    return _json({
      'prompts': [
        {
          'id': 'shabbat_ideal',
          'text': 'Mon Shabbat idéal...',
          'category': 'jewish',
        },
        {
          'id': 'first_date',
          'text': 'Premier date idéal...',
          'category': 'conversation',
        },
      ],
    });
  }
  if (path == '/api/profile/prompts') return _json({'prompts': myPrompts});
  return _json({'success': false}, 404);
});

Future<void> _open(
  WidgetTester tester, {
  required Locale locale,
  Brightness brightness = Brightness.light,
  MockClient? server,
}) async {
  await http.runWithClient(() async {
    await pumpLocalized(
      tester,
      const EditProfileScreen(),
      locale: locale,
      brightness: brightness,
      overrides: [_consentGiven],
    );
    await tester.pumpAndSettle();
  }, () => server ?? _server());
}

void main() {
  setUpAll(loadAppFonts);

  group('modification du profil en anglais', () {
    testWidgets('titres, champs et valeurs normalisées', (tester) async {
      await _open(tester, locale: _en);

      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Press and hold to set as main photo'), findsOneWidget);
      expect(find.text('Tell us about yourself…'), findsOneWidget);
      expect(find.text('My prompts'), findsOneWidget);
      // Les valeurs stockées (« Modern Orthodox », « A la maison »,
      // « Partiellement ») se lisent dans la langue du membre.
      await tester.scrollUntilVisible(
        find.text('My practice'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Basic information'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Modern Orthodox'), findsOneWidget);
      expect(find.text('At home'), findsOneWidget);
      expect(find.text('Partially'), findsOneWidget);
      expect(find.text('Denomination'), findsOneWidget);
      // Le français ne reste nulle part.
      expect(find.text('Partiellement'), findsNothing);
      expect(find.text('A la maison'), findsNothing);
    });

    testWidgets('« Non renseigné » devient « Not specified »', (tester) async {
      await _open(
        tester,
        locale: _en,
        server: _server(kashrut: null, denomination: null, shabbat: null),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Not specified'), findsNWidgets(3));
    });

    testWidgets(
      'la feuille de choix liste les libellés, la sélection garde la valeur stockée',
      (tester) async {
        await _open(tester, locale: _en);
        await tester.scrollUntilVisible(
          find.text('Shabbat'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        // Past the Save bar that floats over the bottom of the list.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Partially'));
        await tester.pumpAndSettle();

        expect(find.text('Not observant'), findsOneWidget);
        expect(find.text('Very observant'), findsOneWidget);
        await tester.tap(find.text('Very observant'));
        await tester.pumpAndSettle();
        // La valeur d'origine est choisie par type : le champ montre le libellé court.
        expect(find.text('Very observant'), findsOneWidget);
      },
    );

    testWidgets('la feuille de modification d\'un champ texte parle anglais', (
      tester,
    ) async {
      await _open(tester, locale: _en);
      await tester.scrollUntilVisible(
        find.text('City'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('City'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Save'), findsWidgets);
    });

    testWidgets(
      'une panne du serveur dit une phrase traduite, jamais le diagnostic',
      (tester) async {
        await _open(tester, locale: _en, server: _server(meStatus: 503));
        expect(
          find.text('The server is unavailable. Try again in a moment.'),
          findsOneWidget,
        );
        expect(find.textContaining('HTTP'), findsNothing);
        expect(find.text('Try again'), findsOneWidget);
      },
    );
  });

  group('prompts : questions traduites par identifiant', () {
    testWidgets('mes réponses gardent leur texte, la question se traduit', (
      tester,
    ) async {
      await _open(
        tester,
        locale: _en,
        server: _server(
          myPrompts: [
            {
              'id': 7,
              'prompt_id': 'shabbat_ideal',
              'prompt_text': 'Mon Shabbat idéal...',
              'answer': 'Une longue table.',
              'position': 1,
            },
            {
              'id': 8,
              'prompt_id': 'question_inconnue',
              'prompt_text': 'Une question du serveur',
              'answer': 'Oui.',
              'position': 2,
            },
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('My ideal Shabbat...'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('My ideal Shabbat...'), findsOneWidget);
      // La réponse du membre ne se traduit pas.
      expect(find.text('Une longue table.'), findsOneWidget);
      // Un identifiant inconnu garde le texte du serveur.
      expect(find.text('Une question du serveur'), findsOneWidget);
      expect(find.text('Mon Shabbat idéal...'), findsNothing);
    });

    testWidgets('la liste des questions est groupée sous des titres traduits', (
      tester,
    ) async {
      await _open(tester, locale: _he);
      await tester.scrollUntilVisible(
        find.text('להוסיף שאלה'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('להוסיף שאלה'));
      await tester.pumpAndSettle();
      expect(find.text('לבחור שאלה'), findsOneWidget);
      expect(find.text('יהדות'), findsOneWidget);
      expect(find.text('שיחה'), findsOneWidget);
      expect(find.text('השבת האידיאלית שלי...'), findsOneWidget);
      expect(find.text('הדייט הראשון המושלם...'), findsOneWidget);
    });
  });

  group('de droite à gauche', () {
    for (final brightness in Brightness.values) {
      testWidgets(
        'hébreu, ${brightness.name} : sens de lecture et pas de débordement',
        (tester) async {
          await _open(tester, locale: _he, brightness: brightness);
          expect(
            textDirectionAt(tester, find.text('עריכת פרופיל')),
            TextDirection.rtl,
          );
          await tester.scrollUntilVisible(
            find.text('אורח החיים הדתי שלי'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('אורתודוקסי מודרני').evaluate().isEmpty, isTrue);
          expect(find.text('דתי לאומי (אורתודוקסי מודרני)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('russe : les libellés longs tiennent à 360 px', (tester) async {
      await _open(tester, locale: _ru, brightness: Brightness.dark);
      expect(find.text('Редактирование профиля'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Моя практика'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
