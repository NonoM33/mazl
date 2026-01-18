import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget to select relationship intention
class RelationshipIntentionSelector extends StatelessWidget {
  const RelationshipIntentionSelector({
    super.key,
    this.selectedIntention,
    required this.onChanged,
  });

  final String? selectedIntention;
  final Function(String?) onChanged;

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'ring':
        return LucideIcons.gem;
      case 'heart':
        return LucideIcons.heart;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'users':
        return LucideIcons.users;
      default:
        return LucideIcons.heart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ce que je recherche',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Montre aux autres ce que tu recherches',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RelationshipIntention.intentions.map((intention) {
            final isSelected = selectedIntention == intention.id;
            return _IntentionChip(
              intention: intention,
              icon: _getIcon(intention.icon),
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
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
              intention.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
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

  RelationshipIntention? get _intention {
    try {
      return RelationshipIntention.intentions.firstWhere((i) => i.id == intentionId);
    } catch (_) {
      return null;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'ring':
        return LucideIcons.gem;
      case 'heart':
        return LucideIcons.heart;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'users':
        return LucideIcons.users;
      default:
        return LucideIcons.heart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intention = _intention;
    if (intention == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(intention.icon),
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            intention.label,
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

  RelationshipIntention? get _intention {
    try {
      return RelationshipIntention.intentions.firstWhere((i) => i.id == intentionId);
    } catch (_) {
      return null;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'ring':
        return LucideIcons.gem;
      case 'heart':
        return LucideIcons.heart;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'users':
        return LucideIcons.users;
      default:
        return LucideIcons.heart;
    }
  }

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
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(intention.icon),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ce que je recherche',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intention.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  intention.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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
