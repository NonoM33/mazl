import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/common/widgets/block_report_dialog.dart';

import '../../../helpers/l10n_helpers.dart';
import 'l10n_harness.dart';

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () =>
            BlockReportDialog.show(context, userId: 7, userName: 'Jeanne'),
        child: const Text('open'),
      ),
    ),
  );
}

const _frenchOptions = [
  'Bloquer',
  'Signaler',
  'Annuler',
  'Cette personne ne pourra plus vous voir ni vous contacter',
  'Signaler un comportement inapproprié',
];

const _frenchReport = [
  'Signaler un problème',
  'Pourquoi signalez-vous Jeanne ?',
  'Faux profil',
  'Photos volées, identité fausse',
  'Spam / Arnaque',
  'Autre raison (précisez)',
  'Détails supplémentaires (optionnel)',
  'Envoyer le signalement',
];

Future<void> _open(WidgetTester tester, L10nCase c) async {
  await pumpLocalized(
    tester,
    const _Host(),
    locale: c.locale,
    brightness: c.brightness,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('French stays word for word', (tester) async {
    await pumpLocalized(tester, const _Host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Jeanne'), findsOneWidget);
    expect(find.text('Bloquer'), findsOneWidget);
    expect(
      find.text('Cette personne ne pourra plus vous voir ni vous contacter'),
      findsOneWidget,
    );
    await tester.tap(find.text('Signaler'));
    await tester.pumpAndSettle();
    expect(find.text('Pourquoi signalez-vous Jeanne ?'), findsOneWidget);
    expect(find.text('Faux profil'), findsOneWidget);
  });

  testWidgets('English options', (tester) async {
    await _open(tester, l10nCases.first);
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.text("This person won't be able to see you or contact you"),
      findsOneWidget,
    );
  });

  for (final c in l10nCases) {
    testWidgets('options sheet in ${c.name}', (tester) async {
      await _open(tester, c);
      expectNoFrench(_frenchOptions);
      expectDirection(tester, find.text('Jeanne'), c);
      expect(tester.takeException(), isNull);
    });

    testWidgets('report sheet in ${c.name}', (tester) async {
      await _open(tester, c);
      // The option rows are ListTiles: tap the second one.
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();
      expectNoFrench(_frenchReport);
      expect(find.textContaining('Jeanne'), findsOneWidget);
      expectDirection(tester, find.textContaining('Jeanne'), c);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hebrew report sheet reads in Hebrew', (tester) async {
    await _open(tester, const L10nCase(Locale('he'), Brightness.light));
    await tester.tap(find.byType(ListTile).at(1));
    await tester.pumpAndSettle();
    expect(find.text('דיווח על בעיה'), findsOneWidget);
    expect(find.text('מה הסיבה לדיווח על Jeanne?'), findsOneWidget);
    expect(find.text('פרופיל מזויף'), findsOneWidget);
  });
}
