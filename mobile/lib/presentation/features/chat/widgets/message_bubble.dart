import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../l10n/chat_preview_text.dart';
import '../logic/chat_items.dart';
import '../state/chat_controller.dart';
import 'bubble_style.dart';
import 'link_preview_card.dart';
import 'photo_grid.dart';
import 'reply_quote.dart';
import '../../../common/l10n/content_direction.dart';
import 'voice_bubble.dart';

/// Everything a bubble needs from the thread around it.
class BubbleContext {
  const BubbleContext({
    required this.authorOf,
    this.onQuoteTap,
    this.onOpenPhoto,
    this.onRevealPhotos,
    this.photosBlurred = false,
    this.heroEnabled = true,
    this.onPlayFailed,
  });

  /// « Vous » or the other member's first name.
  final String Function(int userId) authorOf;
  final void Function(int messageId)? onQuoteTap;
  final void Function(int index)? onOpenPhoto;
  final VoidCallback? onRevealPhotos;
  final bool photosBlurred;
  final VoidCallback? onPlayFailed;

  /// Off in the long-press overlay, which must not take part in hero flights.
  final bool heroEnabled;
}

/// One bubble: text, photos or a voice note, with its quote and link card.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.first,
    required this.last,
    required this.thread,
  });

  /// Key of the coloured box, to measure a bubble in tests.
  static ValueKey<String> boxKey(ChatMessage message) =>
      ValueKey('bubble-${messageKey(message)}');

  final ChatMessage message;
  final bool mine;
  final bool first;
  final bool last;
  final BubbleContext thread;

  @override
  Widget build(BuildContext context) {
    final radius = BubbleStyle.radius(mine: mine, first: first, last: last);
    final maxWidth = BubbleStyle.maxWidth(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = BubbleColors.of(context, mine: mine);

    if (message.unsent) {
      return Container(
        key: boxKey(message),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: BubbleStyle.padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: scheme.outline),
        ),
        child: Text(
          context.l10n.chatRemovedLabel,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            fontStyle: FontStyle.italic,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final photos = message.type == ChatMessageType.photo
        ? PhotoSource.of(message)
        : const <PhotoSource>[];
    final hasPhotos = photos.isNotEmpty;
    final quote = message.replyTo;
    final inset = hasPhotos
        ? const EdgeInsets.symmetric(horizontal: 14)
        : EdgeInsets.zero;
    final children = <Widget>[
      if (quote != null)
        Padding(
          padding: hasPhotos
              ? const EdgeInsets.fromLTRB(8, 8, 8, 2)
              : EdgeInsets.zero,
          child: QuoteBlock(
            author: thread.authorOf(quote.senderId),
            preview: chatPreviewLabel(context.l10n, quote.preview),
            mine: mine,
            onTap: thread.onQuoteTap == null
                ? null
                : () => thread.onQuoteTap!(quote.id),
          ),
        ),
      if (hasPhotos)
        PhotoGrid(
          photos: photos,
          radius: BorderRadius.zero,
          heroPrefix: thread.heroEnabled
              ? 'photo-${messageKey(message)}'
              : null,
          blurred: thread.photosBlurred,
          onReveal: thread.onRevealPhotos,
          onOpen: thread.onOpenPhoto ?? (_) {},
        ),
      if (message.type == ChatMessageType.voice && message.voice != null)
        VoiceBubbleContent(
          voice: message.voice!,
          mine: mine,
          onPlayFailed: thread.onPlayFailed,
        ),
      if (message.content.isNotEmpty)
        Padding(
          padding: inset.add(EdgeInsets.symmetric(vertical: hasPhotos ? 8 : 0)),
          child: Text(
            message.content,
            textDirection: contentDirection(context, message.content),
            style: TextStyle(fontSize: 15, height: 1.4, color: colors.text),
          ),
        ),
      if (message.linkPreview != null)
        Padding(
          padding: inset.add(EdgeInsets.only(bottom: hasPhotos ? 8 : 0)),
          child: LinkPreviewCard(preview: message.linkPreview!, mine: mine),
        ),
    ];

    return Container(
      key: boxKey(message),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: hasPhotos ? EdgeInsets.zero : BubbleStyle.padding,
      clipBehavior: hasPhotos ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(color: colors.background, borderRadius: radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
