import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/privacy/religious_data_consent.dart';
import 'package:mazl/presentation/features/privacy/widgets/religious_consent_sheet.dart';

import 'privacy_fakes.dart';

const _consent = ReligiousDataConsent(
  granted: null,
  version: null,
  decidedAt: null,
  currentVersion: '2026-10-24',
  text: consentText,
);

Future<List<bool?>> _open(
  WidgetTester tester,
  FakePrivacyConsentApi api,
) async {
  final results = <bool?>[];
  await tester.pumpWidget(
    host(
      api,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async =>
                results.add(await showReligiousConsentSheet(context, _consent)),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return results;
}

ElevatedButton _accept(WidgetTester tester) => tester.widget<ElevatedButton>(
  find.widgetWithText(ElevatedButton, 'J\'accepte'),
);

void main() {
  testWidgets('shows the eyebrow, title and the exact server text', (
    tester,
  ) async {
    await _open(tester, FakePrivacyConsentApi());

    expect(find.text('DONNÉES SENSIBLES · RGPD ARTICLE 9'), findsOneWidget);
    expect(
      find.text('Votre pratique religieuse, avec votre accord'),
      findsOneWidget,
    );
    expect(find.text(consentText), findsOneWidget);
    expect(find.textContaining('utiliser MAZL quand même'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('accept stays disabled until the box is ticked', (tester) async {
    final api = FakePrivacyConsentApi();
    await _open(tester, api);

    expect(_accept(tester).onPressed, isNull);
    await tester.tap(find.text('J\'accepte'), warnIfMissed: false);
    await tester.pump();
    expect(api.calls, isEmpty);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(_accept(tester).onPressed, isNotNull);
  });

  testWidgets('accept sends granted true with the received version', (
    tester,
  ) async {
    final api = FakePrivacyConsentApi();
    final results = await _open(tester, api);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('J\'accepte'));
    await tester.pumpAndSettle();

    expect(api.calls, ['put:true:2026-10-24']);
    expect(results, [true]);
    expect(find.text('J\'accepte'), findsNothing);
  });

  testWidgets('continue without sends granted false, box ticked or not', (
    tester,
  ) async {
    final api = FakePrivacyConsentApi();
    final results = await _open(tester, api);

    await tester.tap(find.text('Continuer sans'));
    await tester.pumpAndSettle();

    expect(api.calls, ['put:false:2026-10-24']);
    expect(results, [false]);
  });

  testWidgets('a failed request keeps the sheet open and says so', (
    tester,
  ) async {
    final api = FakePrivacyConsentApi()..failDecide = true;
    final results = await _open(tester, api);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('J\'accepte'));
    await tester.pumpAndSettle();

    expect(find.textContaining('n\'a pas pu être enregistré'), findsOneWidget);
    expect(results, isEmpty);
    expect(_accept(tester).onPressed, isNotNull);
  });
}
