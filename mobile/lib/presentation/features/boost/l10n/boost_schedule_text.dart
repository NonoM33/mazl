import '../../../../core/premium/boost_schedule_api.dart';
import '../../../../l10n/l10n.dart';

/// What to tell the member when scheduling a Boost failed. The server's own
/// text is never shown: the app writes the sentence from the stable kind.
/// [BoostScheduleErrorKind.boostsExhausted] has no sentence: the packs sheet
/// opens instead.
String? boostScheduleErrorText(
  AppLocalizations l10n,
  BoostScheduleErrorKind kind,
) => switch (kind) {
  BoostScheduleErrorKind.boostsExhausted => null,
  BoostScheduleErrorKind.alreadyScheduled => l10n.boostScheduleAlready,
  BoostScheduleErrorKind.invalidTime => l10n.boostScheduleInvalidTime,
  _ => l10n.boostScheduleFailed,
};
