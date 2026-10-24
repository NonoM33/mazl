import 'package:flutter/widgets.dart';

import '../../../../l10n/l10n.dart';
import '../state/chat_controller.dart';

/// What every row of the conversation needs to know about the thread, so rows
/// do not take a dozen parameters.
class ChatScope extends InheritedWidget {
  const ChatScope({
    super.key,
    required this.conversationId,
    required this.myUserId,
    required this.otherName,
    required this.otherUserId,
    this.otherPicture,
    required this.onReply,
    required this.scrollToMessage,
    required this.isScamFlagged,
    required this.highlightedMessageId,
    this.overlayBounds,
    required super.child,
  });

  final int conversationId;
  final int myUserId;
  final String otherName;
  final int otherUserId;
  final String? otherPicture;
  final void Function(ChatMessage message) onReply;
  final void Function(int messageId) scrollToMessage;
  final bool Function(ChatMessage message) isScamFlagged;
  final int? highlightedMessageId;

  /// Free band for the long-press overlay, in global coordinates.
  final ({double top, double bottom}) Function()? overlayBounds;

  /// « Vous » or the other member's name.
  String authorOf(AppLocalizations l10n, int userId) =>
      userId == myUserId ? l10n.chatAuthorYou : otherName;

  static ChatScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChatScope>();
    assert(scope != null, 'ChatScope missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(ChatScope old) =>
      old.highlightedMessageId != highlightedMessageId ||
      old.otherName != otherName ||
      old.myUserId != myUserId ||
      old.isScamFlagged != isScamFlagged;
}
