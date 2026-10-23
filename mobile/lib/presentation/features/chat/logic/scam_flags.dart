import '../../../../core/chat/scam_rules.dart';
import '../state/chat_controller.dart';

/// Decides which RECEIVED messages get the scam warning card, with
/// `detectScam` (local, nothing leaves the phone). Remembers verdicts: a
/// message is judged once, not on every rebuild of a long thread.
class ScamFlagger {
  final _verdicts = <(int, bool), bool>{};

  /// A predicate for [state]. "Early" (the off-platform rule) only applies
  /// when the whole history is loaded and the message is among its first ones;
  /// while older pages exist its true rank is unknown, so it counts as late.
  bool Function(ChatMessage) forState(ChatState state) {
    final early = state.hasMore
        ? const <int>{}
        : {for (final m in state.messages.take(scamEarlyMessageCount)) m.id};
    return (message) {
      if (message.senderId == state.myUserId ||
          message.unsent ||
          message.type != ChatMessageType.text ||
          message.content.isEmpty) {
        return false;
      }
      final isEarly = early.contains(message.id);
      return _verdicts.putIfAbsent(
        (message.id, isEarly),
        () =>
            detectScam(
              message.content,
              position: isEarly ? 0 : scamEarlyMessageCount,
            ) !=
            null,
      );
    };
  }
}
