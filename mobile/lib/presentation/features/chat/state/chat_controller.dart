import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../../../../core/chat/chat_api.dart';
import '../../../../core/models/chat_message.dart';

export '../../../../core/models/chat_message.dart';

/// Why a chat action did not happen. The screen turns it into a sentence in
/// the member's language (`ChatFailureText` in `features/chat/l10n/`).
enum ChatFailure {
  // From the server (see [ChatApiErrorKind]).
  sessionExpired,
  cannotUnsend,
  conversationGone,
  blocked,
  tooLarge,
  rateLimited,
  server,
  fileRejected,
  messageRejected,
  timeout,
  network,
  unknown,
  // Refused by the controller before any call.
  tooManyPhotos,
  notYetSent,
  messageGone,
  notAuthor,
  reactionUnavailable,
  sendUnavailable,
  loadFailed;

  factory ChatFailure.fromApi(ChatApiErrorKind kind) => switch (kind) {
        ChatApiErrorKind.sessionExpired => sessionExpired,
        ChatApiErrorKind.cannotUnsend => cannotUnsend,
        ChatApiErrorKind.conversationGone => conversationGone,
        ChatApiErrorKind.blocked => blocked,
        ChatApiErrorKind.tooLarge => tooLarge,
        ChatApiErrorKind.rateLimited => rateLimited,
        ChatApiErrorKind.server => server,
        ChatApiErrorKind.fileRejected => fileRejected,
        ChatApiErrorKind.messageRejected => messageRejected,
        ChatApiErrorKind.timeout => timeout,
        ChatApiErrorKind.network => network,
        ChatApiErrorKind.unknown => unknown,
      };

  /// Nobody can write in this conversation any more: the composer is closed.
  bool get closesComposer => this == blocked || this == conversationGone;
}

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

  /// Why the first load failed; null otherwise.
  final ChatFailure? error;

  ChatState copyWith({
    int? myUserId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? loadingOlder,
    bool? hasMore,
    bool? otherIsTyping,
    ChatFailure? error,
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
/// on success or the [ChatFailure] to tell the member about.
abstract class ChatActions {
  Future<void> load();
  Future<void> loadOlder();

  Future<ChatFailure?> sendText(String text, {int? replyToId});
  Future<ChatFailure?> sendPhotos(List<Uint8List> jpegs, {String caption = '', int? replyToId});
  Future<ChatFailure?> sendVoice(Uint8List aac, {required int durationMs, required List<int> waveform, int? replyToId});

  /// Retries a message in [MessageStatus.failed].
  Future<ChatFailure?> retry(String clientId);

  /// Drops a failed message without sending it.
  void discard(String clientId);

  Future<ChatFailure?> toggleReaction(int messageId, String emoji);
  Future<ChatFailure?> unsend(int messageId);
  Future<ChatFailure?> report(int messageId, String reason);

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
