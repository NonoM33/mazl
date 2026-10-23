import 'package:flutter/material.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../state/chat_controller.dart';
import 'chat_scope.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Reactions of a bubble as a small pill biting 8 px into its bottom edge on
/// the side opposite the tail (docs/design/CHAT.md §4). Tapping lists who reacted.
class ReactionPill extends StatefulWidget {
  const ReactionPill({
    super.key,
    required this.reactions,
    required this.myUserId,
    required this.onTap,
    this.popOnAppear = false,
  });

  static const height = 24.0;
  static const bite = 8.0;
  static const ring = 2.0;
  static const maxEmojis = 3;

  final List<Reaction> reactions;
  final int myUserId;
  final VoidCallback onTap;

  /// Pops when first shown: the reactions just arrived on a message already
  /// on screen. A pill that comes with the row (history, scrolling) stays still.
  final bool popOnAppear;

  /// Reactions that count, the most liked first (ties keep their order).
  static List<Reaction> visible(List<Reaction> reactions) {
    final withUsers = [
      for (final r in reactions)
        if (r.userIds.isNotEmpty) r,
    ];
    final order = {for (var i = 0; i < withUsers.length; i++) withUsers[i]: i};
    withUsers.sort((a, b) {
      final byCount = b.userIds.length.compareTo(a.userIds.length);
      return byCount != 0 ? byCount : order[a]!.compareTo(order[b]!);
    });
    return withUsers;
  }

  @override
  State<ReactionPill> createState() => _ReactionPillState();
}

class _ReactionPillState extends State<ReactionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: MazlMotion.popDuration,
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: MazlMotion.reactionPopFrom,
        end: MazlMotion.popScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 65,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: MazlMotion.popScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _pop.value = 1;
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.popOnAppear) _play();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _pop.forward(from: 0);
  }

  @override
  void didUpdateWidget(ReactionPill old) {
    super.didUpdateWidget(old);
    if (_signature(old.reactions) != _signature(widget.reactions)) _play();
  }

  /// What the pill shows: emojis and who is behind them.
  static String _signature(List<Reaction> reactions) => [
    for (final r in ReactionPill.visible(reactions))
      '${r.emoji}:${r.userIds.join(',')}',
  ].join('|');

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = ReactionPill.visible(widget.reactions);
    if (visible.isEmpty) return const SizedBox.shrink();
    final shown = visible.take(ReactionPill.maxEmojis).toList();
    final total = visible.fold<int>(0, (sum, r) => sum + r.userIds.length);
    final mine = visible.any((r) => r.userIds.contains(widget.myUserId));
    // Mine: the accent at 12 % over the surface, never a contour.
    final fill = mine
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.12),
            scheme.surface,
          )
        : scheme.surface;
    // The outer 2 px ring is the page colour: the pill is cut out of the
    // bubble without a shadow.
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) =>
            Transform.scale(scale: _scale.transform(_pop.value), child: child),
        child: Container(
          key: const ValueKey('reaction-pill'),
          height: ReactionPill.height + 2 * ReactionPill.ring,
          padding: const EdgeInsets.all(ReactionPill.ring),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            key: const ValueKey('reaction-pill-fill'),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in shown)
                  Padding(
                    padding: EdgeInsets.only(right: r == shown.last ? 0 : 3),
                    child: Text(
                      r.emoji,
                      style: const TextStyle(fontSize: 15, height: 1.2),
                    ),
                  ),
                if (total > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet listing who reacted with what.
Future<void> showReactionsSheet(
  BuildContext context, {
  required List<Reaction> reactions,
  required ChatScope scope,
}) {
  return showMazlSheet<void>(
    context,
    padded: false,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'Réactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final reaction in reactions)
          for (final userId in reaction.userIds)
            ListTile(
              title: Text(scope.authorOf(userId)),
              trailing: Text(
                reaction.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
      ],
    ),
  );
}
