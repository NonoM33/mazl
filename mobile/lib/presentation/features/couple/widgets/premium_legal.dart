import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';

/// The small print under the buttons: renewal, cancellation, where the price
/// comes from, then the two links.
class PremiumLegal extends StatelessWidget {
  const PremiumLegal({
    super.key,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final link = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.couplePremiumLegal,
          style: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: 12,
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              style: link,
              onPressed: onOpenTerms,
              child: Text(l10n.plusTerms),
            ),
            Text('·', style: TextStyle(color: scheme.onSurfaceVariant)),
            TextButton(
              style: link,
              onPressed: onOpenPrivacy,
              child: Text(l10n.plusPrivacy),
            ),
          ],
        ),
      ],
    );
  }
}
