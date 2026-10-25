import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/credits_fakes.dart';

void main() {
  late CreditsService credits;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    credits = installTestCredits();
  });

  tearDown(PremiumGate.resetForTest);

  group('likes quotidiens : le serveur seul les compte', () {
    test('plus de compteur local ni de clé locale pour eux', () {
      final source = File(
        'lib/core/services/premium_gate.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('premium_gate_free_likes_used')));
      expect(source, isNot(contains('premium_gate_quota_date')));
      expect(source, isNot(contains('tryConsumeFreeLike')));
      expect(source, isNot(contains('guardLike')));
      expect(source, isNot(contains('freeLikesPerDay =')));
    });
  });

  group('boosts et Super Likes : le solde du serveur', () {
    test('solde inconnu : rien n\'est accordé', () {
      expect(PremiumGate.remainingSuperLikes, 0);
      expect(PremiumGate.superLikesPerDay, 0);
      expect(PremiumGate.remainingBoosts, 0);
    });

    test('les compteurs lisent available et daily_allowance du serveur', () {
      credits.applyFromServer(serverCredits());

      expect(PremiumGate.remainingSuperLikes, 15);
      expect(PremiumGate.superLikesPerDay, 5);
      expect(PremiumGate.remainingBoosts, 2);
    });

    test('un nouveau solde du serveur se lit tout de suite', () {
      credits.applyFromServer(serverCredits());
      credits.applyFromServer(
        serverCredits(
          superLikeAllowance: 1,
          superLikeRemaining: 0,
          superLikePurchased: 0,
          boostRemaining: 0,
          boostPurchased: 0,
        ),
      );

      expect(PremiumGate.remainingSuperLikes, 0);
      expect(PremiumGate.superLikesPerDay, 1);
      expect(PremiumGate.remainingBoosts, 0);
    });

    test('être abonné ou non ne change rien : le serveur seul décide', () {
      credits.applyFromServer(
        serverCredits(superLikeRemaining: 0, superLikePurchased: 0),
      );
      PremiumGate.debugPremiumOverride = true;
      expect(PremiumGate.remainingSuperLikes, 0);
      PremiumGate.debugPremiumOverride = false;
      expect(PremiumGate.remainingSuperLikes, 0);
    });

    test('plus de compteur local ni de clé locale pour eux', () {
      final source = File(
        'lib/core/services/premium_gate.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('useSuperLike')));
      expect(source, isNot(contains('useBoost')));
      expect(source, isNot(contains('premium_gate_super_likes_used')));
      expect(source, isNot(contains('premium_gate_boosts_used')));
    });
  });
}
