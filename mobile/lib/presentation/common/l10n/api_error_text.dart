import '../../../core/services/api_service.dart';
import '../../../l10n/l10n.dart';

/// The sentence for a failed API call, in the member's language. Screens
/// never show `ApiResponse.error`: it is a diagnostic for the logs.
String apiErrorText(AppLocalizations l10n, ApiErrorKind? kind) =>
    switch (kind) {
      ApiErrorKind.timeout => l10n.errorTimeout,
      ApiErrorKind.network => l10n.errorNetwork,
      ApiErrorKind.server => l10n.errorServer,
      ApiErrorKind.unauthorized => l10n.errorSessionExpired,
      ApiErrorKind.forbidden => l10n.errorForbidden,
      ApiErrorKind.notFound => l10n.errorNotFound,
      ApiErrorKind.conflict => l10n.errorConflict,
      ApiErrorKind.tooLarge => l10n.errorTooLarge,
      ApiErrorKind.rateLimited => l10n.errorRateLimited,
      ApiErrorKind.invalid => l10n.errorInvalid,
      ApiErrorKind.creditsExhausted => l10n.packsErrorExhausted,
      ApiErrorKind.boostAlreadyActive => l10n.packsBoostAlreadyActive,
      ApiErrorKind.unknown || null => l10n.errorUnknown,
    };

String apiResponseErrorText(
  AppLocalizations l10n,
  ApiResponse<Object?> response,
) => apiErrorText(l10n, response.errorKind);
