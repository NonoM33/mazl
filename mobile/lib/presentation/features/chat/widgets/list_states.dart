import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../../core/layout/fold_message_view.dart';
import '../../../common/widgets/fold_pages.dart';

/// Grey bubbles while the first page loads. Still under reduced motion.
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _rows = [
    (false, 0.55),
    (false, 0.4),
    (true, 0.5),
    (false, 0.62),
    (true, 0.35),
    (true, 0.58),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.chatLoading,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Opacity(
          opacity: 0.55 + 0.45 * _pulse.value,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            children: [
              for (final (mine, factor) in _rows)
                Align(
                  alignment: mine
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.sizeOf(context).width * factor,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mine
                          ? scheme.primary.withValues(alpha: 0.18)
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first load failed.
class ListError extends StatelessWidget {
  const ListError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FoldMessageView(
    title: message,
    actionLabel: context.l10n.commonRetry,
    onAction: onRetry,
  );
}

/// A match with no message yet.
class EmptyConversation extends StatelessWidget {
  const EmptyConversation({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // Set down like a laptop, the greeting stays above the fold.
    return FoldPages(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      lead: [
        SectionLabel(context.l10n.chatNewMatch),
        const SizedBox(height: 12),
        Text(
          context.l10n.chatEmptyTitle,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.chatEmptyBody,
          style: TextStyle(fontSize: 16, height: 1.45, color: muted),
        ),
      ],
      rest: const [],
    );
  }
}
