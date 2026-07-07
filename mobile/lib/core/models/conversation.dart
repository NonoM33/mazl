import '_json_parsing.dart';

/// Conversation model
class Conversation {
  final int id;
  final int matchId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ConversationUser? otherUser;

  Conversation({
    required this.id,
    required this.matchId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: parseIntSafe(json['id']) ?? 0,
      matchId: parseIntSafe(json['matchId']) ?? 0,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: parseIntSafe(json['unreadCount']) ?? 0,
      otherUser: json['otherUser'] != null
          ? ConversationUser.fromJson(json['otherUser'])
          : null,
    );
  }
}

/// Conversation user model
class ConversationUser {
  final int userId;
  final String? displayName;
  final String? picture;
  final bool isVerified;

  ConversationUser({
    required this.userId,
    this.displayName,
    this.picture,
    this.isVerified = false,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      isVerified: json['is_verified'] == true,
    );
  }
}
