import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../chat_providers.dart';
import '../logic/chat_dates.dart';
import '../logic/chat_items.dart';
import '../state/chat_controller.dart';
import 'appear_animation.dart';
import 'bubble_style.dart';
import 'chat_scope.dart';
import 'heart_pop.dart';
import 'message_actions_overlay.dart';
import 'message_bubble.dart';
import 'message_row_operations.dart';
import 'photo_grid.dart';
import 'photo_viewer.dart';
import 'reaction_pill.dart';
import 'report_sheet.dart';
import 'scam_warning_card.dart';
import 'swipe_to_reply.dart';

/// A message in the thread: avatar, bubble, reactions, time / « Vu » line,
/// and every gesture on them (docs/design/CHAT.md §2-§6).
class MessageRow extends ConsumerStatefulWidget {
  const MessageRow({super.key, required this.item, this.appear = false});

  final MessageItem item;

  /// Slides in (a message that arrived while the screen was open).
  final bool appear;

  @override
  ConsumerState<MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends ConsumerState<MessageRow> {
  final _bubbleKey = GlobalKey();
  bool _timeRevealed = false;
  int _hearts = 0;

  static const _avatarSlot = 36.0;

  MessageItem get item => widget.item;
  ChatMessage get message => item.message;

  BubbleContext _thread(ChatScope scope, {required bool overlay}) {
    final revealed = ref.watch(revealedPhotosProvider).contains(message.id);
    return BubbleContext(
      authorOf: scope.authorOf,
      onQuoteTap: overlay ? null : scope.scrollToMessage,
      heroEnabled: !overlay,
      photosBlurred: !item.mine && !message.isLocal && !revealed && message.type == ChatMessageType.photo,
      onRevealPhotos: () => ref.read(revealedPhotosProvider.notifier).update((s) => {...s, message.id}),
      onOpenPhoto: (index) => openPhotoViewer(
        context,
        photos: PhotoSource.of(message),
        initialIndex: index,
        heroPrefix: 'photo-${messageKey(message)}',
      ),
    );
  }

  MessageBubble _bubble(ChatScope scope, {bool overlay = false}) => MessageBubble(
        message: message,
        mine: item.mine,
        first: item.first,
        last: item.last,
        thread: _thread(scope, overlay: overlay),
      );

  void _longPress(RowOperations ops, ChatScope scope) {
    if (!ops.canMenu) return;
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    showMessageActions(
      context,
      bubbleRect: box.localToGlobal(Offset.zero) & box.size,
      bubble: _bubble(scope, overlay: true),
      mine: item.mine,
      myReactions: ops.myReactions,
      onReact: ops.react,
      actions: ops.menu(),
      showReactionBar: !ops.failed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final ops = RowOperations(context, ref, scope, item);
    final scheme = Theme.of(context).colorScheme;
    final highlighted = scope.highlightedMessageId == message.id;
    final noMotion = MediaQuery.disableAnimationsOf(context);

    Widget bubble = KeyedSubtree(key: _bubbleKey, child: _bubble(scope));
    if (message.status == MessageStatus.sending) bubble = Opacity(opacity: 0.6, child: bubble);

    final gestures = GestureDetector(
      onTap: () => setState(() => _timeRevealed = !_timeRevealed),
      onDoubleTap: () {
        if (ops.heart()) setState(() => _hearts++);
      },
      onLongPress: () => _longPress(ops, scope),
      child: Stack(clipBehavior: Clip.none, children: [bubble, Positioned.fill(child: HeartPop(trigger: _hearts))]),
    );

    final hasReactions = message.reactions.any((r) => r.userIds.isNotEmpty);
    // The pill bites 8 px into the bubble's bottom edge, on the side opposite
    // the tail; the padding below keeps it inside the Stack so the whole pill
    // can be tapped.
    final bubbleWithPill = Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: EdgeInsets.only(bottom: hasReactions ? ReactionPill.height + 4 - ReactionPill.bite : 0), child: gestures),
        if (hasReactions)
          Positioned(
            bottom: 0,
            left: item.mine ? 12 : null,
            right: item.mine ? null : 12,
            child: ReactionPill(
              reactions: message.reactions,
              myUserId: scope.myUserId,
              onTap: () => showReactionsSheet(context, reactions: message.reactions, scope: scope),
            ),
          ),
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: item.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!item.mine) _avatar(scope),
            Flexible(child: bubbleWithPill),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: item.mine ? 0 : _avatarSlot),
          child: Align(
            alignment: item.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedSize(
              duration: noMotion ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _meta(ops, scheme),
            ),
          ),
        ),
      ],
    );

    return AnimatedContainer(
      duration: noMotion ? Duration.zero : const Duration(milliseconds: 250),
      color: highlighted ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
      padding: EdgeInsets.only(top: BubbleStyle.gapAbove(first: item.first)),
      child: AppearAnimation(
        enabled: widget.appear,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SwipeToReply(
                enabled: !message.isLocal && !message.unsent,
                onReply: () => scope.onReply(message),
                child: column,
              ),
            ),
            if (!item.mine)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScamWarningCard(
                  show: scope.isScamFlagged(message),
                  onReport: ops.report,
                  onLearnMore: () => showScamAdviceSheet(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(ChatScope scope) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox.square(
          dimension: 28,
          child: item.last
              ? ProfilePhoto(url: scope.otherPicture, seed: scope.otherUserId, radius: 14, iconSize: 14)
              : null,
        ),
      );

  /// Time under the last bubble of a group, or « Vu à… », or the failure line.
  Widget _meta(RowOperations ops, ColorScheme scheme) {
    if (message.status == MessageStatus.failed) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: GestureDetector(
          onTap: ops.failedMenu,
          behavior: HitTestBehavior.opaque,
          child: const Text('Échec · Réessayer', style: TextStyle(fontSize: 12, color: AppColors.error)),
        ),
      );
    }
    final seenAt = item.seenAt;
    final text = seenAt != null
        ? 'Vu à ${clock(seenAt)}'
        : (item.last || _timeRevealed) && !message.isLocal
            ? clock(message.createdAt)
            : null;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
    );
  }
}
