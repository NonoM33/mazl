import '_json_parsing.dart';

/// Blocked user model
class BlockedUser {
  final int id;
  final int userId;
  final String? displayName;
  final String? picture;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.userId,
    this.displayName,
    this.picture,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: parseIntSafe(json['id']) ?? 0,
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'])
          : DateTime.now(),
    );
  }
}
