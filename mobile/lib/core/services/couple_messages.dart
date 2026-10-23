import 'api_service.dart';

/// Result of a couple action: either it worked, or it carries a French
/// sentence the screen can show as is.
class CoupleActionResult {
  final bool ok;
  final String? message;

  const CoupleActionResult.ok()
      : ok = true,
        message = null;

  const CoupleActionResult.failure(String this.message) : ok = false;
}

/// Turns what the server (or the network layer) answered into one sentence the
/// member can act on. The server speaks in codes (`not_matched`, contract §2)
/// or in the legacy English sentences of the routes that predate them.
String coupleErrorMessage(String? error, [ApiErrorKind? kind]) {
  final code = (error ?? '').toLowerCase();

  if (kind == ApiErrorKind.timeout || kind == ApiErrorKind.network) {
    return error ?? 'Connexion impossible, réessayez dans un instant.';
  }
  if (code.contains('not_matched')) {
    return 'Le mode couple ne s\'active qu\'avec un match.';
  }
  if (code.contains('already in a couple') || code.contains('already_in_couple')) {
    return 'L\'un de vous est déjà en mode couple.';
  }
  if (code.contains('pending')) {
    return code.contains('no longer')
        ? 'Cette demande n\'est plus en attente.'
        : 'Une demande est déjà en attente avec cette personne.';
  }
  if (code.contains('unavailable')) {
    return 'Cette personne n\'est pas disponible.';
  }
  if (code.contains('yourself')) {
    return 'Vous ne pouvez pas vous envoyer une demande.';
  }
  return 'Une erreur est survenue, réessayez dans un instant.';
}
