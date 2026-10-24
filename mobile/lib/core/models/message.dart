import '_json_parsing.dart';

/// Message model
class Message {
  final int id;
  final int senderId;
  final String content;
  final String? imageUrl;
  final String messageType; // 'text' or 'image'
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
  });

  bool get isImage => messageType == 'image' || imageUrl != null;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: parseIntSafe(json['id']) ?? 0,
      senderId: parseIntSafe(json['sender_id']) ?? 0,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
