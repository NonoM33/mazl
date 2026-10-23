import '../services/websocket_service.dart';
import 'chat_realtime.dart';

/// [ChatRealtimeSource] over the app-wide [WebSocketService].
class WebSocketChatRealtimeSource implements ChatRealtimeSource {
  WebSocketChatRealtimeSource(this._service);

  final WebSocketService _service;

  @override
  Stream<ChatRealtimeEvent> events(int conversationId) async* {
    var wasDown = false;
    await for (final event in _service.events) {
      if (event is ChatContractEvent) {
        if (_conversationOf(event.event) == conversationId) yield event.event;
      } else if (event is ConnectionStatusEvent) {
        if (!event.isConnected) {
          wasDown = true;
        } else if (wasDown) {
          wasDown = false;
          yield const ChatReconnected();
        }
      }
    }
  }

  int? _conversationOf(ChatRealtimeEvent event) => switch (event) {
        ChatMessageArrived(:final message) => message.conversationId,
        ChatMessageUpdated(:final message) => message.conversationId,
        ChatTypingChanged(:final conversationId) => conversationId,
        ChatReadUpTo(:final conversationId) => conversationId,
        ChatReconnected() => null,
      };

  @override
  void sendTyping(int conversationId, bool typing) => _service.sendTyping(conversationId, isTyping: typing);
}
