import '../../../../core/premium/passport_cities.dart';
import '../../../../l10n/l10n.dart';

/// A suggested city's name in the member's language.
String passportCityLabel(AppLocalizations l10n, PassportCity city) =>
    switch (city) {
      PassportCity.telAviv => l10n.passportCityTelAviv,
      PassportCity.jerusalem => l10n.passportCityJerusalem,
      PassportCity.newYork => l10n.passportCityNewYork,
      PassportCity.london => l10n.passportCityLondon,
      PassportCity.montreal => l10n.passportCityMontreal,
      PassportCity.paris => l10n.passportCityParis,
      PassportCity.marseille => l10n.passportCityMarseille,
      PassportCity.lyon => l10n.passportCityLyon,
      PassportCity.nice => l10n.passportCityNice,
    };

/// The name of the city the server holds: the suggested city's translated
/// name when it is one of them, the server's own text otherwise.
String passportServerCityLabel(AppLocalizations l10n, String serverCity) {
  final suggested = PassportCity.named(serverCity);
  return suggested == null ? serverCity : passportCityLabel(l10n, suggested);
}
