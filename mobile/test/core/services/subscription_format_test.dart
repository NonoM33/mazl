import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/subscription_format.dart';

void main() {
  group('planLabelForProduct', () {
    test('reconnaît les produits mazl+ d\'App Store Connect', () {
      expect(planLabelForProduct('com.mazl.app.plus.1m'), '1 mois');
      expect(planLabelForProduct('com.mazl.app.plus.3m'), '3 mois');
      expect(planLabelForProduct('com.mazl.app.plus.6m'), '6 mois');
      expect(planLabelForProduct('com.mazl.app.plus.12m'), '12 mois');
    });

    test('reconnaît les durées des produits RevenueCat', () {
      expect(planLabelForProduct('monthly'), '1 mois');
      expect(planLabelForProduct('two_month'), '2 mois');
      expect(planLabelForProduct('six_month'), '6 mois');
      expect(planLabelForProduct('yearly'), '12 mois');
      expect(planLabelForProduct('com.mazl.mazlpro.six_month:base'), '6 mois');
    });

    test('un produit inconnu n\'a pas de libellé inventé', () {
      expect(planLabelForProduct('consumable'), isNull);
      expect(planLabelForProduct('com.mazl.app.boost.3'), isNull);
      expect(planLabelForProduct('com.mazl.app.superlikes.15'), isNull);
    });
  });

  group('formatFrenchDate', () {
    test('écrit la date en toutes lettres', () {
      expect(formatFrenchDate(DateTime(2027, 3, 12)), '12 mars 2027');
      expect(formatFrenchDate(DateTime(2026, 12, 31)), '31 décembre 2026');
      expect(formatFrenchDate(DateTime(2026, 8, 5)), '5 août 2026');
    });

    test('premier du mois : « 1er »', () {
      expect(formatFrenchDate(DateTime(2027, 1, 1)), '1er janvier 2027');
    });
  });
}
