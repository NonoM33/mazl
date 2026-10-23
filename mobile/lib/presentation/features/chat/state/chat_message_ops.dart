import '../../../../core/models/chat_message.dart';

// Pure list operations of the chat controller: merging server and local
// messages, ordering, reactions. No I/O, no timers.

const quotedPreviewLength = 80;

/// Inserts [incoming] or replaces the message it stands for: the optimistic
/// copy with the same `client_id`, else the one with the same server id. Safe
/// to call any number of times with the same message (WebSocket echo and HTTP
/// answer both land here).
List<ChatMessage> upsertMessage(List<ChatMessage> messages, ChatMessage incoming) {
  final index = _indexOf(messages, incoming);
  final next = [...messages];
  if (index >= 0) {
    next[index] = _keepRead(next[index], incoming);
  } else {
    next.add(incoming);
  }
  return sortMessages(next);
}

/// Replaces the message [incoming] stands for; does nothing if it is unknown.
List<ChatMessage> replaceMessage(List<ChatMessage> messages, ChatMessage incoming) {
  final index = _indexOf(messages, incoming);
  if (index < 0) return messages;
  final next = [...messages];
  next[index] = _keepRead(next[index], incoming);
  return next;
}

int _indexOf(List<ChatMessage> messages, ChatMessage incoming) {
  final clientId = incoming.clientId;
  if (clientId != null) {
    final byClient = messages.indexWhere((m) => m.clientId == clientId);
    if (byClient >= 0) return byClient;
  }
  return incoming.id > 0 ? messages.indexWhere((m) => m.id == incoming.id) : -1;
}

/// A late or partial copy must not make a message "unread" again.
ChatMessage _keepRead(ChatMessage existing, ChatMessage incoming) {
  if (incoming.readAt == null && existing.readAt != null) {
    return incoming.copyWith(readAt: existing.readAt, status: MessageStatus.seen);
  }
  return incoming;
}

/// Oldest first; pending local messages after server ones sent at the same
/// instant, the most recent local one last.
List<ChatMessage> sortMessages(List<ChatMessage> messages) {
  final sorted = [...messages];
  sorted.sort((a, b) {
    final byTime = a.createdAt.compareTo(b.createdAt);
    if (byTime != 0) return byTime;
    if (a.isLocal != b.isLocal) return a.isLocal ? 1 : -1;
    return a.isLocal ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
  });
  return sorted;
}

/// My reaction toggled the way the server does it: one per member and per
/// message, the same emoji twice removes it.
List<Reaction> toggleMyReaction(List<Reaction> reactions, String emoji, int me) {
  final hadSame = reactions.any((r) => r.emoji == emoji && r.userIds.contains(me));
  final result = <Reaction>[];
  var placed = false;
  for (final r in reactions) {
    var ids = r.userIds.where((id) => id != me).toList();
    if (r.emoji == emoji) {
      placed = true;
      if (!hadSame) ids = [...ids, me];
    }
    if (ids.isNotEmpty) result.add(Reaction(emoji: r.emoji, userIds: ids));
  }
  if (!placed && !hadSame) result.add(Reaction(emoji: emoji, userIds: [me]));
  return result;
}

/// Marks my messages up to [upToId] as seen at [readAt].
List<ChatMessage> markSeenUpTo(List<ChatMessage> messages, {required int me, required int upToId, required DateTime readAt}) => [
      for (final m in messages)
        if (m.senderId == me && m.id > 0 && m.id <= upToId && m.status != MessageStatus.seen)
          m.copyWith(readAt: readAt, status: MessageStatus.seen)
        else
          m,
    ];

/// What a quoted message shows (CONTRAT §1 `reply_to.preview`).
ReplyRef replyRefFor(ChatMessage original) {
  final String preview;
  if (original.unsent) {
    preview = 'Message retiré';
  } else {
    preview = switch (original.type) {
      ChatMessageType.photo => 'Photo',
      ChatMessageType.voice => 'Message vocal',
      ChatMessageType.text => original.content.length > quotedPreviewLength
          ? original.content.substring(0, quotedPreviewLength)
          : original.content,
    };
  }
  return ReplyRef(id: original.id, senderId: original.senderId, type: original.type, preview: preview);
}
