import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// A card of « Nous deux » that could not load: a sentence and a way to try
/// again, in place, so the rest of the screen stays usable.
class UsSectionError extends StatelessWidget {
  const UsSectionError({
    super.key,
    required this.title,
    required this.line,
    required this.onRetry,
  });

  final String title;
  final String line;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
              ),
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that waits for its section.
class UsLoadingCard extends StatelessWidget {
  const UsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) => const CoupleCard(
    child: SizedBox(
      height: 72,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}
