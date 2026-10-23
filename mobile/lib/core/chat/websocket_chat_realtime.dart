import '../services/websocket_service.dart';
import 'chat_realtime.dart';

/// [ChatRealtime] over the app-wide [WebSocketService].
class WebSocketChatRealtime implements ChatRealtime {
  WebSocketChatRealtime(this._service);

  final WebSocketService _service;

  @override
  Stream<ChatRealtimeEvent> get events async* {
    var wasDown = false;
    await for (final event in _service.events) {
      if (event is ChatContractEvent) {
        yield event.event;
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

  @override
  void sendTyping(int conversationId, bool typing) => _service.sendTyping(conversationId, isTyping: typing);
}
