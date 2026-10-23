import 'dart:async';
import 'dart:typed_data';

import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/chat/chat_realtime.dart';
import 'package:mazl/core/models/chat_message.dart';

// JSON shapes follow docs/chat/CONTRAT.md §1.
Map<String, dynamic> messageJson({
  required int id,
  int conversationId = 40,
  int senderId = 45,
  String? clientId,
  String type = 'text',
  String content = 'Salut',
  List<Map<String, dynamic>> media = const [],
  Map<String, dynamic>? voice,
  Map<String, dynamic>? replyTo,
  List<Map<String, dynamic>> reactions = const [],
  Map<String, dynamic>? linkPreview,
  String createdAt = '2026-10-22T20:00:00.000Z',
  String? readAt,
  bool unsent = false,
}) =>
    {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'client_id': clientId,
      'type': type,
      'content': content,
      'media': media,
      'voice': voice,
      'reply_to': replyTo,
      'reactions': reactions,
      'link_preview': linkPreview,
      'created_at': createdAt,
      'read_at': readAt,
      'unsent': unsent,
    };

ChatMessage serverMessage({
  required int id,
  int senderId = 45,
  String? clientId,
  String content = 'Salut',
  String type = 'text',
  String createdAt = '2026-10-22T20:00:00.000Z',
  String? readAt,
  List<Map<String, dynamic>> reactions = const [],
  Map<String, dynamic>? linkPreview,
  bool unsent = false,
}) =>
    ChatMessage.fromJson(messageJson(
      id: id,
      senderId: senderId,
      clientId: clientId,
      content: content,
      type: type,
      createdAt: createdAt,
      readAt: readAt,
      reactions: reactions,
      linkPreview: linkPreview,
      unsent: unsent,
    ));

class SendCall {
  SendCall(this.clientId, this.type, this.content, this.mediaIds, this.replyToId);
  final String clientId;
  final ChatMessageType type;
  final String content;
  final List<int> mediaIds;
  final int? replyToId;
}

class UploadCall {
  UploadCall(this.bytes, this.kind, this.durationMs, this.waveform);
  final Uint8List bytes;
  final MediaKind kind;
  final int? durationMs;
  final List<int>? waveform;
}

/// Programmable [ChatApi]. Every handler can be replaced per test; the
/// defaults behave like a healthy server.
class FakeChatApi implements ChatApi {
  FakeChatApi({this.myUserId = 7});

  final int myUserId;
  int _nextId = 1000;
  int _nextMediaId = 500;
  DateTime Function() serverNow = () => DateTime.utc(2026, 10, 22, 21);

  final getCalls = <({int? before, int limit})>[];
  final sendCalls = <SendCall>[];
  final uploadCalls = <UploadCall>[];
  final reactionCalls = <({int messageId, String emoji})>[];
  final unsendCalls = <int>[];
  final readCalls = <int>[];
  final reportCalls = <({int messageId, String reason})>[];

  Future<MessagePage> Function(int? before, int limit) onGet =
      (before, limit) async => const MessagePage(messages: [], hasMore: false);

  Future<ChatMessage> Function(SendCall call)? onSend;
  Future<ChatMedia> Function(UploadCall call)? onUpload;
  Future<List<Reaction>> Function(int messageId, String emoji)? onReaction;
  Future<ChatMessage?> Function(int messageId)? onUnsend;
  Future<void> Function(int upToId)? onRead;
  Future<void> Function(int messageId, String reason)? onReport;

  @override
  Future<MessagePage> getMessages(int conversationId, {int? before, int limit = 30}) {
    getCalls.add((before: before, limit: limit));
    return onGet(before, limit);
  }

  @override
  Future<ChatMedia> uploadMedia(
    int conversationId, {
    required Uint8List bytes,
    required MediaKind kind,
    int? durationMs,
    List<int>? waveform,
  }) {
    final call = UploadCall(bytes, kind, durationMs, waveform);
    uploadCalls.add(call);
    final handler = onUpload;
    if (handler != null) return handler(call);
    final id = _nextMediaId++;
    return Future.value(ChatMedia(id: id, url: 'https://cdn.example.com/$id'));
  }

  @override
  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String clientId,
    required ChatMessageType type,
    String content = '',
    List<int> mediaIds = const [],
    int? replyToId,
  }) {
    final call = SendCall(clientId, type, content, mediaIds, replyToId);
    sendCalls.add(call);
    final handler = onSend;
    if (handler != null) return handler(call);
    return Future.value(echo(call));
  }

  /// What a healthy server answers for [call]. Same id for the same client_id.
  ChatMessage echo(SendCall call) {
    final known = _ids.putIfAbsent(call.clientId, () => _nextId++);
    return ChatMessage.fromJson(messageJson(
      id: known,
      conversationId: 40,
      senderId: myUserId,
      clientId: call.clientId,
      type: call.type.name,
      content: call.content,
      media: [
        for (final id in call.mediaIds)
          if (call.type == ChatMessageType.photo) {'id': id, 'kind': 'photo', 'url': 'https://cdn.example.com/$id'},
      ],
      voice: call.type == ChatMessageType.voice
          ? {'id': call.mediaIds.first, 'url': 'https://cdn.example.com/v', 'duration_ms': 3000, 'waveform': <int>[]}
          : null,
      createdAt: serverNow().toIso8601String(),
    ));
  }

  final _ids = <String, int>{};

  @override
  Future<List<Reaction>> toggleReaction(int messageId, String emoji) {
    reactionCalls.add((messageId: messageId, emoji: emoji));
    final handler = onReaction;
    if (handler != null) return handler(messageId, emoji);
    return Future.value([Reaction(emoji: emoji, userIds: [myUserId])]);
  }

  @override
  Future<ChatMessage?> unsend(int messageId) {
    unsendCalls.add(messageId);
    final handler = onUnsend;
    if (handler != null) return handler(messageId);
    return Future.value();
  }

  @override
  Future<void> markRead(int conversationId, {required int upToId}) {
    readCalls.add(upToId);
    final handler = onRead;
    if (handler != null) return handler(upToId);
    return Future.value();
  }

  @override
  Future<void> report(int messageId, String reason) {
    reportCalls.add((messageId: messageId, reason: reason));
    final handler = onReport;
    if (handler != null) return handler(messageId, reason);
    return Future.value();
  }
}

class FakeChatRealtime implements ChatRealtimeSource {
  final _controller = StreamController<ChatRealtimeEvent>.broadcast(sync: true);
  final typingSent = <bool>[];

  @override
  Stream<ChatRealtimeEvent> events(int conversationId) => _controller.stream;

  @override
  void sendTyping(int conversationId, bool typing) => typingSent.add(typing);

  void emit(ChatRealtimeEvent event) => _controller.add(event);

  bool get hasListeners => _controller.hasListener;

  Future<void> close() => _controller.close();
}
