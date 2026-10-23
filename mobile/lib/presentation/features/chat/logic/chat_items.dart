import '../state/chat_controller.dart';
import 'chat_dates.dart';

/// Two messages belong to one visual group when they share a sender, a day
/// and are less than this apart (docs/design/CHAT.md §2).
const groupGap = Duration(minutes: 3);

/// A message may be taken back by its author for this long (contract §2).
const unsendWindow = Duration(minutes: 15);

/// Stable identity of a message across its optimistic and server versions.
String messageKey(ChatMessage message) => message.clientId ?? 'id-${message.id}';

bool sameGroup(ChatMessage a, ChatMessage b) =>
    a.senderId == b.senderId && sameDay(a.createdAt, b.createdAt) && b.createdAt.difference(a.createdAt).abs() < groupGap;

/// What the list draws, oldest first. The list view reverses it.
sealed class ChatItem {
  const ChatItem();
  String get key;
}

/// Spinner at the very top while older messages load.
class LoadingOlderItem extends ChatItem {
  const LoadingOlderItem();
  @override
  String get key => 'loading-older';
}

/// « MATCH · 21 OCT. » above the first message of the conversation.
class StartItem extends ChatItem {
  const StartItem(this.day);
  final DateTime day;
  @override
  String get key => 'day-${day.millisecondsSinceEpoch}';
}

class DateItem extends ChatItem {
  const DateItem(this.day);
  final DateTime day;
  @override
  String get key => 'day-${day.millisecondsSinceEpoch}';
}

class MessageItem extends ChatItem {
  const MessageItem({
    required this.message,
    required this.mine,
    required this.first,
    required this.last,
    required this.seenAt,
  });

  final ChatMessage message;
  final bool mine;

  /// First / last bubble of its group (a lone bubble is both).
  final bool first;
  final bool last;

  /// Set on the last sent message the other member has read: « Vu à 20:47 ».
  final DateTime? seenAt;

  @override
  String get key => messageKey(message);
}

class TypingItem extends ChatItem {
  const TypingItem();
  @override
  String get key => 'typing';
}

/// Builds the rows of the conversation from its state, oldest first.
List<ChatItem> buildChatItems(ChatState state) {
  final messages = state.messages;
  final items = <ChatItem>[];
  if (state.loadingOlder) items.add(const LoadingOlderItem());

  final lastSeen = _lastSeenIndex(messages, state.myUserId);
  final showStart = !state.hasMore && messages.isNotEmpty;
  for (var i = 0; i < messages.length; i++) {
    final message = messages[i];
    final previous = i > 0 ? messages[i - 1] : null;
    final next = i + 1 < messages.length ? messages[i + 1] : null;
    if (previous == null || !sameDay(previous.createdAt, message.createdAt)) {
      final day = dayOf(message.createdAt);
      items.add(previous == null && showStart ? StartItem(day) : DateItem(day));
    }
    items.add(
      MessageItem(
        message: message,
        mine: message.senderId == state.myUserId,
        first: previous == null || !sameGroup(previous, message),
        last: next == null || !sameGroup(message, next),
        seenAt: i == lastSeen ? (message.readAt ?? message.createdAt) : null,
      ),
    );
  }
  if (state.otherIsTyping) items.add(const TypingItem());
  return items;
}

int _lastSeenIndex(List<ChatMessage> messages, int myUserId) {
  for (var i = messages.length - 1; i >= 0; i--) {
    final m = messages[i];
    if (m.senderId == myUserId && !m.isLocal && (m.status == MessageStatus.seen || m.readAt != null)) return i;
  }
  return -1;
}

/// The day a row belongs to, for the sticky date label.
DateTime? dayOfItem(ChatItem item) => switch (item) {
      MessageItem(:final message) => dayOf(message.createdAt),
      DateItem(:final day) => day,
      StartItem(:final day) => day,
      _ => null,
    };
