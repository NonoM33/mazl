import 'package:http/http.dart' as http;

import 'premium_transport.dart';

// Typed HTTP client for `POST /api/swipes/undo`. The SERVER decides whether
// the last pass or like can be taken back: the app moves a card back only
// after a success. The server's own error text is never shown.

/// What the server took back.
class UndoneSwipe {
  const UndoneSwipe({
    required this.targetUserId,
    required this.action,
    required this.remainingFreeUndos,
  });

  final int targetUserId;

  /// `like` or `pass`.
  final String action;

  /// How many free undos are left today; null: no limit (mazl+).
  final int? remainingFreeUndos;

  /// The `data` of the answer; null when it is malformed.
  static UndoneSwipe? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final target = json['target_user_id'];
    final action = json['action'];
    if (target is! int) return null;
    if (action != 'like' && action != 'pass') return null;
    if (!json.containsKey('remaining_free_undos')) return null;
    final remaining = json['remaining_free_undos'];
    if (remaining != null && remaining is! int) return null;
    return UndoneSwipe(
      targetUserId: target,
      action: action as String,
      remainingFreeUndos: remaining as int?,
    );
  }
}

/// Why nothing was undone.
enum SwipeUndoErrorKind {
  /// HTTP 402 `undo_limit_reached`: the free undo of the day is used.
  limitReached,

  /// HTTP 404 `nothing_to_undo`: no recent pass or like.
  nothingToUndo,

  /// HTTP 409 `undo_not_possible`: a Super Like, or a match already formed.
  notPossible,
  sessionExpired,
  server,
  timeout,
  network,
  unknown,
}

class SwipeUndoException implements Exception {
  const SwipeUndoException(this.kind, {this.status});

  final SwipeUndoErrorKind kind;
  final int? status;

  @override
  String toString() => '$runtimeType:${kind.name}:${status ?? 0}';
}

abstract interface class SwipeUndoApi {
  /// Takes back the member's last pass or like.
  Future<UndoneSwipe> undoLastSwipe();
}

class HttpSwipeUndoApi implements SwipeUndoApi {
  HttpSwipeUndoApi({PremiumTransport? transport})
    : _transport = transport ?? PremiumTransport.app();

  /// For tests: the client the requests go through.
  HttpSwipeUndoApi.withClient({
    required String baseUrl,
    required String? Function() token,
    required http.Client Function() clientFactory,
  }) : _transport = PremiumTransport(
         baseUrl: baseUrl,
         token: token,
         clientFactory: clientFactory,
       );

  final PremiumTransport _transport;

  @override
  Future<UndoneSwipe> undoLastSwipe() async {
    final TransportReply reply;
    try {
      reply = await _transport.send('POST', '/api/swipes/undo');
    } on TransportFailure catch (failure) {
      throw SwipeUndoException(switch (failure.kind) {
        TransportFailureKind.timeout => SwipeUndoErrorKind.timeout,
        TransportFailureKind.network => SwipeUndoErrorKind.network,
      });
    }
    final status = reply.status;
    final code = reply.errorCode;
    final kind = switch (status) {
      401 => SwipeUndoErrorKind.sessionExpired,
      402 when code == 'undo_limit_reached' => SwipeUndoErrorKind.limitReached,
      404 when code == 'nothing_to_undo' => SwipeUndoErrorKind.nothingToUndo,
      409 when code == 'undo_not_possible' => SwipeUndoErrorKind.notPossible,
      >= 500 => SwipeUndoErrorKind.server,
      _ when !reply.isSuccess => SwipeUndoErrorKind.unknown,
      _ => null,
    };
    if (kind != null) throw SwipeUndoException(kind, status: status);
    final undone = UndoneSwipe.tryParse(reply.data);
    if (undone == null) {
      throw SwipeUndoException(SwipeUndoErrorKind.unknown, status: status);
    }
    return undone;
  }
}
