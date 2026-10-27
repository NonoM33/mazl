import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// « Réglages du couple »: the status of the relationship in three pills, and
/// the MAZL Couple line.
class UsSettingsSection extends StatelessWidget {
  const UsSettingsSection({
    super.key,
    required this.status,
    required this.premium,
    required this.partnerName,
    required this.onStatus,
    required this.onPremium,
  });

  final RelationshipStatus status;
  final CouplePremium premium;
  final String partnerName;
  final ValueChanged<RelationshipStatus> onStatus;
  final VoidCallback onPremium;

  static const _choices = [
    RelationshipStatus.inRelationship,
    RelationshipStatus.engaged,
    RelationshipStatus.married,
  ];

  String _label(AppLocalizations l10n, RelationshipStatus s) => switch (s) {
    RelationshipStatus.engaged => l10n.coupleUsStatusEngaged,
    RelationshipStatus.married => l10n.coupleUsStatusMarried,
    _ => l10n.coupleUsStatusInRelationship,
  };

  String _premiumLine(AppLocalizations l10n) {
    if (!premium.active) return l10n.coupleUsPremiumDiscover;
    return switch (premium.paidBy) {
      CouplePayer.me => l10n.coupleUsPremiumActiveByYou,
      CouplePayer.partner => l10n.coupleUsPremiumActiveByPartner(partnerName),
      null => l10n.coupleUsPremiumActive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.coupleUsSettingsLabel),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in _choices)
              CouplePill(
                key: Key('couple-us-status-${choice.name}'),
                label: _label(l10n, choice),
                selected: status == choice,
                onTap: () => onStatus(choice),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CoupleCard(
          onTap: onPremium,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 16, 14),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 22, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coupleUsPremiumTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      _premiumLine(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DirectionalIcon(
                LucideIcons.chevronRight,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
