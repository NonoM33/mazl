import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/onboarding/screens/onboarding_screen.dart';

import '../../helpers/l10n_helpers.dart';

// Décision de Renaud du 2026-10-25 : aucune façade visible par un client.
// La dernière page de la présentation annonçait un « AI Shadchan » qui
// n'existe pas ; elle présente désormais les suggestions du jour, qui existent
// (GET /api/daily-picks, écran atteint depuis Découvrir).

const _titles = {
  'fr': 'Suggestions du jour',
  'en': 'Daily picks',
  'he': 'הצעות היום',
  'es': 'Sugerencias del día',
  'ru': 'Подборка дня',
};

// Page 3 listait « Questions quotidiennes » et « Milestones de couple » : aucun
// écran de l'espace couple ne les montre (souvenirs, dates importantes,
// bucket list, calendrier et activités, eux, existent).
const _coupleLines = {
  'fr': ['Souvenirs et dates importantes', 'Bucket list à deux'],
  'en': ['Memories and important dates', 'A bucket list for two'],
  'he': ['זיכרונות ותאריכים חשובים', 'רשימת משאלות לשניים'],
  'es': ['Recuerdos y fechas importantes', 'Lista de deseos para dos'],
  'ru': ['Воспоминания и важные даты', 'Список желаний на двоих'],
};

Future<void> _toLastPage(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('${language.code} : la dernière page présente les suggestions '
        'du jour et ne parle ni d\'IA ni de Shadchan', (tester) async {
      await pumpLocalized(
        tester,
        const OnboardingScreen(),
        locale: Locale(language.code),
      );
      await _toLastPage(tester);

      expect(find.text(_titles[language.code]!), findsOneWidget);
      expect(find.textContaining('Shadchan'), findsNothing);
      expect(find.textContaining(RegExp(r'\b(AI|IA)\b')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in AppLanguage.values) {
    testWidgets('${language.code} : la page du mode couple ne cite que des '
        'fonctions de l\'espace couple', (tester) async {
      await pumpLocalized(
        tester,
        const OnboardingScreen(),
        locale: Locale(language.code),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      for (final line in _coupleLines[language.code]!) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      final unwanted = {
        'fr': ['Questions quotidiennes', 'Milestones de couple'],
        'en': ['Daily questions', 'Couple milestones'],
        'he': ['שאלות יומיות', 'אבני דרך של הזוג'],
        'es': ['Preguntas diarias', 'Hitos de pareja'],
        'ru': ['Ежедневные вопросы', 'Важные события пары'],
      };
      for (final line in unwanted[language.code]!) {
        expect(find.text(line), findsNothing, reason: line);
      }
    });
  }
}
