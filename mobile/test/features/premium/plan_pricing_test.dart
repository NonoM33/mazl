import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';

// Vu au simulateur le 2026-10-24 : « 2 mois · 9,49 € par mois · US$18,99 ».
// Le prix par mois était écrit avec un « € » à la main, alors que le store
// vendait en dollars. Les deux prix d'une formule doivent parler la même devise,
// celle du produit du store.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  // Espaces insécables de la mise en forme française, remplacés pour comparer.
  String plain(String s) =>
      s.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');

  group('produit en dollars', () {
    test('le total et le prix par mois sont en dollars, jamais en euros', () {
      final total = planTotalLabel(price: 18.99, currencyCode: 'USD');
      final monthly = planMonthlyLabel(
        price: 18.99,
        months: 2,
        currencyCode: 'USD',
      );
      expect(plain(total), '18,99 \$US');
      expect(plain(monthly), '9,50 \$US par mois');
      expect(monthly, isNot(contains('€')));
    });
  });

  group('produit en euros', () {
    test('un an à 89,99 € : 7,50 € par mois', () {
      expect(
        plain(planTotalLabel(price: 89.99, currencyCode: 'EUR')),
        '89,99 €',
      );
      expect(
        plain(planMonthlyLabel(price: 89.99, months: 12, currencyCode: 'EUR')),
        '7,50 € par mois',
      );
    });

    test('un mois : le prix par mois est le prix', () {
      expect(
        plain(planMonthlyLabel(price: 9.99, months: 1, currencyCode: 'EUR')),
        '9,99 € par mois',
      );
    });
  });

  test('une durée inconnue (0 mois) ne divise pas par zéro', () {
    expect(
      plain(planMonthlyLabel(price: 9.99, months: 0, currencyCode: 'EUR')),
      '9,99 € par mois',
    );
  });
}
