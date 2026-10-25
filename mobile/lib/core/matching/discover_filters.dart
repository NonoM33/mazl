/// Les filtres avancés de Découvrir (mazl+), tels que le serveur les garde :
/// `GET/PUT /api/discover/filters`. Ils disent qui le membre veut voir, ils ne
/// décrivent pas le membre (cela reste dans le profil).
///
/// Les listes portent les réponses TELLES QU'ELLES SONT ENREGISTRÉES dans les
/// profils (« Massorti », « Tres observant »), jamais des libellés traduits.
/// `null` = aucun critère.
class DiscoverFilters {
  const DiscoverFilters({
    this.denominations,
    this.kashrutLevels,
    this.shabbatObservances,
    this.onlyVerified = false,
    this.onlyWithPhoto = false,
  });

  static const none = DiscoverFilters();

  factory DiscoverFilters.fromJson(Map<String, dynamic> json) =>
      DiscoverFilters(
        denominations: _answers(json, 'denominations'),
        kashrutLevels: _answers(json, 'kashrutLevels'),
        shabbatObservances: _answers(json, 'shabbatObservances'),
        onlyVerified: _flag(json, 'onlyVerified'),
        onlyWithPhoto: _flag(json, 'onlyWithPhoto'),
      );

  final List<String>? denominations;
  final List<String>? kashrutLevels;
  final List<String>? shabbatObservances;
  final bool onlyVerified;
  final bool onlyWithPhoto;

  /// Vrai quand un critère sur la pratique religieuse est posé (article 9).
  bool get hasReligiousCriterion =>
      denominations != null ||
      kashrutLevels != null ||
      shabbatObservances != null;

  /// Le corps complet du `PUT` : chaque critère est écrit, `null` l'efface.
  Map<String, dynamic> toJson() => {
    'denominations': denominations,
    'kashrutLevels': kashrutLevels,
    'shabbatObservances': shabbatObservances,
    'onlyVerified': onlyVerified,
    'onlyWithPhoto': onlyWithPhoto,
  };

  @override
  bool operator ==(Object other) =>
      other is DiscoverFilters &&
      _sameList(denominations, other.denominations) &&
      _sameList(kashrutLevels, other.kashrutLevels) &&
      _sameList(shabbatObservances, other.shabbatObservances) &&
      onlyVerified == other.onlyVerified &&
      onlyWithPhoto == other.onlyWithPhoto;

  @override
  int get hashCode => Object.hash(
    denominations == null ? null : Object.hashAll(denominations!),
    kashrutLevels == null ? null : Object.hashAll(kashrutLevels!),
    shabbatObservances == null ? null : Object.hashAll(shabbatObservances!),
    onlyVerified,
    onlyWithPhoto,
  );
}

/// Ce que `GET /api/discover/filters` rend : les critères gardés, et si le
/// membre est abonné mazl+ (les critères ne s'appliquent que dans ce cas).
class DiscoverFiltersState {
  const DiscoverFiltersState({required this.filters, required this.plus});

  factory DiscoverFiltersState.fromJson(Map<String, dynamic> json) {
    final filters = json['filters'];
    final plus = json['plus'];
    if (filters is! Map<String, dynamic> || plus is! bool) {
      throw const FormatException('discover filters');
    }
    return DiscoverFiltersState(
      filters: DiscoverFilters.fromJson(filters),
      plus: plus,
    );
  }

  final DiscoverFilters filters;
  final bool plus;
}

bool _sameList(List<String>? a, List<String>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<String>? _answers(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('invalid $key');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

bool _flag(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return false;
  if (value is! bool) throw FormatException('invalid $key');
  return value;
}
