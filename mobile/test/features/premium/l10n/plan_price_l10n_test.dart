import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/premium/l10n/plan_price.dart';

import 'premium_l10n_harness.dart';

AppLocalizations _l10n(String code) => lookupAppLocalizations(Locale(code));

// The store sells in its own currency; the language only decides how the
// amount is written. French keeps its own rule for the dollar (« $US »).
void main() {
  group('a plan sold in euros', () {
    test('French keeps « 89,99 € » and « 7,50 € par mois »', () {
      expect(
        plain(planTotalLabel(price: 89.99, currencyCode: 'EUR', locale: 'fr')),
        '89,99 €',
      );
      expect(
        plain(
          planMonthlyLabel(
            _l10n('fr'),
            price: 89.99,
            months: 12,
            currencyCode: 'EUR',
          ),
        ),
        '7,50 € par mois',
      );
    });

    test('English puts the euro first and says « per month »', () {
      expect(
        planTotalLabel(price: 89.99, currencyCode: 'EUR', locale: 'en'),
        '€89.99',
      );
      expect(
        planMonthlyLabel(
          _l10n('en'),
          price: 89.99,
          months: 12,
          currencyCode: 'EUR',
        ),
        '€7.50 per month',
      );
    });

    test('Spanish and Russian use the decimal comma', () {
      expect(
        plain(planTotalLabel(price: 44.99, currencyCode: 'EUR', locale: 'es')),
        '44,99 €',
      );
      expect(
        plain(
          planMonthlyLabel(
            _l10n('es'),
            price: 44.99,
            months: 3,
            currencyCode: 'EUR',
          ),
        ),
        '15,00 € al mes',
      );
      expect(
        plain(
          planMonthlyLabel(
            _l10n('ru'),
            price: 44.99,
            months: 3,
            currencyCode: 'EUR',
          ),
        ),
        '15,00 € в месяц',
      );
    });

    test('Hebrew keeps the decimal point and the sentence', () {
      expect(
        plain(planTotalLabel(price: 44.99, currencyCode: 'EUR', locale: 'he')),
        '44.99 €',
      );
      expect(
        plain(
          planMonthlyLabel(
            _l10n('he'),
            price: 44.99,
            months: 3,
            currencyCode: 'EUR',
          ),
        ),
        '15.00 € לחודש',
      );
    });
  });

  group('a plan sold in dollars', () {
    test('French says « \$US » so the dollar is not ambiguous', () {
      expect(
        plain(planTotalLabel(price: 18.99, currencyCode: 'USD', locale: 'fr')),
        '18,99 \$US',
      );
      expect(
        plain(planTotalLabel(price: 18.99, currencyCode: 'CAD', locale: 'fr')),
        '18,99 \$CA',
      );
      final monthly = planMonthlyLabel(
        _l10n('fr'),
        price: 18.99,
        months: 2,
        currencyCode: 'USD',
      );
      expect(plain(monthly), '9,50 \$US par mois');
      expect(monthly, isNot(contains('€')));
    });

    test('English uses the symbol the language gives to the dollar', () {
      expect(
        planTotalLabel(price: 18.99, currencyCode: 'USD', locale: 'en'),
        '\$18.99',
      );
      expect(
        planMonthlyLabel(
          _l10n('en'),
          price: 18.99,
          months: 2,
          currencyCode: 'USD',
        ),
        '\$9.50 per month',
      );
    });

    test('the monthly price never turns into euros in another language', () {
      for (final code in ['en', 'he', 'es', 'ru']) {
        final monthly = planMonthlyLabel(
          _l10n(code),
          price: 18.99,
          months: 2,
          currencyCode: 'USD',
        );
        expect(monthly, isNot(contains('€')), reason: code);
      }
    });
  });

  test('a plan of 0 months does not divide by zero', () {
    expect(
      plain(
        planMonthlyLabel(
          _l10n('fr'),
          price: 9.99,
          months: 0,
          currencyCode: 'EUR',
        ),
      ),
      '9,99 € par mois',
    );
  });

  test('the cents are rounded from the price in cents, not a float', () {
    // 69,99 € over 6 months is 11,665 -> 11,67 (and not 11,66 from a float).
    expect(
      plain(
        planMonthlyLabel(
          _l10n('fr'),
          price: 69.99,
          months: 6,
          currencyCode: 'EUR',
        ),
      ),
      '11,67 € par mois',
    );
  });
}
