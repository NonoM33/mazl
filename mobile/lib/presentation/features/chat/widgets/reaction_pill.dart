import 'package:flutter/material.dart';

import '../state/chat_controller.dart';
import 'chat_scope.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Reactions of a bubble as a small pill biting 8 px into its bottom edge on
/// the side opposite the tail (docs/design/CHAT.md §4). Tapping lists who reacted.
class ReactionPill extends StatelessWidget {
  const ReactionPill({
    super.key,
    required this.reactions,
    required this.myUserId,
    required this.onTap,
  });

  static const height = 22.0;
  static const bite = 8.0;

  final List<Reaction> reactions;
  final int myUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = [
      for (final r in reactions)
        if (r.userIds.isNotEmpty) r,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();
    final mine = visible.any((r) => r.userIds.contains(myUserId));
    // The outer 2 px ring is the page colour: the pill detaches without a shadow.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: const ValueKey('reaction-pill'),
        height: height + 4,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          key: const ValueKey('reaction-pill-fill'),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: mine ? Border.all(color: scheme.primary) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in visible) ...[
                Text(
                  r.emoji,
                  style: const TextStyle(fontSize: 13, height: 1.2),
                ),
                if (r.userIds.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '${r.userIds.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (r != visible.last) const SizedBox(width: 6),
              ],
            ],
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
