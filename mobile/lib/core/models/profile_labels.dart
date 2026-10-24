/// Les réponses de profil, normalisées vers des types, quelle que soit la
/// forme stockée : les écrans successifs ont enregistré « A la maison »,
/// « Tres observant », `kasher_a_la_maison` ou `serious` pour la même idée.
///
/// Le cœur ne parle pas : il rend un type ([Denomination], [Kashrut],
/// [ShabbatObservance]…) ; les libellés vivent dans
/// `presentation/features/profile/l10n/`.
library;

import 'relationship_intention.dart';

/// Courant du judaïsme pratiqué.
enum Denomination {
  secular,
  traditional,
  masorti,
  liberal,
  modernOrthodox,
  orthodox,
  chabad,
  other;

  /// Les choix proposés à la saisie, dans l'ordre d'affichage.
  static const choices = [
    secular,
    traditional,
    masorti,
    modernOrthodox,
    orthodox,
    chabad,
    other,
  ];
}

/// Niveau de kashrout.
enum Kashrut {
  none,
  home,
  strict,
  glatt;

  static const choices = values;
}

/// Observance du Shabbat.
enum ShabbatObservance {
  notObservant,
  partial,
  observant,
  strict,
  family;

  static const choices = [notObservant, partial, observant, strict];
}

/// Fréquence des visites à la synagogue (saisie à l'inscription seulement).
enum SynagogueVisits { daily, weekly, holidays, rarely }

/// Une réponse stockée, normalisée : soit un type connu, soit les mots du
/// membre (une valeur que l'app ne connaît pas, qui reste lisible).
final class ProfileAnswer<T extends Enum> {
  const ProfileAnswer.known(T this.kind, {this.isHidden = false})
    : custom = null;
  const ProfileAnswer.custom(String this.custom) : kind = null, isHidden = false;

  final T? kind;
  final String? custom;

  /// Vrai quand la réponse ne mérite pas de puce (« Non », « Autre »).
  final bool isHidden;
}

abstract final class ProfileLabels {
  static ProfileAnswer<Denomination>? denominationAnswer(String? raw) =>
      _answer(raw, _denominationKinds, const {Denomination.other});

  static ProfileAnswer<Kashrut>? kashrutAnswer(String? raw) =>
      _answer(raw, _kashrutKinds, const {Kashrut.none});

  static ProfileAnswer<ShabbatObservance>? shabbatAnswer(String? raw) =>
      _answer(raw, _shabbatKinds, const {ShabbatObservance.notObservant});

  static ProfileAnswer<RelationshipIntention>? intentionAnswer(String? raw) =>
      _answer(raw, _intentionKinds, const {});

  static const _denominationKinds = {
    'laique': Denomination.secular,
    'traditionaliste': Denomination.traditional,
    'massorti': Denomination.masorti,
    'liberal': Denomination.liberal,
    'liberale': Denomination.liberal,
    'modern_orthodox': Denomination.modernOrthodox,
    'orthodoxe_moderne': Denomination.modernOrthodox,
    'orthodox': Denomination.orthodox,
    'orthodoxe': Denomination.orthodox,
    'habad': Denomination.chabad,
    'loubavitch': Denomination.chabad,
    'autre': Denomination.other,
  };

  static const _kashrutKinds = {
    'non': Kashrut.none,
    'no': Kashrut.none,
    'none': Kashrut.none,
    'a_la_maison': Kashrut.home,
    'kasher_a_la_maison': Kashrut.home,
    'cacher_a_la_maison': Kashrut.home,
    'home': Kashrut.home,
    'strict': Kashrut.strict,
    'kasher_strict': Kashrut.strict,
    'glatt': Kashrut.glatt,
  };

  static const _shabbatKinds = {
    'non_observant': ShabbatObservance.notObservant,
    'not_observant': ShabbatObservance.notObservant,
    'partiellement': ShabbatObservance.partial,
    'partial': ShabbatObservance.partial,
    'partially': ShabbatObservance.partial,
    'observant': ShabbatObservance.observant,
    'tres_observant': ShabbatObservance.strict,
    'strict': ShabbatObservance.strict,
    'shabbat_en_famille': ShabbatObservance.family,
  };

  static const _intentionKinds = {
    'marriage': RelationshipIntention.marriage,
    'mariage': RelationshipIntention.marriage,
    'serious': RelationshipIntention.serious,
    'relation_serieuse': RelationshipIntention.serious,
    'open': RelationshipIntention.open,
    'friends_first': RelationshipIntention.friendsFirst,
    'je_ne_sais_pas': RelationshipIntention.undecided,
  };

  /// `null` pour une réponse vide ; sinon le type connu, ou les mots du
  /// membre sans `_` et avec une majuscule.
  static ProfileAnswer<T>? _answer<T extends Enum>(
    String? raw,
    Map<String, T> known,
    Set<T> hidden,
  ) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final kind = known[_key(value)];
    if (kind != null) {
      return ProfileAnswer.known(kind, isHidden: hidden.contains(kind));
    }
    final spaced = value.replaceAll('_', ' ');
    return ProfileAnswer.custom(spaced[0].toUpperCase() + spaced.substring(1));
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

  // ---- Anciennes méthodes : le cœur ne doit plus rendre de texte. ----
  // Gardées le temps que `discover_card.dart` (lot matching) passe aux
  // réponses typées ci-dessus ; à supprimer ensuite, avec leurs tables.

  @Deprecated('denominationAnswer')
  static String? denomination(String? raw) => _label(raw, _denominations);
  @Deprecated('kashrutAnswer')
  static String? kashrut(String? raw) => _label(raw, _kashrut);
  @Deprecated('shabbatAnswer')
  static String? shabbat(String? raw) => _label(raw, _shabbat);
  @Deprecated('intentionAnswer')
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
}
