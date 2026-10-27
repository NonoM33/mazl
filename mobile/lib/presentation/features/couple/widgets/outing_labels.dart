import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';

/// The words of an outing: the model keeps the API's numbers and dates, the
/// screen writes them the way the member's language does.
extension OutingLabels on Outing {
  /// « Gratuit » for 0, otherwise « 35 € » (« €35 » in English); null when
  /// the price is unknown.
  String? priceLabel(AppLocalizations l10n) {
    final cents = priceCents;
    if (cents == null) return null;
    if (cents == 0) return l10n.coupleOutingsFree;
    return NumberFormat.currency(
      locale: l10n.localeName,
      symbol: '€',
      decimalDigits: cents % 100 == 0 ? 0 : 2,
    ).format(cents / 100);
  }

  /// The line of a tile: « sam. 7 nov. · Paris 3e · 35 € ».
  String tileMeta(AppLocalizations l10n) {
    final date = startsAt;
    return _join(l10n, [
      if (date != null)
        DateFormat.MMMEd(l10n.localeName).format(date.toLocal()),
      city,
      priceLabel(l10n),
    ]);
  }

  /// The line of the featured outing: « vendredi 6 novembre · Paris 17e · 35 €
  /// par couple ».
  String featuredMeta(AppLocalizations l10n) {
    final date = startsAt;
    final price = priceLabel(l10n);
    return _join(l10n, [
      if (date != null)
        DateFormat.MMMMEEEEd(l10n.localeName).format(date.toLocal()),
      city,
      if (price != null && priceCents != 0)
        l10n.coupleOutingsPerCouple(price)
      else
        price,
    ]);
  }

  static String _join(AppLocalizations l10n, List<String?> parts) => parts
      .whereType<String>()
      .where((p) => p.isNotEmpty)
      .join(l10n.coupleOutingsMetaSeparator);
}
