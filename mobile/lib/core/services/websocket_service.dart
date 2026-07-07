import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import 'auth_service.dart';

/// Events emitted by the WebSocket service
abstract class ChatEvent {}

class NewMessageEvent extends ChatEvent {
  final int conversationId;
  final int messageId;
  final int senderId;
  final String content;
  final DateTime createdAt;

  NewMessageEvent({
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });
}

class TypingEvent extends ChatEvent {
  final int conversationId;
  final int userId;
  final bool isTyping;

  TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}

class MessagesReadEvent extends ChatEvent {
  final int conversationId;
  final int userId;

  MessagesReadEvent({
    required this.conversationId,
    required this.userId,
  });
}

class NewMatchEvent extends ChatEvent {
  final int matchId;
  final int conversationId;
  final int userId;
  final String userName;
  final String? userPicture;

  NewMatchEvent({
    required this.matchId,
    required this.conversationId,
    required this.userId,
    required this.userName,
    this.userPicture,
  });
}

class ConnectionStatusEvent extends ChatEvent {
  final bool isConnected;

  ConnectionStatusEvent({required this.isConnected});
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _eventController = StreamController<ChatEvent>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  final Random _random = Random();

  static const String _wsUrl = Env.wsUrl;
  static const Duration _pingInterval = Duration(seconds: 30);

  /// Base delay for the exponential backoff (doubles each consecutive failure).
  static const Duration _reconnectBaseDelay = Duration(seconds: 2);

  /// Upper bound for the exponential backoff, before jitter is applied.
  static const Duration _reconnectMaxDelay = Duration(seconds: 60);

  /// Maximum random jitter added to each reconnect delay, in milliseconds.
  static const int _reconnectMaxJitterMs = 1000;

  Stream<ChatEvent> get events => _eventController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final authService = AuthService();
      final token = authService.currentUser?.jwtToken;

      if (token == null) {
        debugPrint('WebSocket: No auth token available');
        _isConnecting = false;
        return;
      }

      final uri = Uri.parse('$_wsUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      // Connection succeeded: reset the backoff so the next disconnect
      // starts again from the base delay.
      _reconnectAttempts = 0;

      debugPrint('WebSocket: Connected');
      _eventController.add(ConnectionStatusEvent(isConnected: true));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

    } catch (e) {
      debugPrint('WebSocket: Connection error: $e');
      _channel = null;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _eventController.add(ConnectionStatusEvent(isConnected: false));
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    if (_channel != null) {
      _send({'type': 'ping'});
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;
      final payload = message['payload'] as Map<String, dynamic>?;

      switch (type) {
        case 'chat:message':
          if (payload != null) {
            _eventController.add(NewMessageEvent(
              conversationId: payload['conversationId'] as int,
              messageId: payload['messageId'] as int,
              senderId: payload['senderId'] as int,
              content: payload['content'] as String,
              createdAt: DateTime.parse(payload['createdAt'] as String),
            ));
          }
          break;

        case 'chat:typing':
          if (payload != null) {
            _eventController.add(TypingEvent(
              conversationId: payload['conversationId'] as int,
              userId: payload['userId'] as int,
              isTyping: payload['isTyping'] as bool? ?? true,
            ));
          }
          break;

        case 'chat:read':
          if (payload != null) {
            _eventController.add(MessagesReadEvent(
              conversationId: payload['conversationId'] as int,
              userId: payload['userId'] as int,
            ));
          }
          break;

        case 'match:new':
          if (payload != null) {
            _eventController.add(NewMatchEvent(
              matchId: payload['matchId'] as int,
              conversationId: payload['conversationId'] as int,
              userId: payload['userId'] as int,
              userName: payload['userName'] as String,
              userPicture: payload['userPicture'] as String?,
            ));
          }
          break;

        case 'pong':
          // Keep-alive response, ignore
          break;

        default:
          debugPrint('WebSocket: Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket: Error: $error');
    _channel = null;
    _eventController.add(ConnectionStatusEvent(isConnected: false));
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('WebSocket: Connection closed');
    _channel = null;
    _pingTimer?.cancel();
    _eventController.add(ConnectionStatusEvent(isConnected: false));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    _reconnectTimer?.cancel();

    final delay = _nextReconnectDelay();
    _reconnectAttempts++;
    debugPrint(
      'WebSocket: Reconnecting in ${delay.inMilliseconds}ms '
      '(attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  /// Computes the next reconnect delay using exponential backoff capped at
  /// [_reconnectMaxDelay], plus a small random jitter to avoid a thundering
  /// herd of clients reconnecting in lockstep.
  Duration _nextReconnectDelay() {
    // Exponential: base * 2^attempts (2s, 4s, 8s, 16s, ...).
    // Guard the exponent so the multiplier never overflows before clamping.
    final exponent = _reconnectAttempts.clamp(0, 30);
    final backoffMs = _reconnectBaseDelay.inMilliseconds * (1 << exponent);
    final cappedMs =
        backoffMs.clamp(0, _reconnectMaxDelay.inMilliseconds).toInt();

    final jitterMs = _random.nextInt(_reconnectMaxJitterMs + 1);
    return Duration(milliseconds: cappedMs + jitterMs);
  }

  void _send(Map<String, dynamic> message) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(message));
  }

  /// Send a chat message
  void sendMessage(int conversationId, String content) {
    _send({
      'type': 'chat:send',
      'payload': {
        'conversationId': conversationId,
        'content': content,
      },
    });
  }

  /// Send typing indicator
  void sendTyping(int conversationId, {bool isTyping = true}) {
    _send({
      'type': 'chat:typing',
      'payload': {
        'conversationId': conversationId,
        'isTyping': isTyping,
      },
    });
  }

  /// Mark messages as read
  void markAsRead(int conversationId) {
    _send({
      'type': 'chat:read',
      'payload': {
        'conversationId': conversationId,
      },
    });
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
