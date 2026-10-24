import 'dart:async';

import '../chat/chat_api.dart';
import '../chat/chat_realtime.dart';
import '../models/chat_message.dart';
import 'demo_store.dart';

/// Real-time input of the demo, which has no WebSocket: while a conversation
/// is listened to, page 1 of its messages is fetched every [interval] through
/// the same [ChatApi] and compared with what was already emitted. Polling
/// stops when nobody listens.
class DemoChatRealtimeSource implements ChatRealtimeSource {
  DemoChatRealtimeSource({
    required this.api,
    required this.myUserId,
    this.interval = const Duration(seconds: 1),
    bool Function(int conversationId)? isTyping,
  }) : _isTyping = isTyping ?? ((id) => DemoStore.chat.isTyping(id, DemoStore.clock()));

  final ChatApi api;
  final int Function() myUserId;
  final Duration interval;
  final bool Function(int conversationId) _isTyping;

  @override
  Stream<ChatRealtimeEvent> events(int conversationId) {
    Timer? timer;
    var polling = false;
    var typing = false;
    final seen = <int, _Seen>{};
    late final StreamController<ChatRealtimeEvent> controller;

    Future<void> poll() async {
      if (polling) return;
      polling = true;
      try {
        final page = await api.getMessages(conversationId);
        if (controller.isClosed || !controller.hasListener) return;
        _diff(controller, seen, page.messages.reversed.toList(), conversationId);
        final nowTyping = _isTyping(conversationId);
        if (nowTyping != typing) {
          typing = nowTyping;
          controller.add(ChatTypingChanged(
            conversationId: conversationId,
            userId: _otherId(page.messages),
            isTyping: nowTyping,
          ));
        }
      } on ChatApiException {
        // The next tick tries again.
      } finally {
        polling = false;
      }
    }

    controller = StreamController<ChatRealtimeEvent>(
      onListen: () {
        unawaited(poll());
        timer = Timer.periodic(interval, (_) => unawaited(poll()));
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  /// Oldest first. A message never seen is emitted as it is; a known one is
  /// emitted as a read receipt when only [ChatMessage.readAt] changed, as an
  /// update when anything else did.
  void _diff(
    StreamController<ChatRealtimeEvent> out,
    Map<int, _Seen> seen,
    List<ChatMessage> oldestFirst,
    int conversationId,
  ) {
    final me = myUserId();
    int? readUpTo;
    DateTime? readAt;
    final other = _otherId(oldestFirst);
    for (final m in oldestFirst) {
      final before = seen[m.id];
      final now = _Seen.of(m);
      seen[m.id] = now;
      if (before == null) {
        out.add(ChatMessageArrived(m));
      } else if (before.sameExceptRead(now)) {
        if (before.readAt == null && now.readAt != null && m.senderId == me) {
          if (readUpTo == null || m.id > readUpTo) readUpTo = m.id;
          readAt = m.readAt;
        }
      } else {
        out.add(ChatMessageUpdated(m));
      }
    }
    if (readUpTo != null && readAt != null) {
      out.add(ChatReadUpTo(conversationId: conversationId, userId: other, upToId: readUpTo, readAt: readAt));
    }
  }

  /// The other member of the conversation: whoever sent a message that is not
  /// mine (the demo conversations have two members).
  int _otherId(List<ChatMessage> messages) {
    final me = myUserId();
    for (final m in messages) {
      if (m.senderId != me) return m.senderId;
    }
    return me + 1;
  }

  @override
  void sendTyping(int conversationId, bool typing) {}
}

class _Seen {
  const _Seen(this.readAt, this.rest);

  factory _Seen.of(ChatMessage m) => _Seen(
        m.readAt,
        [
          m.unsent,
          m.content,
          m.linkPreview?.url,
          m.linkPreview?.title,
          [for (final r in m.reactions) '${r.emoji}:${r.userIds.join(",")}'].join('|'),
        ].join('\u0000'),
      );

  final DateTime? readAt;
  final String rest;

  bool sameExceptRead(_Seen other) => rest == other.rest;
}
