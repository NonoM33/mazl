import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/ai_shadchan/screens/ai_suggestions_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

Future<void> _pump(WidgetTester tester, L10nCase c) async {
  await pumpLocalized(
    tester,
    const AISuggestionsScreen(),
    locale: c.locale,
    brightness: c.brightness,
    size: const Size(360, 2200),
  );
  await tester.pump(const Duration(seconds: 1));
}

const _frenchTexts = [
  'Votre Shadchan personnel',
  'Notre IA analyse vos préférences pour vous proposer des profils ultra-compatibles',
  'Suggestions du jour',
  '3 nouvelles',
  'Pourquoi cette suggestion ?',
  'Même niveau de pratique',
  'Intérêts communs : voyages, cuisine',
  'Valeurs familiales alignées',
  'Pratique religieuse similaire',
  'Comment ça marche ?',
  'Notre IA analyse votre profil et vos préférences',
  'Vous recevez des suggestions personnalisées chaque jour',
  'Passer',
  "J'aime",
];

void main() {
  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(
      tester,
      const AISuggestionsScreen(),
      size: const Size(360, 2200),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Votre Shadchan personnel'), findsOneWidget);
    expect(find.text('3 nouvelles'), findsOneWidget);
    expect(find.text('Même niveau de pratique'), findsOneWidget);
    expect(find.text('Passer'), findsNWidgets(3));
  });

  testWidgets('English screen and dismissals', (tester) async {
    await _pump(tester, l10nCases.first);
    expect(find.text('AI Shadchan'), findsOneWidget);
    expect(find.text('Your personal Shadchan'), findsOneWidget);
    expect(find.text('3 new'), findsOneWidget);
    expect(find.text('Same level of observance'), findsOneWidget);
    await tester.tap(find.text('Pass').first);
    await tester.pump();
    expect(find.text('Rachel skipped'), findsOneWidget);
    expect(find.text('2 new'), findsOneWidget);
    await tester.tap(find.text('Pass').first);
    await tester.pump();
    await tester.tap(find.text('Pass').first);
    await tester.pump();
    expect(
      find.text("You've been through all your suggestions."),
      findsOneWidget,
    );
    expect(find.text('Discover more profiles'), findsOneWidget);
  });

  testWidgets('English like confirmation', (tester) async {
    await _pump(tester, l10nCases.first);
    await tester.tap(find.text('Like').first);
    await tester.pump();
    expect(find.text('Rachel added to your likes'), findsOneWidget);
  });

  testWidgets('Hebrew uses matchmaking wording that is not gendered', (
    tester,
  ) async {
    await _pump(tester, const L10nCase(Locale('he'), Brightness.light));
    expect(find.text('השדכן הדיגיטלי'), findsOneWidget);
    expect(find.text('שידוכים אישיים בשבילך'), findsOneWidget);
    expect(find.text('3 חדשות'), findsOneWidget);
  });

  for (final c in l10nCases) {
    testWidgets('screen in ${c.name}', (tester) async {
      await _pump(tester, c);
      expectNoFrench(_frenchTexts);
      expectDirection(tester, find.text('Rachel, 26'), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dismissed suggestions in ${c.name}', (tester) async {
      await _pump(tester, c);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(OutlinedButton).first);
        await tester.pump();
      }
      expectNoFrench([
        'Vous avez parcouru toutes vos suggestions.',
        'Revenez demain pour de nouvelles propositions de votre Shadchan.',
        'Découvrir plus de profils',
        'Rachel ignorée',
        'Miriam ignorée',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
