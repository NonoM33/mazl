import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../../../../core/models/chat_message.dart';

export '../../../../core/models/chat_message.dart';

/// What the conversation screen renders. CONTRACT: docs/chat/CONTRAT.md §4.
@immutable
class ChatState {
  const ChatState({
    required this.conversationId,
    required this.myUserId,
    this.messages = const [],
    this.loading = true,
    this.loadingOlder = false,
    this.hasMore = true,
    this.otherIsTyping = false,
    this.error,
  });

  final int conversationId;
  final int myUserId;

  /// Oldest first. Includes optimistic messages (negative ids).
  final List<ChatMessage> messages;
  final bool loading;
  final bool loadingOlder;
  final bool hasMore;
  final bool otherIsTyping;

  /// A French message when the first load failed; null otherwise.
  final String? error;

  ChatState copyWith({
    int? myUserId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? loadingOlder,
    bool? hasMore,
    bool? otherIsTyping,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        conversationId: conversationId,
        myUserId: myUserId ?? this.myUserId,
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        loadingOlder: loadingOlder ?? this.loadingOlder,
        hasMore: hasMore ?? this.hasMore,
        otherIsTyping: otherIsTyping ?? this.otherIsTyping,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Everything the screen can ask for. Implemented by the real controller
/// (HTTP + WebSocket) and by fakes in widget tests. Every action returns null
/// on success or a short French message to show.
abstract class ChatActions {
  Future<void> load();
  Future<void> loadOlder();

  Future<String?> sendText(String text, {int? replyToId});
  Future<String?> sendPhotos(List<Uint8List> jpegs, {String caption = '', int? replyToId});
  Future<String?> sendVoice(Uint8List aac, {required int durationMs, required List<int> waveform, int? replyToId});

  /// Retries a message in [MessageStatus.failed].
  Future<String?> retry(String clientId);

  /// Drops a failed message without sending it.
  void discard(String clientId);

  Future<String?> toggleReaction(int messageId, String emoji);
  Future<String?> unsend(int messageId);
  Future<String?> report(int messageId, String reason);

  /// Called while the composer changes; debounced by the implementation.
  void setTyping(bool typing);

  /// The screen shows messages up to [messageId]: mark them read.
  void markReadUpTo(int messageId);
}

/// What `chatControllerProvider(conversationId)` exposes: the state to render
/// and the actions to call. Widget tests override the provider with a fake that
/// extends this class.
abstract class ChatNotifier extends StateNotifier<ChatState> implements ChatActions {
  ChatNotifier(super.state);
}
