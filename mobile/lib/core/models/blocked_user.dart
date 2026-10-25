import '_json_parsing.dart';

/// A member the current user blocked, as GET /api/users/blocked lists them.
/// The row has no id of its own: [userId] identifies the blocked member.
class BlockedUser {
  final int userId;
  final String? displayName;
  final String? picture;
  final DateTime blockedAt;

  BlockedUser({
    required this.userId,
    this.displayName,
    this.picture,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'])
          : DateTime.now(),
    );
  }
}
