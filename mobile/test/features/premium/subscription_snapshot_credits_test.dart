import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/premium/screens/subscription_screen.dart';

import '../../support/credits_fakes.dart';

void main() {
  test('« aujourd\'hui » compte l\'inclus du jour du serveur, pas les crédits '
      'achetés (sinon « 15 / 5 »)', () {
    final credits = installTestCredits();
    credits.applyFromServer(serverCredits());

    final snapshot = SubscriptionSnapshot.current();

    expect(snapshot.superLikesLeft, 3);
    expect(snapshot.superLikesMax, 5);
    // Le Boost du jour est utilisé, mais deux Boosts achetés restent.
    expect(snapshot.boostAvailable, isTrue);
  });

  test('sans solde du serveur : rien d\'accordé', () {
    installTestCredits();

    final snapshot = SubscriptionSnapshot.current();

    expect(snapshot.superLikesLeft, 0);
    expect(snapshot.superLikesMax, 0);
    expect(snapshot.boostAvailable, isFalse);
  });
}
