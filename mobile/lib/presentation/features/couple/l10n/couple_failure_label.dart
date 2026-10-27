import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_messages.dart';
import '../../../../l10n/l10n.dart';

/// The sentence for a couple action that did not go through, in the member's
/// language. The core only names the cause.
extension CoupleActionFailureLabel on CoupleActionFailure {
  String label(AppLocalizations l10n) => switch (this) {
    CoupleActionFailure.notMatched => l10n.coupleSpaceFailNotMatched,
    CoupleActionFailure.alreadyInCouple => l10n.coupleSpaceFailAlreadyInCouple,
    CoupleActionFailure.requestPending => l10n.coupleSpaceFailRequestPending,
    CoupleActionFailure.requestNoLongerPending =>
      l10n.coupleSpaceFailRequestGone,
    CoupleActionFailure.unavailable => l10n.coupleSpaceFailUnavailable,
    CoupleActionFailure.self => l10n.coupleSpaceFailSelf,
    CoupleActionFailure.notInCouple => l10n.coupleSpaceFailNotInCouple,
    CoupleActionFailure.notFound => l10n.errorNotFound,
    CoupleActionFailure.cannotLeave => l10n.coupleSpaceFailCannotLeave,
    CoupleActionFailure.network => l10n.errorNetwork,
    CoupleActionFailure.timeout => l10n.errorTimeout,
    CoupleActionFailure.server => l10n.errorServer,
    CoupleActionFailure.unknown => l10n.coupleSpaceFailUnknown,
  };
}

/// The sentence for a couple content call (activities, events, space) that
/// failed. [CoupleFailure.message] is a diagnostic for the logs, never shown.
extension CoupleFailureLabel on CoupleFailure {
  String label(AppLocalizations l10n) => switch (kind) {
    CoupleFailureKind.network => l10n.errorNetwork,
    CoupleFailureKind.notFound => l10n.errorNotFound,
    CoupleFailureKind.routeMissing => l10n.coupleFailRouteMissing,
    CoupleFailureKind.subscriptionRequired =>
      l10n.coupleFailSubscriptionRequired,
    CoupleFailureKind.rateLimited => l10n.coupleFailRateLimited,
    CoupleFailureKind.alreadyDone => l10n.coupleFailAlreadyDone,
    CoupleFailureKind.notInCouple => l10n.coupleSpaceFailNotInCouple,
    CoupleFailureKind.full => l10n.coupleSpaceFailEventFull,
    CoupleFailureKind.server => l10n.coupleSpaceFailServer,
    CoupleFailureKind.malformed => l10n.coupleSpaceFailUnexpected,
  };
}
