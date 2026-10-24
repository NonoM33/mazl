import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/privacy/screens/religious_data_settings_screen.dart';

import 'privacy_fakes.dart';

void main() {
  testWidgets('shows the state and the text, with the grant button', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FakePrivacyConsentApi(), const ReligiousDataSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accord non donné'), findsOneWidget);
    expect(find.text(consentText), findsOneWidget);
    expect(find.text('Donner mon accord'), findsOneWidget);
    expect(find.text('Retirer mon accord'), findsNothing);
  });

  testWidgets('withdrawing asks first, naming what will be erased', (
    tester,
  ) async {
    final api = FakePrivacyConsentApi(granted: true, version: '2026-10-24');
    await tester.pumpWidget(host(api, const ReligiousDataSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Accord donné'), findsOneWidget);

    await tester.tap(find.text('Retirer mon accord'));
    await tester.pumpAndSettle();

    expect(api.calls, ['get']);
    expect(find.textContaining('courant'), findsOneWidget);
    expect(find.textContaining('kashrout'), findsOneWidget);
    expect(find.textContaining('Shabbat'), findsOneWidget);
    expect(find.textContaining('intention'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(api.calls, ['get']);

    await tester.tap(find.text('Retirer mon accord'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer mon accord').last);
    await tester.pumpAndSettle();

    expect(api.calls, contains('put:false:2026-10-24'));
    expect(find.text('Accord non donné'), findsOneWidget);
    expect(find.text('Donner mon accord'), findsOneWidget);
  });

  testWidgets('giving consent opens the sheet and records it', (tester) async {
    final api = FakePrivacyConsentApi();
    await tester.pumpWidget(host(api, const ReligiousDataSettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Donner mon accord'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('J\'accepte'));
    await tester.pumpAndSettle();

    expect(api.calls, contains('put:true:2026-10-24'));
    expect(find.text('Accord donné'), findsOneWidget);
  });
}
