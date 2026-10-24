import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';

/// Total of a plan, in the store product's own currency, written the way
/// [locale] writes money (« 89,99 € » in French, « €89.99 » in English).
String planTotalLabel({
  required double price,
  required String currencyCode,
  required String locale,
}) => _planCurrency(currencyCode, locale).format(price);

/// Price per month of a plan, in the same currency as its total: never a
/// hand-written « € » next to a store that sells in another currency.
String planMonthlyLabel(
  AppLocalizations l10n, {
  required double price,
  required int months,
  required String currencyCode,
}) {
  final perMonth = _planCurrency(
    currencyCode,
    l10n.localeName,
  ).format(_perMonthCents(price, months) / 100);
  return l10n.plusPerMonth(perMonth);
}

/// Rounded to the cent from the price in cents, so 18,99 over 2 months reads
/// 9,50 and not a float artefact (9,4949… shown as 9,49).
int _perMonthCents(double price, int months) =>
    ((price * 100).round() / (months > 0 ? months : 1)).round();

/// The currency of the store, written in the member's language. In French a
/// bare « $ » would be ambiguous, so dollars carry their country (« $US »,
/// « $CA »), as in French typography; the other languages use the symbol
/// `intl` gives them.
NumberFormat _planCurrency(String currencyCode, String locale) {
  final simple = NumberFormat.simpleCurrency(
    locale: locale,
    name: currencyCode,
  );
  if (locale != 'fr' || simple.currencySymbol != r'$') return simple;
  return NumberFormat.currency(
    locale: locale,
    name: currencyCode,
    symbol: currencyCode.length == 3
        ? '\$${currencyCode.substring(0, 2)}'
        : simple.currencySymbol,
  );
}
