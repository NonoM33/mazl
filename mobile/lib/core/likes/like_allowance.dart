import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// What the SERVER says a member can still like today
/// (`GET /api/likes/allowance`, `domain/allowance.ts`). The app never counts
/// likes itself: it only relays this.
@immutable
class LikeAllowance {
  const LikeAllowance({
    required this.dailyAllowance,
    required this.remaining,
    required this.resetsAt,
  });

  /// Likes included per day; null for a mazl+ member (unlimited).
  final int? dailyAllowance;

  /// Likes left until [resetsAt]; null when unlimited.
  final int? remaining;

  /// When the day's count starts again, as the server reckons it.
  final DateTime resetsAt;

  bool get isUnlimited => remaining == null;

  /// No like left at [now]. After [resetsAt] what the app knows is out of
  /// date, so it does not refuse anything: the server will say.
  bool isExhaustedAt(DateTime now) {
    final left = remaining;
    return left != null && left <= 0 && now.isBefore(resetsAt);
  }

  /// The allowance object of the contract, or null when it is not one.
  static LikeAllowance? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final daily = json['daily_allowance'];
    final remaining = json['remaining'];
    final resetsAt = json['resets_at'];
    if (daily != null && daily is! int) return null;
    if (remaining != null && remaining is! int) return null;
    if (resetsAt is! String) return null;
    final reset = DateTime.tryParse(resetsAt);
    if (reset == null) return null;
    return LikeAllowance(
      dailyAllowance: daily as int?,
      remaining: remaining as int?,
      resetsAt: reset,
    );
  }
}

/// A like the server refused because the day's likes are gone: HTTP 402 with
/// the code `likes_exhausted` (`like-allowance.routes.ts`). Not to be mixed up
/// with the 402 of a Super Like or a Boost ([ApiResponse.isCreditsExhausted]).
extension LikesExhaustedResponse<T> on ApiResponse<T> {
  bool get isLikesExhausted =>
      statusCode == 402 && errorCode == 'likes_exhausted';

  /// The allowance the refusal carries, when it does.
  LikeAllowance? get exhaustedAllowance =>
      isLikesExhausted ? LikeAllowance.tryParse(body?['allowance']) : null;
}
