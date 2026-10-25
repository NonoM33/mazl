import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';

import 'l10n/premium_l10n_harness.dart';

/// La fenêtre « likes du jour épuisés » suit ce que le SERVEUR annonce : sa
/// limite du jour et l'instant de la remise à zéro (`resets_at`), pas une
/// constante ni le minuit du téléphone.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('le compte à rebours va jusqu\'à resets_at, pas jusqu\'à minuit', (
    tester,
  ) async {
    // Le serveur remet à zéro à 00:00 UTC ; il est 21:00 UTC : trois heures.
    final now = DateTime.utc(2026, 10, 25, 21);
    await pumpPlus(
      tester,
      Scaffold(
        body: DailyLimitSheet(
          freeLikesPerDay: 10,
          resetsAt: DateTime.utc(2026, 10, 26),
          now: () => now,
        ),
      ),
    );

    expect(find.text('03:00:00'), findsOneWidget);
  });

  testWidgets('la limite affichée est celle du serveur', (tester) async {
    await pumpPlus(
      tester,
      Scaffold(
        body: DailyLimitSheet(
          freeLikesPerDay: 25,
          resetsAt: DateTime.utc(2026, 10, 26),
          now: () => DateTime.utc(2026, 10, 25, 23, 59, 30),
        ),
      ),
    );

    expect(find.text('LIMITE DU JOUR · 25 / 25'), findsOneWidget);
    expect(find.text('00:00:30'), findsOneWidget);
  });

  testWidgets('sans limite connue, on n\'invente pas de chiffre', (tester) async {
    await pumpPlus(
      tester,
      const Scaffold(body: DailyLimitSheet(freeLikesPerDay: null)),
    );

    expect(find.textContaining('LIMITE DU JOUR'), findsNothing);
    expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
  });
}
