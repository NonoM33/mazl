import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/chat_message.dart';
import '../../../../core/theme/app_colors.dart';
import 'reaction_drag.dart';

/// The capsule of the six reactions that floats above a lifted bubble
/// (docs/design/CHAT.md §5): 44 px high, six 40 px slots 2 px apart, 28 px
/// emojis. It grows from the bubble's corner and its emojis pop in turn. A
/// finger still down from the long press ([drag]) slides over it: the emoji
/// under it rises, and lifting there picks it.
class ReactionBar extends StatefulWidget {
  const ReactionBar({
    super.key,
    required this.selected,
    required this.onPick,
    required this.mine,
    this.drag,
  });

  static const height = 44.0;
  static const slot = 40.0;
  static const gap = 2.0;
  static const padding = 6.0;
  static const border = 1.0;
  static const emojiSize = 28.0;

  /// Outer width, border included.
  static double get width =>
      allowedReactions.length * slot +
      (allowedReactions.length - 1) * gap +
      2 * padding +
      2 * border;

  /// The reactions I already left on the message.
  final Set<String> selected;

  /// An emoji was chosen, by tap or by lifting the finger on it.
  final ValueChanged<String> onPick;

  /// My bubble: the bar grows from its right corner, else from the left one.
  final bool mine;

  final ReactionDragController? drag;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 320);
  static const _growMs = 260;
  static const _stagger = 20;
  static const _popMs = 200;
  static const _hoverReach = 24.0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final Animation<double> _grow = Tween<double>(begin: 0.7, end: 1)
      .animate(
        CurvedAnimation(
          parent: _entrance,
          curve: Interval(
            0,
            _growMs / _total.inMilliseconds,
            curve: Curves.easeOutBack,
          ),
        ),
      );
  late final List<Animation<double>> _pops = [
    for (var i = 0; i < allowedReactions.length; i++) _pop(i),
  ];
  final _hovered = ValueNotifier<int?>(null);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.drag?.attach(onMove: _onMove, onRelease: _onRelease);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    widget.drag?.detach();
    _entrance.dispose();
    _hovered.dispose();
    super.dispose();
  }

  /// The slot under a global point, or null when the point is off the bar
  /// (a little room is left above it: the hovered emoji rises).
  int? _slotAt(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    final size = box.size;
    if (local.dx < 0 ||
        local.dx > size.width ||
        local.dy < -_hoverReach ||
        local.dy > size.height) {
      return null;
    }
    // Slots run from the START side: right to left in a right-to-left language.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fromStart = rtl ? size.width - local.dx : local.dx;
    final x = fromStart - ReactionBar.border - ReactionBar.padding;
    final index = (x / (ReactionBar.slot + ReactionBar.gap)).floor();
    return index.clamp(0, allowedReactions.length - 1);
  }

  void _onMove(Offset global) {
    final slot = _slotAt(global);
    if (slot == _hovered.value) return;
    if (slot != null) HapticFeedback.selectionClick();
    _hovered.value = slot;
  }

  /// Lifting on an emoji reacts; lifting anywhere else just clears the hover
  /// and leaves the bar and the menu open. Only a finger that moved onto the
  /// bar counts, so lifting where the press began never reacts by accident.
  void _onRelease(Offset _) {
    final slot = _hovered.value;
    _hovered.value = null;
    if (slot != null) widget.onPick(allowedReactions[slot]);
  }

  Animation<double> _pop(int index) {
    final total = _total.inMilliseconds;
    final start = index * _stagger / total;
    final end = (index * _stagger + _popMs) / total;
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _entrance, curve: Interval(start, end)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final capsule = Container(
      key: const ValueKey('reaction-bar'),
      height: ReactionBar.height,
      padding: const EdgeInsets.symmetric(horizontal: ReactionBar.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? AppColors.dividerDark : AppColors.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < allowedReactions.length; i++) ...[
            if (i > 0) const SizedBox(width: ReactionBar.gap),
            _Slot(
              emoji: allowedReactions[i],
              index: i,
              mine: widget.selected.contains(allowedReactions[i]),
              hovered: _hovered,
              pop: _pops[i],
              onTap: () => widget.onPick(allowedReactions[i]),
            ),
          ],
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _grow,
      child: capsule,
      builder: (context, child) => Transform.scale(
        scale: _grow.value,
        alignment: widget.mine
            ? AlignmentDirectional.bottomEnd
            : AlignmentDirectional.bottomStart,
        child: child,
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.emoji,
    required this.index,
    required this.mine,
    required this.hovered,
    required this.pop,
    required this.onTap,
  });

  final String emoji;
  final int index;
  final bool mine;
  final ValueListenable<int?> hovered;
  final Animation<double> pop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final content = SizedBox.square(
      dimension: ReactionBar.slot,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (mine)
            Container(
              key: const ValueKey('reaction-disc'),
              width: ReactionBar.slot,
              height: ReactionBar.slot,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            emoji,
            style: const TextStyle(
              fontSize: ReactionBar.emojiSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: pop,
        child: ValueListenableBuilder<int?>(
          valueListenable: hovered,
          child: content,
          builder: (context, current, child) => TweenAnimationBuilder<double>(
            tween: Tween<double>(end: current == index ? 1 : 0),
            duration: noMotion
                ? Duration.zero
                : const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: child,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(0, -8 * t),
              child: Transform.scale(scale: 1 + 0.35 * t, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
