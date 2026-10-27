import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/chat_realtime.dart';
import 'package:mazl/core/services/websocket_service.dart';

// Payloads copied from docs/chat/CONTRAT.md §3.
const messageJson = {
  'id': 812,
  'conversation_id': 40,
  'sender_id': 45,
  'client_id': 'c-1',
  'type': 'text',
  'content': 'Salut !',
  'media': <Object>[],
  'voice': null,
  'reply_to': null,
  'reactions': <Object>[],
  'link_preview': null,
  'created_at': '2026-10-22T20:45:00.000Z',
  'read_at': null,
  'unsent': false,
};

void main() {
  group('parseChatEnvelope', () {
    test('chat:message carries a full message', () {
      final event = parseChatEnvelope('chat:message', {'message': messageJson});
      expect(event, isA<ChatMessageArrived>());
      expect((event as ChatMessageArrived).message.id, 812);
      expect(event.message.clientId, 'c-1');
    });

    test('chat:updated carries a full message', () {
      final event = parseChatEnvelope('chat:updated', {'message': messageJson});
      expect(event, isA<ChatMessageUpdated>());
      expect((event as ChatMessageUpdated).message.content, 'Salut !');
    });

    test('chat:typing', () {
      final event = parseChatEnvelope('chat:typing', {'conversation_id': 40, 'user_id': 45, 'is_typing': true});
      expect(event, isA<ChatTypingChanged>());
      final typing = event as ChatTypingChanged;
      expect(typing.conversationId, 40);
      expect(typing.userId, 45);
      expect(typing.isTyping, isTrue);
    });

    test('chat:typing with the legacy camelCase keys', () {
      final event = parseChatEnvelope('chat:typing', {'conversationId': 40, 'userId': 45, 'isTyping': false});
      final typing = event as ChatTypingChanged;
      expect(typing.conversationId, 40);
      expect(typing.userId, 45);
      expect(typing.isTyping, isFalse);
    });

    test('chat:read', () {
      final event = parseChatEnvelope('chat:read', {
        'conversation_id': 40,
        'user_id': 45,
        'up_to_id': 812,
        'read_at': '2026-10-22T20:47:00.000Z',
      });
      final read = event as ChatReadUpTo;
      expect(read.conversationId, 40);
      expect(read.userId, 45);
      expect(read.upToId, 812);
      expect(read.readAt, DateTime.utc(2026, 10, 22, 20, 47));
    });

    test('a chat:read without read_at tells nothing: no time is invented', () {
      // The server leaves read_at out when the sender is not a mazl+ member or
      // the reader keeps their receipts off (docs/premium/MONETISATION.md §4).
      expect(
        parseChatEnvelope('chat:read', {'conversation_id': 40, 'user_id': 45, 'up_to_id': 812}),
        isNull,
      );
      expect(
        parseChatEnvelope('chat:read', {'conversation_id': 40, 'user_id': 45, 'up_to_id': 812, 'read_at': null}),
        isNull,
      );
    });

    test('a legacy chat:read without up_to_id is not a contract event', () {
      expect(parseChatEnvelope('chat:read', {'conversationId': 40, 'userId': 45}), isNull);
    });

    test('a legacy chat:message (flat payload) is not a contract event', () {
      expect(
        parseChatEnvelope('chat:message', {
          'conversationId': 40,
          'messageId': 1,
          'senderId': 2,
          'content': 'x',
          'createdAt': '2026-10-22T20:45:00.000Z',
        }),
        isNull,
      );
    });

    test('unknown types and malformed payloads give null instead of throwing', () {
      expect(parseChatEnvelope('match:new', {}), isNull);
      expect(parseChatEnvelope('chat:message', {'message': 'oops'}), isNull);
      expect(parseChatEnvelope('chat:message', {'message': <String, dynamic>{}}), isNull);
    });
  });

  group('WebSocketService keeps feeding the conversation list', () {
    test('a contract chat:message also produces the legacy NewMessageEvent', () async {
      final service = WebSocketService();
      final events = <ChatEvent>[];
      final sub = service.events.listen(events.add);

      service.debugHandleMessage(jsonEncode({
        'type': 'chat:message',
        'payload': {'message': messageJson},
      }));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.whereType<ChatContractEvent>().single.event, isA<ChatMessageArrived>());
      final legacy = events.whereType<NewMessageEvent>().single;
      expect(legacy.conversationId, 40);
      expect(legacy.messageId, 812);
      expect(legacy.senderId, 45);
      expect(legacy.content, 'Salut !');
    });

    test('a photo or voice message gets a readable preview in the list', () async {
      final service = WebSocketService();
      final events = <ChatEvent>[];
      final sub = service.events.listen(events.add);

      for (final type in ['photo', 'voice']) {
        service.debugHandleMessage(jsonEncode({
          'type': 'chat:message',
          'payload': {
            'message': {...messageJson, 'type': type, 'content': ''},
          },
        }));
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.whereType<NewMessageEvent>().map((e) => e.content), ['Photo', 'Message vocal']);
    });

    test('the old flat payloads still work', () async {
      final service = WebSocketService();
      final events = <ChatEvent>[];
      final sub = service.events.listen(events.add);

      service.debugHandleMessage(jsonEncode({
        'type': 'chat:message',
        'payload': {
          'conversationId': 40,
          'messageId': 5,
          'senderId': 2,
          'content': 'ancien',
          'createdAt': '2026-10-22T20:45:00.000Z',
        },
      }));
      service.debugHandleMessage(jsonEncode({
        'type': 'chat:typing',
        'payload': {'conversationId': 40, 'userId': 2, 'isTyping': true},
      }));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.whereType<NewMessageEvent>().single.content, 'ancien');
      expect(events.whereType<TypingEvent>().single.isTyping, isTrue);
      expect(events.whereType<ChatContractEvent>().single.event, isA<ChatTypingChanged>());
    });

    test('snake_case typing and read events reach both consumers', () async {
      final service = WebSocketService();
      final events = <ChatEvent>[];
      final sub = service.events.listen(events.add);

      service.debugHandleMessage(jsonEncode({
        'type': 'chat:typing',
        'payload': {'conversation_id': 40, 'user_id': 45, 'is_typing': true},
      }));
      service.debugHandleMessage(jsonEncode({
        'type': 'chat:read',
        'payload': {'conversation_id': 40, 'user_id': 45, 'up_to_id': 812, 'read_at': '2026-10-22T20:47:00.000Z'},
      }));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.whereType<TypingEvent>().single.conversationId, 40);
      expect(events.whereType<MessagesReadEvent>().single.userId, 45);
      expect(events.whereType<ChatContractEvent>(), hasLength(2));
    });
  });
}
