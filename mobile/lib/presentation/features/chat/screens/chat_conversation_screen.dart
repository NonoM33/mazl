import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/chat/voice.dart';
import '../../../../core/models/conversation.dart';
import '../logic/chat_errors.dart';
import '../logic/scam_flags.dart';
import '../state/chat_controller_impl.dart';
import '../state/chat_controller.dart';
import '../widgets/chat_feedback.dart';
import '../widgets/chat_header.dart';
import '../widgets/message_composer.dart';
import '../widgets/message_list.dart';

/// The conversation: header, thread, composer. Everything it shows comes from
/// the state of [chatControllerProvider] and everything it does goes through
/// its notifier (CONTRACT §4); it never talks to an API service.
class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    this.otherUser,
    this.onBack,
    this.onOpenProfile,
    this.onVideoCall,
    this.onOptions,
    this.isScamFlagged,
  });

  final int conversationId;

  /// Who the conversation is with; null while it loads.
  final ConversationUser? otherUser;
  final VoidCallback? onBack;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onVideoCall;
  final VoidCallback? onOptions;

  /// Replaces the built-in scam rules (`lib/core/chat/scam_rules.dart`) that
  /// decide which received messages get the warning card; for tests.
  final bool Function(ChatMessage message)? isScamFlagged;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final ChatActions _actions = ref.read(
    chatControllerProvider(widget.conversationId).notifier,
  );
  final _scam = ScamFlagger();
  ReplyDraft? _reply;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _actions.load());
  }

  @override
  void dispose() {
    _actions.setTyping(false);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _otherName =>
      widget.otherUser?.displayName ?? 'Votre correspondant';

  ReplyDraft _draftFor(ChatMessage message, int myUserId) {
    final mine = message.senderId == myUserId;
    final preview = switch (message.type) {
      ChatMessageType.photo =>
        message.content.isEmpty ? 'Photo' : message.content,
      ChatMessageType.voice => 'Message vocal',
      ChatMessageType.text => message.content,
    };
    return ReplyDraft(
      messageId: message.id,
      label: mine ? 'Réponse à votre message' : 'Réponse à $_otherName',
      preview: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
    );
  }

  void _startReply(ChatMessage message) {
    if (message.isLocal || message.unsent) return;
    setState(
      () => _reply = _draftFor(
        message,
        ref.read(chatControllerProvider(widget.conversationId)).myUserId,
      ),
    );
    _focus.requestFocus();
  }

  /// Takes the pending reply: it belongs to the message being sent.
  int? _takeReply() {
    final id = _reply?.messageId;
    if (_reply != null) setState(() => _reply = null);
    return id;
  }

  Future<void> _send(Future<String?> Function(int? replyToId) action) async {
    final error = await action(_takeReply());
    if (!mounted) return;
    if (isBlockedError(error)) {
      setState(() => _blocked = true);
    } else {
      showChatError(context, error);
    }
  }

  void _sendText(String text) {
    _actions.setTyping(false);
    _send((replyTo) => _actions.sendText(text, replyToId: replyTo));
  }

  void _sendPhotos(List<Uint8List> photos) =>
      _send((replyTo) => _actions.sendPhotos(photos, replyToId: replyTo));

  void _sendVoice(VoiceRecording recording) => _send(
    (replyTo) => _actions.sendVoice(
      recording.aac,
      durationMs: recording.duration.inMilliseconds,
      waveform: recording.waveform,
      replyToId: replyTo,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.conversationId));
    final other = widget.otherUser;
    return Scaffold(
      body: Column(
        children: [
          ChatHeader(
            user: other,
            isTyping: state.otherIsTyping,
            onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
            onOpenProfile: other == null ? null : widget.onOpenProfile,
            onVideoCall: widget.onVideoCall ?? () {},
            onOptions: widget.onOptions ?? () {},
          ),
          Expanded(
            child: ChatMessageList(
              conversationId: widget.conversationId,
              state: state,
              otherName: _otherName,
              otherUserId: other?.userId ?? 0,
              otherPicture: other?.picture,
              onReply: _startReply,
              isScamFlagged: widget.isScamFlagged ?? _scam.forState(state),
            ),
          ),
          MessageComposer(
            disabledMessage: _blocked ? blockedConversationMessage : null,
            controller: _text,
            focusNode: _focus,
            reply: _reply,
            onCancelReply: () => setState(() => _reply = null),
            onSendText: _sendText,
            onSendPhotos: _sendPhotos,
            onSendVoice: _sendVoice,
            onTyping: _actions.setTyping,
          ),
        ],
      ),
    );
  }
}
