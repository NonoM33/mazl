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

final RegExp _productIdPattern = RegExp(r'^com\.mazl\.app\.plus\.(\d{1,2})m$');

/// Durée en mois lue dans l'identifiant du produit, ou null si l'identifiant
/// n'est pas un produit mazl+ (aucune durée n'est inventée).
int? monthsFromProductId(String productId) {
  final match = _productIdPattern.firstMatch(productId);
  if (match == null) return null;
  final months = int.parse(match.group(1)!);
  return months > 0 ? months : null;
}
