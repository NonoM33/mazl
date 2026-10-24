import 'store/store_products.dart';

/// Libellé de la durée d'une formule à partir de l'identifiant du produit
/// (« com.mazl.app.plus.6m » -> « 6 mois »). Null si le produit n'est pas
/// reconnu.
String? planLabelForProduct(String productIdentifier) {
  final months = monthsFromProductId(productIdentifier);
  return months == null ? null : monthsLabel(months);
}

/// « 1 mois », « 6 mois ».
String monthsLabel(int months) => '$months mois';

const _frenchMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « 23 octobre 2026 », « 1er mars 2027 ».
String formatFrenchDate(DateTime date) {
  final day = date.day == 1 ? '1er' : '${date.day}';
  return '$day ${_frenchMonths[date.month - 1]} ${date.year}';
}
