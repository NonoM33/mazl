/// Libellés lisibles des réponses de profil, quelle que soit la forme
/// stockée : les écrans successifs ont enregistré « A la maison »,
/// « Tres observant », `kasher_a_la_maison` ou `serious` pour la même idée.
///
/// Rend `null` quand la réponse ne mérite pas de puce (vide, « Non »,
/// « Autre ») ; une valeur inconnue reste lisible, sans `_`.
abstract final class ProfileLabels {
  static String? denomination(String? raw) => _label(raw, _denominations);
  static String? kashrut(String? raw) => _label(raw, _kashrut);
  static String? shabbat(String? raw) => _label(raw, _shabbat);
  static String? intention(String? raw) => _label(raw, _intentions);

  static const _hidden = '';

  static const _denominations = {
    'laique': 'Laïque',
    'traditionaliste': 'Traditionaliste',
    'massorti': 'Massorti',
    'liberal': 'Libéral',
    'liberale': 'Libérale',
    'modern_orthodox': 'Orthodoxe moderne',
    'orthodoxe_moderne': 'Orthodoxe moderne',
    'orthodox': 'Orthodoxe',
    'orthodoxe': 'Orthodoxe',
    'habad': 'Habad',
    'loubavitch': 'Habad',
    'autre': _hidden,
  };

  static const _kashrut = {
    'non': _hidden,
    'no': _hidden,
    'none': _hidden,
    'a_la_maison': 'Cacher à la maison',
    'kasher_a_la_maison': 'Cacher à la maison',
    'cacher_a_la_maison': 'Cacher à la maison',
    'home': 'Cacher à la maison',
    'strict': 'Cacher strict',
    'kasher_strict': 'Cacher strict',
    'glatt': 'Glatt cacher',
  };

  static const _shabbat = {
    'non_observant': _hidden,
    'not_observant': _hidden,
    'partiellement': 'Shabbat en partie',
    'partial': 'Shabbat en partie',
    'partially': 'Shabbat en partie',
    'observant': 'Shabbat observé',
    'tres_observant': 'Shabbat strict',
    'strict': 'Shabbat strict',
    'shabbat_en_famille': 'Shabbat en famille',
  };

  static const _intentions = {
    'marriage': 'Mariage',
    'mariage': 'Mariage',
    'serious': 'Relation sérieuse',
    'open': 'Ouvert à tout',
    'friends_first': "Amitié d'abord",
  };

  static String? _label(String? raw, Map<String, String> known) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final label = known[_key(value)];
    if (label != null) return label.isEmpty ? null : label;
    final spaced = value.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// « Très Observant » → `tres_observant`.
  static String _key(String value) {
    const accents = {'à': 'a', 'â': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u'};
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'[\s\-]+'), '_');
  }
}
