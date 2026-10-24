import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../chat_providers.dart';
import '../state/chat_controller_impl.dart';
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
import 'reaction_drag.dart';
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
  static const _doubleTapWindow = Duration(milliseconds: 300);

  bool _timeRevealed = false;
  bool _revealedBeforeTap = false;
  int _hearts = 0;
  Offset? _tapPoint;
  bool _reactionsAppeared = false;
  ReactionDragController? _drag;
  Timer? _tapWindow;
  Timer? _photoOpen;

  @override
  void didUpdateWidget(MessageRow old) {
    super.didUpdateWidget(old);
    _reactionsAppeared =
        _hasReactions(widget.item.message) && !_hasReactions(old.item.message);
  }

  static bool _hasReactions(ChatMessage m) =>
      m.reactions.any((r) => r.userIds.isNotEmpty);

  @override
  void dispose() {
    _tapWindow?.cancel();
    _photoOpen?.cancel();
    super.dispose();
  }

  /// Taps are counted here rather than with a double-tap recognizer, which
  /// would hold every tap on a button inside the bubble (play, speed) for
  /// 300 ms. First tap: reveal / hide the time. A second one within the
  /// window: undo that and heart the message.
  void _tap(RowOperations ops) {
    if (_tapWindow?.isActive ?? false) {
      _tapWindow!.cancel();
      setState(() => _timeRevealed = _revealedBeforeTap);
      _doubleTap(ops);
      return;
    }
    _revealedBeforeTap = _timeRevealed;
    setState(() => _timeRevealed = !_timeRevealed);
    _tapWindow = Timer(_doubleTapWindow, () {});
  }

  void _doubleTap(RowOperations ops) {
    if (ops.heart()) setState(() => _hearts++);
  }

  /// A tap on a photo opens the viewer, unless a second tap follows at once:
  /// that one is a heart, as on any other bubble.
  void _photoTap(RowOperations ops, int index) {
    if (_photoOpen?.isActive ?? false) {
      _photoOpen!.cancel();
      _doubleTap(ops);
      return;
    }
    _photoOpen = Timer(_doubleTapWindow, () {
      if (!mounted) return;
      openPhotoViewer(
        context,
        photos: PhotoSource.of(message),
        initialIndex: index,
        heroPrefix: 'photo-${messageKey(message)}',
      );
    });
  }

  static const _avatarSlot = 36.0;

  MessageItem get item => widget.item;
  ChatMessage get message => item.message;

  BubbleContext _thread(
    ChatScope scope,
    RowOperations ops, {
    required bool overlay,
  }) {
    final revealed = ref.watch(revealedPhotosProvider).contains(message.id);
    return BubbleContext(
      authorOf: (userId) => scope.authorOf(context.l10n, userId),
      onQuoteTap: overlay ? null : scope.scrollToMessage,
      heroEnabled: !overlay,
      onPlayFailed: () => ref
          .read(chatControllerProvider(scope.conversationId).notifier)
          .load(),
      photosBlurred:
          !item.mine &&
          !message.isLocal &&
          !revealed &&
          message.type == ChatMessageType.photo,
      onRevealPhotos: () => ref
          .read(revealedPhotosProvider.notifier)
          .update((s) => {...s, message.id}),
      onOpenPhoto: (index) => _photoTap(ops, index),
    );
  }

  MessageBubble _bubble(
    ChatScope scope,
    RowOperations ops, {
    bool overlay = false,
  }) => MessageBubble(
    message: message,
    mine: item.mine,
    first: item.first,
    last: item.last,
    thread: _thread(scope, ops, overlay: overlay),
  );

  void _longPress(RowOperations ops, ChatScope scope) {
    _drag = null;
    if (!ops.canMenu) return;
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final bounds = scope.overlayBounds?.call();
    // The finger stays down: it slides onto the reaction bar from here.
    final drag = _drag = ReactionDragController();
    showMessageActions(
      context,
      bubbleRect: box.localToGlobal(Offset.zero) & box.size,
      bubble: _bubble(scope, ops, overlay: true),
      mine: item.mine,
      myReactions: ops.myReactions,
      onReact: ops.react,
      actions: ops.menu(),
      showReactionBar: !ops.failed,
      minTop: bounds?.top,
      maxBottom: bounds?.bottom,
      drag: drag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final ops = RowOperations(context, ref, scope, item);
    final scheme = Theme.of(context).colorScheme;
    final highlighted = scope.highlightedMessageId == message.id;
    final noMotion = MediaQuery.disableAnimationsOf(context);

    Widget bubble = KeyedSubtree(key: _bubbleKey, child: _bubble(scope, ops));
    if (message.status == MessageStatus.sending) {
      bubble = Opacity(opacity: 0.6, child: bubble);
    }

    final gestures = Listener(
      // The tap point, whichever recognizer wins the tap (a photo inside).
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _tapPoint = e.localPosition,
      child: GestureDetector(
        onTap: () => _tap(ops),
        onLongPressStart: (_) => _longPress(ops, scope),
        onLongPressMoveUpdate: (d) => _drag?.move(d.globalPosition),
        onLongPressEnd: (d) => _drag?.release(d.globalPosition),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            Positioned.fill(
              child: HeartPop(trigger: _hearts, origin: _tapPoint),
            ),
          ],
        ),
      ),
    );

    final hasReactions = message.reactions.any((r) => r.userIds.isNotEmpty);
    // The pill bites 8 px into the bubble's bottom edge, on the side opposite
    // the tail; the padding below keeps it inside the Stack so the whole pill
    // can be tapped.
    final bubbleWithPill = Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: hasReactions
                ? ReactionPill.height + 4 - ReactionPill.bite
                : 0,
          ),
          child: gestures,
        ),
        if (hasReactions)
          PositionedDirectional(
            bottom: 0,
            start: item.mine ? 12 : null,
            end: item.mine ? null : 12,
            child: ReactionPill(
              reactions: message.reactions,
              myUserId: scope.myUserId,
              popOnAppear: _reactionsAppeared,
              onTap: () => showReactionsSheet(
                context,
                reactions: message.reactions,
                scope: scope,
              ),
            ),
          ),
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: item.mine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!item.mine) _avatar(scope),
            Flexible(child: bubbleWithPill),
          ],
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: item.mine ? 0 : _avatarSlot,
          ),
          child: Align(
            alignment: item.mine
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: AnimatedSize(
              duration: noMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
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
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
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
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: SizedBox.square(
      dimension: 28,
      child: item.last
          ? ProfilePhoto(
              url: scope.otherPicture,
              seed: scope.otherUserId,
              radius: 14,
              iconSize: 14,
            )
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
          child: Text(
            context.l10n.chatFailedRetry,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),
      );
    }
    final l10n = context.l10n;
    final seenAt = item.seenAt;
    final text = seenAt != null
        ? l10n.chatSeenAt(clock(l10n, seenAt))
        : (item.last || _timeRevealed) && !message.isLocal
        ? clock(l10n, message.createdAt)
        : null;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
