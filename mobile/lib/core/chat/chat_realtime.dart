import '../models/_json_parsing.dart';
import '../models/chat_message.dart';

// Real-time side of the chat. CONTRACT: docs/chat/CONTRAT.md §3.

sealed class ChatRealtimeEvent {
  const ChatRealtimeEvent();
}

/// `chat:message`: a new message, sent by the other member or echoed back to
/// the author.
class ChatMessageArrived extends ChatRealtimeEvent {
  const ChatMessageArrived(this.message);
  final ChatMessage message;
}

/// `chat:updated`: link preview arrived, message unsent, reactions changed.
class ChatMessageUpdated extends ChatRealtimeEvent {
  const ChatMessageUpdated(this.message);
  final ChatMessage message;
}

class ChatTypingChanged extends ChatRealtimeEvent {
  const ChatTypingChanged({required this.conversationId, required this.userId, required this.isTyping});
  final int conversationId;
  final int userId;
  final bool isTyping;
}

/// `chat:read`: [userId] has read everything up to [upToId].
class ChatReadUpTo extends ChatRealtimeEvent {
  const ChatReadUpTo({required this.conversationId, required this.userId, required this.upToId, required this.readAt});
  final int conversationId;
  final int userId;
  final int upToId;
  final DateTime readAt;
}

/// The socket came back after a drop: the app may have missed events.
class ChatReconnected extends ChatRealtimeEvent {
  const ChatReconnected();
}

/// Where the chat controller gets its real-time input: the WebSocket in the
/// app, a polling source in the demo, a fake in tests.
abstract class ChatRealtimeSource {
  /// Events of one conversation (plus [ChatReconnected]). Listening starts the
  /// source for that conversation, cancelling stops it.
  Stream<ChatRealtimeEvent> events(int conversationId);

  void sendTyping(int conversationId, bool typing);
}

/// Decodes a `{type, payload}` envelope into a contract event. Returns null
/// for other types, for the legacy flat payloads and for malformed data.
ChatRealtimeEvent? parseChatEnvelope(String type, Map<String, dynamic> payload) {
  try {
    switch (type) {
      case 'chat:message':
        final message = payload['message'];
        if (message is! Map<String, dynamic>) return null;
        return ChatMessageArrived(ChatMessage.fromJson(message));
      case 'chat:updated':
        final message = payload['message'];
        if (message is! Map<String, dynamic>) return null;
        return ChatMessageUpdated(ChatMessage.fromJson(message));
      case 'chat:typing':
        final conversationId = parseIntSafe(payload['conversation_id'] ?? payload['conversationId']);
        final userId = parseIntSafe(payload['user_id'] ?? payload['userId']);
        if (conversationId == null || userId == null) return null;
        final typing = payload['is_typing'] ?? payload['isTyping'];
        return ChatTypingChanged(conversationId: conversationId, userId: userId, isTyping: typing != false);
      case 'chat:read':
        final conversationId = parseIntSafe(payload['conversation_id']);
        final userId = parseIntSafe(payload['user_id']);
        final upToId = parseIntSafe(payload['up_to_id']);
        if (conversationId == null || userId == null || upToId == null) return null;
        final readAt = payload['read_at'];
        return ChatReadUpTo(
          conversationId: conversationId,
          userId: userId,
          upToId: upToId,
          readAt: readAt is String ? DateTime.parse(readAt) : DateTime.now(),
        );
    }
  } on Object {
    return null;
  }
  return null;
}

/// One line for the conversation list.
String chatPreviewText(ChatMessage message) {
  if (message.unsent) return 'Message retiré';
  return switch (message.type) {
    ChatMessageType.photo => 'Photo',
    ChatMessageType.voice => 'Message vocal',
    ChatMessageType.text => message.content,
  };
}
