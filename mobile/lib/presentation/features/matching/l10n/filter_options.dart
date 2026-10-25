import '../../../../l10n/l10n.dart';

/// A choice of a multiple-choice filter: the words on screen come from
/// [label]; [storedValues] are the answers the profiles hold for it, exactly
/// as the server compares them (trimmed, lower-cased, nothing else).
///
/// The profile screens have written the same idea in several ways over time
/// (« Orthodox », « Orthodoxe »), so a choice lists every spelling: choosing it
/// finds the members whichever version of the app they filled in.
class FilterChoice {
  const FilterChoice(this.storedValues, this.label);

  final List<String> storedValues;
  final String Function(AppLocalizations l10n) label;

  /// True when the server's saved answers [saved] contain this choice.
  bool isIn(Iterable<String> saved) {
    final keys = saved.map(_key).toSet();
    return storedValues.any((value) => keys.contains(_key(value)));
  }
}

String _key(String answer) => answer.trim().toLowerCase();

/// The answers to send for [selected]: every spelling of every choice.
List<String> answersOf(Iterable<FilterChoice> selected) => [
  for (final choice in selected) ...choice.storedValues,
];

/// The religious movements the members can filter on. The movements a profile
/// cannot hold (séfarade, ashkénaze: a custom, not a movement) are not offered.
final denominationChoices = <FilterChoice>[
  FilterChoice(['Laique', 'Laïque'], (l) => l.profileDenominationSecular),
  FilterChoice(['Traditionaliste'], (l) => l.profileDenominationTraditional),
  FilterChoice(['Massorti', 'Masorti'], (l) => l.profileDenominationMasorti),
  FilterChoice([
    'Liberal',
    'Libéral',
    'Liberale',
    'Libérale',
  ], (l) => l.profileDenominationLiberal),
  FilterChoice([
    'Modern Orthodox',
    'Orthodoxe moderne',
    'modern_orthodox',
    'orthodoxe_moderne',
  ], (l) => l.profileDenominationModernOrthodox),
  FilterChoice(['Orthodox', 'Orthodoxe'], (l) => l.profileDenominationOrthodox),
  FilterChoice([
    'Habad',
    'Chabad',
    'Loubavitch',
  ], (l) => l.profileDenominationChabad),
];

final kashrutChoices = <FilterChoice>[
  FilterChoice(['Non', 'No', 'None'], (l) => l.profileKashrutNone),
  FilterChoice([
    'A la maison',
    'À la maison',
    'a_la_maison',
    'Kasher a la maison',
    'kasher_a_la_maison',
    'Cacher a la maison',
    'cacher_a_la_maison',
    'Home',
  ], (l) => l.profileKashrutOptionHome),
  FilterChoice([
    'Strict',
    'Kasher strict',
    'kasher_strict',
  ], (l) => l.profileKashrutOptionStrict),
  FilterChoice(['Glatt'], (l) => l.profileKashrutOptionGlatt),
];

final shabbatChoices = <FilterChoice>[
  FilterChoice([
    'Non observant',
    'non_observant',
    'Not observant',
  ], (l) => l.profileShabbatNotObservant),
  FilterChoice([
    'Partiellement',
    'Partially',
    'Partial',
  ], (l) => l.profileShabbatOptionPartial),
  FilterChoice(['Observant'], (l) => l.profileShabbatOptionObservant),
  FilterChoice([
    'Tres observant',
    'Très observant',
    'tres_observant',
  ], (l) => l.profileShabbatOptionStrict),
];
