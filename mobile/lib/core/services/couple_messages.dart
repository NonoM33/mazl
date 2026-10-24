import 'api_service.dart';

/// Why a couple action (request, answer, cancel, leave) did not go through.
/// The core only names the cause; the screen says it in the member's language
/// (`CoupleActionFailureLabel` in the presentation layer).
enum CoupleActionFailure {
  /// The couple mode only starts between two members who matched.
  notMatched,

  /// One of the two members is already in a couple.
  alreadyInCouple,

  /// A request is already waiting between these two members.
  requestPending,

  /// The request was answered or cancelled meanwhile.
  requestNoLongerPending,

  /// The other member can no longer be reached (account gone, blocked).
  unavailable,

  /// The member tried to send a request to themselves.
  self,

  /// The member is not in a couple (any more).
  notInCouple,

  /// The couple or the request does not exist (any more).
  notFound,

  /// The couple cannot be ended now (no couple known on this phone).
  cannotLeave,

  /// No connection, or the server is unreachable.
  network,

  /// The server did not answer in time.
  timeout,

  /// The server failed (HTTP 5xx).
  server,

  /// Anything else.
  unknown,
}

/// Result of a couple action: either it worked, or it carries the cause the
/// screen turns into a sentence.
class CoupleActionResult {
  final bool ok;
  final CoupleActionFailure? failure;

  const CoupleActionResult.ok() : ok = true, failure = null;

  const CoupleActionResult.failure(CoupleActionFailure this.failure)
    : ok = false;
}

/// Names what the server (or the network layer) answered. The server speaks in
/// stable codes (`not_matched`, contract §2) and, on the routes that predate
/// them, in English sentences: the code is read first, the sentence is the
/// fallback.
CoupleActionFailure coupleFailureOf(ApiResponse<Object?> response) {
  final kind = response.errorKind;
  if (kind == ApiErrorKind.timeout) return CoupleActionFailure.timeout;
  if (kind == ApiErrorKind.network) return CoupleActionFailure.network;

  final named =
      _failureNamedBy(response.errorCode) ?? _failureNamedBy(response.error);
  if (named != null) return named;

  return switch (kind) {
    ApiErrorKind.server => CoupleActionFailure.server,
    ApiErrorKind.notFound => CoupleActionFailure.notFound,
    _ => CoupleActionFailure.unknown,
  };
}

// What each cause looks like in a stable code (`not_matched`) or in the legacy
// English sentence of the routes that predate codes.
final _notMatched = RegExp('not_matched');
final _alreadyInCouple = RegExp('already in a couple|already_in_couple');
final _noLongerPending = RegExp('no longer');
final _pending = RegExp('pending');
final _unavailable = RegExp('unavailable');
final _yourself = RegExp('yourself');
final _notInCouple = RegExp('not in a couple|not_in_couple');

/// The failure a code (`not_matched`) or a legacy English sentence
/// (`Couple request is no longer pending`) stands for, if it is one we know.
CoupleActionFailure? _failureNamedBy(String? raw) {
  final text = (raw ?? '').toLowerCase();
  if (text.isEmpty) return null;
  if (_notMatched.hasMatch(text)) return CoupleActionFailure.notMatched;
  if (_alreadyInCouple.hasMatch(text)) return CoupleActionFailure.alreadyInCouple;
  if (_pending.hasMatch(text)) {
    return _noLongerPending.hasMatch(text)
        ? CoupleActionFailure.requestNoLongerPending
        : CoupleActionFailure.requestPending;
  }
  if (_unavailable.hasMatch(text)) return CoupleActionFailure.unavailable;
  if (_yourself.hasMatch(text)) return CoupleActionFailure.self;
  if (_notInCouple.hasMatch(text)) return CoupleActionFailure.notInCouple;
  return null;
}
