import 'package:flutter/material.dart';

import 'fold_cut.dart';
import 'fold_safe_actions.dart';

/// The narrowest page a message accepts on either side of a fold.
const double kFoldMessagePaneExtent = 240;

/// A centered icon, a title, one line and at most one action: the empty, the
/// error and the waiting state of a screen, kept off the fold of a half-open
/// foldable iPhone.
///
/// Held like a book, the words sit on the reading-start page and the action
/// on the other; set down like a laptop, the words above the fold and the
/// action below it. Anywhere else it is a single centered column.
class FoldMessageView extends StatelessWidget {
  const FoldMessageView({
    super.key,
    required this.title,
    this.line,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? line;
  final IconData? icon;

  /// The icon's color, the muted text color by default.
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final message = [
      if (icon != null) ...[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: iconColor ?? muted),
        ),
        const SizedBox(height: 16),
      ],
      Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      if (line != null) ...[
        const SizedBox(height: 8),
        Text(
          line!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    ];
    final action = actionLabel == null
        ? null
        : ElevatedButton(onPressed: onAction, child: Text(actionLabel!));
    Widget centered(List<Widget> children) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    return FoldCutBuilder(
      minPaneExtent: kFoldMessagePaneExtent,
      builder: (context, cut) {
        if (cut != null) {
          final lead = centered(message);
          final rest = action == null
              ? const SizedBox.shrink()
              : centered([action]);
          return switch (cut.axis) {
            FoldSplitAxis.vertical => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: cut.leadExtent, child: lead),
                SizedBox(width: cut.gap),
                Expanded(child: rest),
              ],
            ),
            FoldSplitAxis.horizontal => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: cut.leadExtent, child: lead),
                SizedBox(height: cut.gap),
                Expanded(child: rest),
              ],
            ),
          };
        }
        return FoldSafeActions(
          child: centered([
            ...message,
            if (action != null) ...[const SizedBox(height: 24), action],
          ]),
        );
      },
    );
  }
}
