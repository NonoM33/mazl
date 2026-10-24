import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/privacy/widgets/religious_data_gate.dart';
import 'package:mazl/l10n/l10n.dart';

import 'privacy_fakes.dart';

const _fields = Text('CHAMPS PRATIQUE');

class _Probe extends StatefulWidget {
  const _Probe({required this.seen});

  final List<bool> seen;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) =>
      ReligiousDataGate(onValidityChanged: widget.seen.add, child: _fields);
}

Future<void> _pump(
  WidgetTester tester,
  FakePrivacyConsentApi api,
  List<bool> seen,
) async {
  await tester.pumpWidget(host(api, _Probe(seen: seen)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without consent the fields are replaced by the card', (
    tester,
  ) async {
    final seen = <bool>[];
    await _pump(tester, FakePrivacyConsentApi(), seen);

    expect(find.text('CHAMPS PRATIQUE'), findsNothing);
    expect(
      find.text('Pour renseigner votre pratique, donnez votre accord'),
      findsOneWidget,
    );
    expect(seen.last, isFalse);
  });

  testWidgets('a consent given to an older text does not unlock', (
    tester,
  ) async {
    final seen = <bool>[];
    await _pump(
      tester,
      FakePrivacyConsentApi(granted: true, version: '2026-01-01'),
      seen,
    );

    expect(find.text('CHAMPS PRATIQUE'), findsNothing);
    expect(seen.last, isFalse);
  });

  testWidgets('accepting in the sheet unlocks the fields', (tester) async {
    final api = FakePrivacyConsentApi();
    final seen = <bool>[];
    await _pump(tester, api, seen);

    await tester.tap(find.text('Donner mon accord'));
    await tester.pumpAndSettle();
    expect(find.text(consentText), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('J\'accepte'));
    await tester.pumpAndSettle();

    expect(api.calls, contains('put:true:2026-10-24'));
    expect(find.text('CHAMPS PRATIQUE'), findsOneWidget);
    expect(seen.last, isTrue);
  });

  testWidgets('refusing keeps the fields locked', (tester) async {
    final api = FakePrivacyConsentApi();
    final seen = <bool>[];
    await _pump(tester, api, seen);

    await tester.tap(find.text('Donner mon accord'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer sans'));
    await tester.pumpAndSettle();

    expect(api.calls, contains('put:false:2026-10-24'));
    expect(find.text('CHAMPS PRATIQUE'), findsNothing);
    expect(seen.last, isFalse);
  });

  testWidgets('with a valid consent the fields show at once', (tester) async {
    final seen = <bool>[];
    await _pump(
      tester,
      FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
      seen,
    );

    expect(find.text('CHAMPS PRATIQUE'), findsOneWidget);
    expect(find.text('Donner mon accord'), findsNothing);
    expect(seen.last, isTrue);
  });

  testWidgets('when the consent cannot be read the fields stay locked', (
    tester,
  ) async {
    final seen = <bool>[];
    await _pump(tester, FakePrivacyConsentApi()..failFetch = true, seen);

    expect(find.text('CHAMPS PRATIQUE'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(seen.last, isFalse);
  });

  testWidgets('ReligiousDataLocked blocks taps while locked', (tester) async {
    var taps = 0;
    Widget build(bool locked) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: ReligiousDataLocked(
        locked: locked,
        child: ElevatedButton(onPressed: () => taps++, child: const Text('x')),
      ),
    );

    await tester.pumpWidget(build(true));
    await tester.tap(find.text('x'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      find.textContaining('Disponible une fois votre accord'),
      findsOneWidget,
    );

    await tester.pumpWidget(build(false));
    await tester.tap(find.text('x'));
    expect(taps, 1);
  });
}
