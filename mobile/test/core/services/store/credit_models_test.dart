import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/credit_models.dart';

import '../../../support/credits_fakes.dart';

void main() {
  group('CreditBalance.fromJson', () {
    test('lit chaque champ de chaque type, et la remise à zéro en UTC', () {
      final balance = CreditBalance.fromJson(serverCredits());

      expect(balance.superLike.dailyAllowance, 5);
      expect(balance.superLike.dailyRemaining, 3);
      expect(balance.superLike.purchasedBalance, 12);
      expect(balance.superLike.available, 15);
      expect(balance.boost.dailyAllowance, 1);
      expect(balance.boost.dailyRemaining, 0);
      expect(balance.boost.purchasedBalance, 2);
      expect(balance.boost.available, 2);
      expect(balance.resetsAt, DateTime.utc(2026, 11, 2));
      expect(balance.of(CreditKind.superLike), same(balance.superLike));
      expect(balance.of(CreditKind.boost), same(balance.boost));
    });

    test('un solde acheté négatif (remboursement) est conservé tel quel', () {
      final balance = CreditBalance.fromJson(
        serverCredits(boostRemaining: 1, boostPurchased: -2),
      );
      expect(balance.boost.purchasedBalance, -2);
      expect(balance.boost.available, 1);
    });

    test('un champ manquant ou mal typé lève FormatException', () {
      expect(
        () => CreditBalance.fromJson({'super_like': <String, Object?>{}}),
        throwsFormatException,
      );
      final stringCount = serverCredits();
      (stringCount['super_like']! as Map<String, Object?>)['daily_allowance'] =
          '5';
      expect(() => CreditBalance.fromJson(stringCount), throwsFormatException);
      final noReset = serverCredits()..remove('resets_at');
      expect(() => CreditBalance.fromJson(noReset), throwsFormatException);
    });

    test('tryParse rend null au lieu de lever', () {
      expect(CreditBalance.tryParse(null), isNull);
      expect(CreditBalance.tryParse('texte'), isNull);
      expect(CreditBalance.tryParse(<String, Object?>{}), isNull);
      expect(CreditBalance.tryParse(serverCredits()), isNotNull);
    });
  });

  test('CreditKind : le nom de fil du serveur', () {
    expect(CreditKind.superLike.wire, 'super_like');
    expect(CreditKind.boost.wire, 'boost');
  });
}
