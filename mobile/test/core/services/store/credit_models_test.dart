import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/credit_models.dart';

/// Forme du `credits` renvoyé par le serveur, recopiée de
/// `src/features/credits/domain/view.ts` (KindCredits / CreditsView).
Map<String, Object?> serverCredits({
  Map<String, Object?>? superLike,
  Map<String, Object?>? boost,
}) => {
  'super_like':
      superLike ??
      {
        'daily_allowance': 5,
        'daily_remaining': 3,
        'purchased_balance': 12,
        'available': 15,
      },
  'boost':
      boost ??
      {
        'daily_allowance': 1,
        'daily_remaining': 0,
        'purchased_balance': 2,
        'available': 2,
      },
  'resets_at': '2026-10-25T00:00:00.000Z',
};

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
      expect(balance.resetsAt, DateTime.utc(2026, 10, 25));
      expect(balance.of(CreditKind.superLike), same(balance.superLike));
      expect(balance.of(CreditKind.boost), same(balance.boost));
    });

    test('un solde acheté négatif (remboursement) est conservé tel quel', () {
      final balance = CreditBalance.fromJson(
        serverCredits(
          boost: {
            'daily_allowance': 1,
            'daily_remaining': 1,
            'purchased_balance': -2,
            'available': 1,
          },
        ),
      );
      expect(balance.boost.purchasedBalance, -2);
      expect(balance.boost.available, 1);
    });

    test('un champ manquant ou mal typé lève FormatException', () {
      expect(
        () => CreditBalance.fromJson({'super_like': <String, Object?>{}}),
        throwsFormatException,
      );
      expect(
        () => CreditBalance.fromJson(
          serverCredits(
            superLike: {
              'daily_allowance': '5',
              'daily_remaining': 3,
              'purchased_balance': 12,
              'available': 15,
            },
          ),
        ),
        throwsFormatException,
      );
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
