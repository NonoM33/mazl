import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/store_products.dart';

/// La table de `docs/premium/CREDITS.md`, recopiée ICI depuis le contrat (pas
/// depuis le code testé) : identifiant App Store Connect, type, quantité.
const _contract = <(String, String, int)>[
  ('com.mazl.app.boost.1', 'boost', 1),
  ('com.mazl.app.boost.3', 'boost', 3),
  ('com.mazl.app.superlikes.5', 'super_like', 5),
  ('com.mazl.app.superlikes.15', 'super_like', 15),
];

void main() {
  test('les quatre consommables du contrat, et seulement eux', () {
    expect(kConsumableProducts, hasLength(_contract.length));
    for (final (id, kind, quantity) in _contract) {
      final product = consumableProductById(id);
      expect(product, isNotNull, reason: id);
      expect(product!.kind.wire, kind, reason: id);
      expect(product.quantity, quantity, reason: id);
    }
  });

  test('un identifiant d\'abonnement n\'est pas un consommable', () {
    for (final id in kSubscriptionProductIds) {
      expect(consumableProductById(id), isNull, reason: id);
      expect(isConsumableProductId(id), isFalse, reason: id);
    }
    expect(isConsumableProductId('com.mazl.app.boost.1'), isTrue);
    expect(consumableProductById('autre.chose'), isNull);
  });

  test('les packs d\'un type vont du plus petit au plus grand', () {
    expect(
      consumableProductsOf(CreditKind.boost).map((p) => p.id),
      ['com.mazl.app.boost.1', 'com.mazl.app.boost.3'],
    );
    expect(
      consumableProductsOf(CreditKind.superLike).map((p) => p.quantity),
      [5, 15],
    );
  });

  test('MAZL Couple est le produit Apple du contrat, hors des formules mazl+', () {
    // docs/couple/ESPACE-COUPLE.md §0.1
    expect(kCoupleProductId, 'com.mazl.app.couple.1m');
    expect(kSubscriptionProductIds, isNot(contains(kCoupleProductId)));
    expect(monthsFromProductId(kCoupleProductId), isNull);
    expect(isConsumableProductId(kCoupleProductId), isFalse);
  });

  test('seul iOS vend : la règle des abonnements, au même endroit', () {
    expect(canSellOn(TargetPlatform.iOS), isTrue);
    expect(canSellOn(TargetPlatform.android), isFalse);
  });
}
