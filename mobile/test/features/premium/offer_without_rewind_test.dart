import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/presentation/features/premium/screens/premium_screen.dart';

import 'l10n/premium_l10n_harness.dart';

/// Décision de Renaud du 2026-10-25 : le retour arrière quitte l'offre mazl+.
/// « Rattraper un Passer » ne défaisait rien côté serveur : on ne le promet plus.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('l\'offre ne liste plus le retour arrière, en français', (
    tester,
  ) async {
    await pumpPlus(tester, PremiumScreen(loadPlans: () async => const []));

    expect(find.text('Revenir en arrière'), findsNothing);
    expect(find.text('Rattrapez un « Passer » trop rapide.'), findsNothing);
    // Les autres avantages restent.
    expect(find.text('Likes illimités'), findsOneWidget);
    expect(find.text('Filtres avancés'), findsOneWidget);
  });

  testWidgets('l\'offre ne liste plus le retour arrière, en anglais', (
    tester,
  ) async {
    await pumpPlus(
      tester,
      PremiumScreen(loadPlans: () async => const []),
      locale: l10nCases.first.locale,
    );

    expect(find.text('Rewind'), findsNothing);
    expect(find.text('Unlimited likes'), findsOneWidget);
  });

  test('aucune fonction réservée ne s\'appelle plus retour arrière', () {
    expect(
      PremiumFeature.values.map((feature) => feature.name),
      isNot(contains('rewind')),
    );
  });
}
