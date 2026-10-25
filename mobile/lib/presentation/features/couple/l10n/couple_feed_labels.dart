import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/couple_message_view.dart';
import 'couple_failure_label.dart';

/// A price in whole euros, written the way the language writes it
/// (« €120 », « 120 € »).
String formatEuros(String locale, int euros) => NumberFormat.currency(
  locale: locale,
  symbol: '€',
  decimalDigits: 0,
).format(euros);

/// A rating with one decimal, in the language's own decimal sign.
String formatRating(String locale, double rating) =>
    NumberFormat('0.0', locale).format(rating);

/// The words of an activity: the core model keeps the API's identifiers and
/// numbers, the screen turns them into a sentence in the member's language.
extension CoupleActivityLabels on CoupleActivity {
  String categoryName(AppLocalizations l10n) =>
      activityCategoryLabel(l10n, category);

  String priceLabel(AppLocalizations l10n) {
    final euros = priceEuros;
    if (euros == null) return l10n.coupleFeedPriceFree;
    return formatEuros(l10n.localeName, euros);
  }

  /// « 45 min », « 2 h », « 2 h 30 min »; null when the duration is unknown.
  String? durationLabel(AppLocalizations l10n) {
    final total = durationMinutes;
    if (total == null) return null;
    if (total < 60) return l10n.coupleFeedDurationMinutes(total);
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (minutes == 0) return l10n.coupleFeedDurationHours(hours);
    return l10n.coupleFeedDurationHoursMinutes(hours, minutes);
  }

  /// The note alone, or the note and the number of reviews: « 4,8 (124) ».
  String ratingLabel(AppLocalizations l10n) {
    final rating = formatRating(l10n.localeName, this.rating!);
    final count = reviewCount;
    if (count == null) return rating;
    return '$rating (${NumberFormat.decimalPattern(l10n.localeName).format(count)})';
  }

  /// « 4,8 (124 avis) », the long form of the detail screen.
  String ratingWithReviewsLabel(AppLocalizations l10n) {
    final rating = formatRating(l10n.localeName, this.rating!);
    final count = reviewCount;
    if (count == null) return rating;
    return l10n.coupleFeedRatingWithReviews(rating, count);
  }
}

String activityCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'wellness' => l10n.coupleFeedCategoryWellness,
      'gastronomy' => l10n.coupleFeedCategoryGastronomy,
      'culture' => l10n.coupleFeedCategoryCulture,
      'sport' => l10n.coupleFeedCategorySport,
      'travel' => l10n.coupleFeedCategoryTravel,
      'spiritual' => l10n.coupleFeedCategorySpiritual,
      'diy' => l10n.coupleFeedCategoryDiy,
      'romantic' => l10n.coupleFeedCategoryRomantic,
      // A category the app does not know yet: the server's own word.
      _ => category,
    };

/// A filter chip of the activities feed; null is « all ».
String activityFilterLabel(AppLocalizations l10n, String? category) =>
    switch (category) {
      null => l10n.coupleFeedFilterAll,
      'gastronomy' => l10n.coupleFeedFilterGastronomy,
      _ => activityCategoryLabel(l10n, category),
    };

extension CoupleEventLabels on CoupleEvent {
  String priceLabel(AppLocalizations l10n) {
    final euros = priceEuros;
    if (euros == null) return l10n.coupleFeedPriceFree;
    return l10n.coupleFeedEventPricePerCouple(
      formatEuros(l10n.localeName, euros),
    );
  }

  /// « jeu. 12 nov. », « Thu, Nov 12 ».
  String dateLabel(AppLocalizations l10n) =>
      DateFormat.MMMEd(l10n.localeName).format(eventDate);

  /// « 19:30 », « 7:30 PM »; empty when the event has no time.
  String timeLabel(AppLocalizations l10n) {
    final time = startTime;
    if (time == null) return eventTime ?? '';
    return DateFormat.jm(
      l10n.localeName,
    ).format(DateTime(2000, 1, 1, time.hour, time.minute));
  }

  /// The date, then the time when there is one.
  String whenLabel(AppLocalizations l10n) {
    final time = timeLabel(l10n);
    return [dateLabel(l10n), if (time.isNotEmpty) time].join(' · ');
  }
}

/// The error state of a couple content screen, in the member's language:
/// what went wrong, and a way to try again.
Widget coupleFailureView(
  BuildContext context,
  CoupleFailure failure, {
  VoidCallback? onRetry,
}) {
  final l10n = context.l10n;
  return CoupleMessageView(
    icon: LucideIcons.alertCircle,
    title: l10n.coupleFeedLoadFailedTitle,
    line: failure.label(l10n),
    actionLabel: onRetry == null ? null : l10n.commonRetry,
    onAction: onRetry,
  );
}

/// The back arrow, pointing the way « back » goes: Lucide arrows do not
/// mirror themselves, and [RoundIconButton] takes an icon, not a widget.
IconData backArrowIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? LucideIcons.arrowRight
    : LucideIcons.arrowLeft;
