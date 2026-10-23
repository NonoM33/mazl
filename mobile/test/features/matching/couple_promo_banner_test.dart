import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/matching/screens/matches_screen.dart';

// Paid on 2026-10-23: after sending a couple request, the Matches banner kept
// offering « Activer le mode couple » as if nothing had been sent.
void main() {
  test('pas de bannière tant qu\'une demande attend une réponse', () {
    expect(shouldShowCouplePromo(coupleModeEnabled: false, hasPendingRequest: true, dismissed: false), isFalse);
  });

  test('bannière pour qui peut encore activer le mode couple', () {
    expect(shouldShowCouplePromo(coupleModeEnabled: false, hasPendingRequest: false, dismissed: false), isTrue);
  });

  test('ni en couple, ni après fermeture', () {
    expect(shouldShowCouplePromo(coupleModeEnabled: true, hasPendingRequest: false, dismissed: false), isFalse);
    expect(shouldShowCouplePromo(coupleModeEnabled: false, hasPendingRequest: false, dismissed: true), isFalse);
  });
}
