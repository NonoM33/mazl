import '../../../../l10n/l10n.dart';

/// The religious movements of the Discover filters. [apiValue] is what the
/// server has always received for this filter; the words on screen come from
/// [label].
enum FilterDenomination {
  all('Toutes'),
  orthodox('Orthodoxe'),
  masorti('Massorti'),
  liberal('Libéral'),
  traditional('Traditionaliste'),
  chabad('Loubavitch'),
  sephardi('Séfarade'),
  ashkenazi('Ashkénaze');

  const FilterDenomination(this.apiValue);

  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
    all => l10n.matchingFiltersDenominationAll,
    orthodox => l10n.matchingFiltersDenominationOrthodox,
    masorti => l10n.matchingFiltersDenominationMasorti,
    liberal => l10n.matchingFiltersDenominationLiberal,
    traditional => l10n.matchingFiltersDenominationTraditional,
    chabad => l10n.matchingFiltersDenominationChabad,
    sephardi => l10n.matchingFiltersDenominationSephardi,
    ashkenazi => l10n.matchingFiltersDenominationAshkenazi,
  };
}

/// The religious practices of the Discover filters (several can be chosen).
enum FilterObservance {
  shabbat('Shomer Shabbat'),
  kosher('Casher'),
  kosherStrict('Casher strict'),
  dailyPrayer('Prière quotidienne'),
  mikveh('Mikvé'),
  tzniut('Tsniout');

  const FilterObservance(this.apiValue);

  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
    shabbat => l10n.matchingFiltersShabbat,
    kosher => l10n.matchingFiltersKosher,
    kosherStrict => l10n.matchingFiltersKosherStrict,
    dailyPrayer => l10n.matchingFiltersDailyPrayer,
    mikveh => l10n.matchingFiltersMikveh,
    tzniut => l10n.matchingFiltersTzniut,
  };
}

/// The education levels of the Discover filters.
enum FilterEducation {
  all('Tous'),
  highSchool('Lycée'),
  baccalaureate('Bac'),
  bachelor('Licence'),
  master('Master'),
  doctorate('Doctorat'),
  yeshiva('Yeshiva/Sem');

  const FilterEducation(this.apiValue);

  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
    all => l10n.matchingFiltersEducationAll,
    highSchool => l10n.matchingFiltersEducationHighSchool,
    baccalaureate => l10n.matchingFiltersEducationBaccalaureate,
    bachelor => l10n.matchingFiltersEducationBachelor,
    master => l10n.matchingFiltersEducationMaster,
    doctorate => l10n.matchingFiltersEducationDoctorate,
    yeshiva => l10n.matchingFiltersEducationYeshiva,
  };
}
