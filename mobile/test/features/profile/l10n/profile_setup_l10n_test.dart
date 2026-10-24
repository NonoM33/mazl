import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/presentation/features/profile/screens/profile_setup_screen.dart';

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
const _es = Locale('es');

Future<void> _open(
  WidgetTester tester,
  Locale locale, {
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    const ProfileSetupScreen(),
    locale: locale,
    brightness: brightness,
    overrides: [_consentGiven],
  );
  await tester.pumpAndSettle();
}

/// Remplit l'étape 1 (prénom, date, genre) puis passe à l'étape [target].
Future<void> _fillAndGo(
  WidgetTester tester, {
  required String next,
  required String man,
  required int steps,
}) async {
  await tester.enterText(find.byType(TextFormField).first, 'Jeanne');
  await tester.tap(find.byIcon(LucideIcons.calendar));
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextButton),
        )
        .last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(man));
  await tester.pump();
  for (var i = 0; i < steps; i++) {
    await tester.tap(find.text(next));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('inscription en anglais', () {
    testWidgets('étape 1 : titres, champs et indication de date', (
      tester,
    ) async {
      await _open(tester, _en);
      expect(find.text('Step 1/4'), findsOneWidget);
      expect(find.text('Tell us about you'), findsOneWidget);
      expect(
        find.text('This information will be visible on your profile'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'First name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'City'), findsOneWidget);
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('MM/DD/YYYY'), findsOneWidget);
      expect(find.text('A man'), findsOneWidget);
      expect(find.text('A woman'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('les erreurs de saisie parlent anglais', (tester) async {
      await _open(tester, _en);
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Enter your first name to continue'), findsOneWidget);
    });

    testWidgets('la date choisie s\'écrit à la manière de la langue', (
      tester,
    ) async {
      await _open(tester, _en);
      await tester.tap(find.byIcon(LucideIcons.calendar));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      final now = DateTime.now();
      final initial = DateTime(now.year - 25, now.month, now.day);
      expect(find.text(DateFormat.yMd('en').format(initial)), findsOneWidget);
    });

    testWidgets('les quatre étapes, jusqu\'au bouton « Finish »', (
      tester,
    ) async {
      await _open(tester, _en);
      await _fillAndGo(tester, next: 'Next', man: 'A man', steps: 1);
      expect(find.text('Step 2/4'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsOneWidget);
      expect(
        find.text('Profiles with good-quality photos get 3x more matches.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3/4'), findsOneWidget);
      expect(find.text('Your practice'), findsOneWidget);
      expect(find.text('Secular'), findsOneWidget);
      expect(find.text('Modern Orthodox'), findsOneWidget);
      expect(find.text('At home'), findsOneWidget);
      expect(find.text('Very observant'), findsOneWidget);
      expect(find.text('On holidays'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4/4'), findsOneWidget);
      expect(find.text('What you\'re looking for'), findsOneWidget);
      expect(find.text('Age range'), findsOneWidget);
      expect(find.text('Marriage'), findsOneWidget);
      expect(find.text('Serious relationship'), findsOneWidget);
      expect(find.text("I don't know yet"), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });
  });

  group('de droite à gauche et autres langues', () {
    for (final brightness in Brightness.values) {
      testWidgets(
        'hébreu, ${brightness.name} : les quatre étapes tiennent à 360 px',
        (tester) async {
          await _open(tester, _he, brightness: brightness);
          expect(
            textDirectionAt(tester, find.text('קצת עליך')),
            TextDirection.rtl,
          );
          expect(find.text('שלב 1/4'), findsOneWidget);
          expect(find.text('DD.MM.YYYY'), findsOneWidget);
          await _fillAndGo(tester, next: 'הבא', man: 'גבר', steps: 1);
          expect(find.text('שלב 2/4'), findsOneWidget);
          await tester.tap(find.text('הבא'));
          await tester.pumpAndSettle();
          expect(find.text('אורח החיים הדתי שלך'), findsOneWidget);
          await tester.tap(find.text('הבא'));
          await tester.pumpAndSettle();
          expect(find.text('סיום'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'le retour est une flèche qui pointe vers la droite en hébreu',
      (tester) async {
        await _open(tester, _he);
        await _fillAndGo(tester, next: 'הבא', man: 'גבר', steps: 1);
        expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
        final arrow = tester.widget<Transform>(
          find
              .ancestor(
                of: find.byIcon(LucideIcons.arrowLeft),
                matching: find.byType(Transform),
              )
              .first,
        );
        expect(arrow.transform.storage[0], -1, reason: 'miroir horizontal');
      },
    );

    testWidgets('russe : titres des étapes sans débordement', (tester) async {
      await _open(tester, _ru, brightness: Brightness.dark);
      expect(find.text('Шаг 1/4'), findsOneWidget);
      expect(find.text('Расскажите о себе'), findsOneWidget);
      await _fillAndGo(tester, next: 'Далее', man: 'Мужчина', steps: 2);
      expect(find.text('Ваша практика'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('espagnol : étape 1 et indication de date', (tester) async {
      await _open(tester, _es);
      expect(find.text('Paso 1/4'), findsOneWidget);
      expect(find.text('Fecha de nacimiento'), findsOneWidget);
      expect(find.text('DD/MM/AAAA'), findsOneWidget);
    });
  });
}
