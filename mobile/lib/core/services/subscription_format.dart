/// Libellé de la durée d'une formule à partir de l'identifiant du produit
/// (« com.mazl.app.plus.6m » ou « six_month » -> « 6 mois »). Null si le
/// produit n'est pas reconnu.
String? planLabelForProduct(String productIdentifier) {
  final id = productIdentifier.toLowerCase();
  final plus = RegExp(r'\.plus\.(\d+)m\b').firstMatch(id);
  if (plus != null) return '${plus.group(1)} mois';
  if (id.contains('six_month') || id.contains('6_month')) return '6 mois';
  if (id.contains('three_month') || id.contains('3_month')) return '3 mois';
  if (id.contains('two_month') || id.contains('2_month')) return '2 mois';
  if (id.contains('yearly') || id.contains('annual')) return '12 mois';
  if (id.contains('monthly')) return '1 mois';
  return null;
}

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
