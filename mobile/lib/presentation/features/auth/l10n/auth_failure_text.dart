import '../../../../core/services/auth_service.dart';
import '../../../../l10n/l10n.dart';

/// The sentence for a failed sign-in or account deletion, in the
/// member's language. [unknown] is what the screen says when the cause is not
/// known; the server's own text is never shown.
String authFailureText(
  AppLocalizations l10n,
  AuthFailure? failure, {
  required String unknown,
}) => switch (failure) {
  AuthFailure.cancelled => l10n.authErrorCancelled,
  AuthFailure.rateLimited => l10n.errorRateLimited,
  AuthFailure.invalidCredentials => l10n.authErrorInvalidCredentials,
  AuthFailure.network => l10n.errorNetwork,
  AuthFailure.server => l10n.errorServer,
  AuthFailure.unsupported => l10n.authErrorUnsupported,
  AuthFailure.notSignedIn => l10n.errorSessionExpired,
  AuthFailure.unknown || null => unknown,
};
