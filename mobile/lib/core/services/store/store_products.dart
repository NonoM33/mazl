import 'package:flutter/foundation.dart' show TargetPlatform;

import 'credit_models.dart';

/// Les produits d'abonnement mazl+ vendus par le store. UN SEUL endroit : tout
/// le reste de l'application (achat, restauration, libellés) part de cette
/// liste.
///
/// Un identifiant suit `com.mazl.app.plus.<n>m`, où `<n>` est la durée en mois.
const List<String> kSubscriptionProductIds = [
  'com.mazl.app.plus.1m',
  'com.mazl.app.plus.3m',
  'com.mazl.app.plus.6m',
  'com.mazl.app.plus.12m',
];

/// MAZL Couple : l'abonnement du couple (29,99 €/mois), du même groupe
/// d'abonnements que mazl+, au niveau le plus haut. Un seul des deux paie, les
/// deux en profitent (docs/couple/ESPACE-COUPLE.md §0.1). Il n'entre pas dans
/// [kSubscriptionProductIds] : ses écrans ne vendent que mazl+, et l'écran
/// MAZL Couple ne vend que lui.
const String kCoupleProductId = 'com.mazl.app.couple.1m';

final RegExp _productIdPattern = RegExp(r'^com\.mazl\.app\.plus\.(\d{1,2})m$');

/// Durée en mois lue dans l'identifiant du produit, ou null si l'identifiant
/// n'est pas un produit mazl+ (aucune durée n'est inventée).
int? monthsFromProductId(String productId) {
  final match = _productIdPattern.firstMatch(productId);
  if (match == null) return null;
  final months = int.parse(match.group(1)!);
  return months > 0 ? months : null;
}

/// Un consommable vendu par le store : ce qu'il crédite, et combien.
class ConsumableProduct {
  const ConsumableProduct(this.id, this.kind, this.quantity);

  /// Identifiant App Store Connect (type Consommable).
  final String id;
  final CreditKind kind;
  final int quantity;
}

/// Les quatre consommables, décrits ICI et nulle part ailleurs (contrat
/// `docs/premium/CREDITS.md`). Du plus petit au plus grand pour chaque type.
const List<ConsumableProduct> kConsumableProducts = [
  ConsumableProduct('com.mazl.app.boost.1', CreditKind.boost, 1),
  ConsumableProduct('com.mazl.app.boost.3', CreditKind.boost, 3),
  ConsumableProduct('com.mazl.app.superlikes.5', CreditKind.superLike, 5),
  ConsumableProduct('com.mazl.app.superlikes.15', CreditKind.superLike, 15),
];

/// Le consommable d'identifiant [productId], ou null s'il n'en est pas un.
ConsumableProduct? consumableProductById(String productId) {
  for (final product in kConsumableProducts) {
    if (product.id == productId) return product;
  }
  return null;
}

bool isConsumableProductId(String productId) =>
    consumableProductById(productId) != null;

/// Les packs d'un type, du plus petit au plus grand.
List<ConsumableProduct> consumableProductsOf(CreditKind kind) => [
  for (final product in kConsumableProducts)
    if (product.kind == kind) product,
]..sort((a, b) => a.quantity.compareTo(b.quantity));

/// Seul iOS vend : le serveur ne vérifie pas encore Google Play, et on
/// n'ouvre jamais un droit sur un achat non vérifié. Même règle pour les
/// abonnements et les consommables.
bool canSellOn(TargetPlatform platform) => platform == TargetPlatform.iOS;
