import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// The argument of MAZL Couple, left page: the word mark « mazl. couple »,
/// the big headline, one sentence and the five things it brings.
class PremiumPitch extends StatelessWidget {
  const PremiumPitch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final perks = [
      (
        l10n.couplePremiumPerkConciergeTitle,
        l10n.couplePremiumPerkConciergeMeta,
      ),
      (l10n.couplePremiumPerkRitualsTitle, l10n.couplePremiumPerkRitualsMeta),
      (l10n.couplePremiumPerkOutingsTitle, l10n.couplePremiumPerkOutingsMeta),
      (l10n.couplePremiumPerkQuestionTitle, l10n.couplePremiumPerkQuestionMeta),
      (l10n.couplePremiumPerkCheckinTitle, l10n.couplePremiumPerkCheckinMeta),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MazlWordmark(),
              const SizedBox(width: 8),
              Text(
                l10n.couplePremiumWordmarkSuffix,
                style: AppTypography.wordmark(26, scheme.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(l10n.couplePremiumHeadline, style: theme.textTheme.displayMedium),
        const SizedBox(height: 18),
        Text(
          l10n.couplePremiumIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final (title, meta) in perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Perk(title: title, meta: meta),
          ),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          child: SizedBox.square(
            dimension: 28,
            child: Icon(
              LucideIcons.check,
              size: 16,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(meta, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
