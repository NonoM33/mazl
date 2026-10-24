import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/chat/voice.dart';
import '../../../../core/chat/voice_impl.dart';
import '../../../../l10n/l10n.dart';
import '../chat_providers.dart';
import 'attach_sheet.dart';
import 'chat_feedback.dart';
import 'mic_button.dart';
import 'recording_strip.dart';
import 'reply_quote.dart';
import 'voice_capture.dart';

/// The message being answered, shown in the composer.
class ReplyDraft {
  const ReplyDraft({
    required this.messageId,
    required this.label,
    required this.preview,
  });

  final int messageId;

  /// « Réponse à Noémie », « Réponse à votre message ».
  final String label;
  final String preview;
}

/// Floating capsule (docs/design/CHAT.md §10): « + », a field growing to five
/// lines, and a mic (hold to record) that turns into a send arrow once there
/// is text. Never touches the bottom: 12 px above the safe area or keyboard.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendPhotos,
    required this.onSendVoice,
    required this.onTyping,
    this.reply,
    this.onCancelReply,
    this.focusNode,
    this.disabledMessage,
  });

  static const capsuleKey = ValueKey('chat-composer-capsule');
  static const bottomGap = 12.0;

  final TextEditingController controller;
  final void Function(String text) onSendText;
  final void Function(List<Uint8List> photos) onSendPhotos;
  final void Function(VoiceRecording recording) onSendVoice;

  /// True while there is text in the field.
  final ValueChanged<bool> onTyping;
  final ReplyDraft? reply;
  final VoidCallback? onCancelReply;
  final FocusNode? focusNode;

  /// Replaces the field and buttons when nobody can write here any more.
  final String? disabledMessage;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  VoiceCapture? _capture;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _capture?.dispose();
    super.dispose();
  }

  void _onText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has == _hasText) return;
    setState(() => _hasText = has);
    widget.onTyping(has);
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.controller.clear();
    widget.onSendText(text);
  }

  Future<void> _attach() async {
    final choice = await pickAttachment(context);
    if (choice == null || !mounted) return;
    final picker = ref.read(chatMediaPickerProvider);
    try {
      final photos = choice == AttachChoice.gallery
          ? await picker.fromGallery()
          : await picker.fromCamera();
      if (photos.isNotEmpty) widget.onSendPhotos(photos);
    } on Exception {
      if (mounted) {
        showChatSnack(context, context.l10n.chatComposerPhotoError);
      }
    }
  }

  // --- voice ---------------------------------------------------------------

  VoiceCapture _ensureCapture() => _capture ??= (VoiceCapture(
    ref.read(voiceRecorderProvider),
    onLimit: _sendRecording,
  )..addListener(_redraw));

  void _redraw() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    final capture = _ensureCapture();
    HapticFeedback.mediumImpact();
    final result = await capture.start();
    if (!mounted) return;
    switch (result) {
      case VoiceStartResult.started:
        break;
      case VoiceStartResult.denied:
        showChatSnack(context, context.l10n.chatComposerMicDenied);
      case VoiceStartResult.failed:
        showChatSnack(context, context.l10n.chatComposerRecordError);
    }
  }

  Future<void> _sendRecording() async {
    final recording = await _capture?.finish();
    if (!mounted) return;
    if (recording == null) {
      showChatSnack(context, context.l10n.chatComposerHoldLonger);
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onSendVoice(recording);
  }

  Future<void> _releaseMic(LongPressEndDetails details) async {
    final capture = _capture;
    if (capture == null || !capture.active || capture.locked) return;
    if (capture.willCancel) {
      await capture.cancel();
    } else {
      await _sendRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // Watched so the autoDispose recorder lives as long as the composer.
    ref.watch(voiceRecorderProvider);
    final capture = _capture;
    final recording = capture != null && capture.visible;
    final reply = widget.reply;
    final disabled = widget.disabledMessage;
    if (disabled != null) return _disabled(scheme, safeBottom, disabled);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MessageComposer.bottomGap + safeBottom,
      ),
      child: Container(
        key: MessageComposer.capsuleKey,
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply != null && !recording)
              ReplyComposerBar(
                author: reply.label,
                preview: reply.preview,
                onCancel: widget.onCancelReply ?? () {},
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (recording)
                    Expanded(
                      child: RecordingStrip(
                        capture: capture,
                        onCancel: () => capture.cancel(),
                      ),
                    )
                  else ...[
                    IconButton(
                      tooltip: context.l10n.chatComposerAttach,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      icon: const Icon(LucideIcons.plus, size: 22),
                      onPressed: _attach,
                    ),
                    Expanded(child: _field()),
                  ],
                  const SizedBox(width: 6),
                  _trailing(recording, capture),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabled(ColorScheme scheme, double safeBottom, String message) =>
      Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MessageComposer.bottomGap + safeBottom,
        ),
        child: Container(
          key: MessageComposer.capsuleKey,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  Widget _field() {
    const noBorder = InputBorder.none;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      minLines: 1,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, height: 1.4),
      decoration: InputDecoration(
        hintText: context.l10n.chatComposerHint,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: noBorder,
        enabledBorder: noBorder,
        focusedBorder: noBorder,
        disabledBorder: noBorder,
      ),
    );
  }

  Widget _trailing(bool recording, VoiceCapture? capture) {
    final scheme = Theme.of(context).colorScheme;
    if (recording && capture!.locked) {
      return ComposerRoundButton(
        label: context.l10n.chatComposerSendVoice,
        icon: LucideIcons.arrowUp,
        color: scheme.primary,
        onTap: _sendRecording,
      );
    }
    if (_hasText && !recording) {
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        child: ComposerRoundButton(
          key: const ValueKey('send'),
          label: context.l10n.chatComposerSend,
          icon: LucideIcons.arrowUp,
          color: scheme.primary,
          onTap: _submit,
        ),
      );
    }
    return MicButton(
      key: const ValueKey('mic'),
      recording: recording,
      lockHint: recording && !capture!.locked,
      onStart: _startRecording,
      // The mic sits at the END of the capsule: cancelling means sliding toward
      // the START, which is left in French and right in Hebrew.
      onMove: (offset) => capture?.slide(
        Directionality.of(context) == TextDirection.rtl
            ? Offset(-offset.dx, offset.dy)
            : offset,
      ),
      onEnd: _releaseMic,
      onTap: () => showChatSnack(context, context.l10n.chatComposerHoldHint),
    );
  }
}
