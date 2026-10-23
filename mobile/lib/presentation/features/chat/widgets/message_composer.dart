import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/chat/voice.dart';
import '../chat_providers.dart';
import 'attach_sheet.dart';
import 'chat_feedback.dart';
import 'recording_strip.dart';
import 'reply_quote.dart';
import 'voice_capture.dart';

/// The message being answered, shown in the composer.
class ReplyDraft {
  const ReplyDraft({required this.messageId, required this.label, required this.preview});

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
      final photos = choice == AttachChoice.gallery ? await picker.fromGallery() : await picker.fromCamera();
      if (photos.isNotEmpty) widget.onSendPhotos(photos);
    } on Exception {
      if (mounted) showChatSnack(context, 'Impossible d\'ajouter la photo. Vérifiez les autorisations.');
    }
  }

  // --- voice ---------------------------------------------------------------

  VoiceCapture _ensureCapture() => _capture ??= (VoiceCapture(ref.read(voiceRecorderProvider), onLimit: _sendRecording)..addListener(_redraw));

  void _redraw() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    final capture = _ensureCapture();
    HapticFeedback.mediumImpact();
    if (!await capture.start() && mounted) {
      showChatSnack(context, 'Autorisez le micro dans les réglages pour envoyer un vocal.');
    }
  }

  Future<void> _sendRecording() async {
    final recording = await _capture?.finish();
    if (!mounted) return;
    if (recording == null) {
      showChatSnack(context, 'Maintenez le micro plus longtemps pour enregistrer.');
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
    final capture = _capture;
    final recording = capture != null && capture.recording;
    final reply = widget.reply;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MessageComposer.bottomGap + safeBottom),
      child: Container(
        key: MessageComposer.capsuleKey,
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(30)),
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
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (recording)
                    Expanded(child: RecordingStrip(capture: capture, onCancel: () => capture.cancel()))
                  else ...[
                    IconButton(
                      tooltip: 'Joindre des photos',
                      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
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

  Widget _field() {
    const noBorder = InputBorder.none;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      minLines: 1,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, height: 1.4),
      decoration: const InputDecoration(
        hintText: 'Message',
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      return _RoundButton(label: 'Envoyer le vocal', icon: LucideIcons.arrowUp, color: scheme.primary, onTap: _sendRecording);
    }
    if (_hasText && !recording) {
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
        child: _RoundButton(key: const ValueKey('send'), label: 'Envoyer', icon: LucideIcons.arrowUp, color: scheme.primary, onTap: _submit),
      );
    }
    return _MicButton(
      key: const ValueKey('mic'),
      recording: recording,
      lockHint: recording && !capture!.locked,
      onStart: _startRecording,
      onMove: (offset) => capture?.slide(offset),
      onEnd: _releaseMic,
      onTap: () => showChatSnack(context, 'Maintenez le micro pour enregistrer un vocal.'),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: SizedBox.square(
          dimension: 48,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: Center(child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onPrimary))),
          ),
        ),
      );
}

/// Hold to record; the press is tracked by a long-press recognizer that fires
/// after 200 ms rather than the default 500.
class _MicButton extends StatelessWidget {
  const _MicButton({
    super.key,
    required this.recording,
    required this.lockHint,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onTap,
  });

  final bool recording;
  final bool lockHint;
  final VoidCallback onStart;
  final ValueChanged<Offset> onMove;
  final ValueChanged<LongPressEndDetails> onEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Maintenir pour enregistrer un vocal',
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 200)),
            (r) => r
              ..onLongPressStart = ((_) => onStart())
              ..onLongPressMoveUpdate = ((d) => onMove(d.offsetFromOrigin))
              ..onLongPressEnd = onEnd,
          ),
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r.onTap = onTap,
          ),
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(color: recording ? scheme.primary : Colors.transparent, shape: BoxShape.circle),
                child: Icon(LucideIcons.mic, size: 22, color: recording ? scheme.onPrimary : scheme.onSurface),
              ),
            ),
            if (lockHint)
              Positioned(
                bottom: 56,
                child: Container(
                  width: 36,
                  height: 64,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(18)),
                  child: Icon(LucideIcons.lock, size: 16, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
