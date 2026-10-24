import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// Quiet warning in the thread under a received message flagged by the scam
/// rules (docs/design/CHAT.md §11). It warns, it never blocks.
class ScamWarningCard extends StatelessWidget {
  const ScamWarningCard({
    super.key,
    required this.show,
    required this.onReport,
    this.onLearnMore,
  });

  final bool show;
  final VoidCallback onReport;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.shieldAlert,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chatScamTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.chatScamBody,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    if (onLearnMore != null)
                      _Link(context.l10n.chatScamLearnMore, onLearnMore!, scheme.primary),
                    _Link(context.l10n.commonReport, onReport, scheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap, this.color);

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 16),
        child: Align(
          widthFactor: 1,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}
