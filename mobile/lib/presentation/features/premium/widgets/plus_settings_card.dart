import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import 'plus_widgets.dart';

/// Ligne unique de la section « Abonnement » des réglages : mène à la gestion
/// de l'abonnement pour un abonné, à l'offre mazl+ sinon.
class PlusSettingsCard extends StatelessWidget {
  const PlusSettingsCard({
    super.key,
    required this.isPremium,
    required this.onTap,
    this.detail,
  });

  final bool isPremium;
  final VoidCallback onTap;

  /// Ligne secondaire pour un abonné (« 6 mois · jusqu'au 12 mars 2027 »).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final subtitle = isPremium
        ? (detail ?? l10n.plusActiveSubscription)
        : l10n.plusSettingsPitch;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        button: true,
        label: isPremium
            ? l10n.plusSettingsSemanticsActive(subtitle)
            : l10n.plusSettingsSemanticsUpgrade(subtitle),
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPremium)
                            const PlusWord(size: 22)
                          else
                            Text.rich(
                              TextSpan(
                                children: brandPhraseSpans(
                                  l10n.plusUpgradeTo,
                                  plusWordSpans(plusColor: scheme.primary),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DirectionalIcon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: scheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
