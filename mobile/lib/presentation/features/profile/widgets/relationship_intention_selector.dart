import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/relationship_intention.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/profile_answer_labels.dart';

IconData _intentionIcon(RelationshipIntention intention) =>
    switch (intention.icon) {
      'ring' => LucideIcons.gem,
      'sparkles' => LucideIcons.sparkles,
      'users' => LucideIcons.users,
      _ => LucideIcons.heart,
    };

/// Widget to select relationship intention
class RelationshipIntentionSelector extends StatelessWidget {
  const RelationshipIntentionSelector({
    super.key,
    this.selectedIntention,
    required this.onChanged,
  });

  final String? selectedIntention;
  final Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profileLookingFor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.profileIntentionHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RelationshipIntention.selectable.map((intention) {
            final isSelected = selectedIntention == intention.id;
            return _IntentionChip(
              intention: intention,
              icon: _intentionIcon(intention),
              isSelected: isSelected,
              onTap: () => onChanged(isSelected ? null : intention.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _IntentionChip extends StatelessWidget {
  const _IntentionChip({
    required this.intention,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final RelationshipIntention intention;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              intention.selectorLabel(context.l10n),
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Display-only badge for relationship intention on profiles
class RelationshipIntentionBadge extends StatelessWidget {
  const RelationshipIntentionBadge({
    super.key,
    required this.intentionId,
  });

  final String intentionId;

  RelationshipIntention? get _intention =>
      RelationshipIntention.fromId(intentionId);

  @override
  Widget build(BuildContext context) {
    final intention = _intention;
    if (intention == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _intentionIcon(intention),
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            intention.selectorLabel(context.l10n),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full intention display with description
class RelationshipIntentionCard extends StatelessWidget {
  const RelationshipIntentionCard({
    super.key,
    required this.intentionId,
  });

  final String intentionId;

  RelationshipIntention? get _intention =>
      RelationshipIntention.fromId(intentionId);

  @override
  Widget build(BuildContext context) {
    final intention = _intention;
    if (intention == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _intentionIcon(intention),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.profileLookingFor,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intention.selectorLabel(context.l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  intention.description(context.l10n),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
