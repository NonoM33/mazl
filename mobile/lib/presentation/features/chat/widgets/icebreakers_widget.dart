import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/icebreaker_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget showing icebreaker suggestions for starting a conversation
class IcebreakersWidget extends StatelessWidget {
  const IcebreakersWidget({
    super.key,
    required this.icebreakers,
    required this.onSelect,
    this.onDismiss,
  });

  final List<Icebreaker> icebreakers;
  final Function(String text) onSelect;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (icebreakers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(12),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.lightbulb,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Besoin d\'inspiration ?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Voici quelques idees pour briser la glace',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(LucideIcons.x, size: 18, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Icebreaker suggestions
          ...icebreakers.take(3).map((icebreaker) => _IcebreakerCard(
                icebreaker: icebreaker,
                onTap: () => onSelect(icebreaker.text),
              )),
        ],
      ),
    );
  }
}

class _IcebreakerCard extends StatelessWidget {
  const _IcebreakerCard({
    required this.icebreaker,
    required this.onTap,
  });

  final Icebreaker icebreaker;
  final VoidCallback onTap;

  IconData get _icon {
    switch (icebreaker.type) {
      case IcebreakerType.prompt:
        return LucideIcons.messageCircle;
      case IcebreakerType.bio:
        return LucideIcons.user;
      case IcebreakerType.jewish:
        return LucideIcons.star;
      case IcebreakerType.location:
        return LucideIcons.mapPin;
      case IcebreakerType.generic:
        return LucideIcons.sparkles;
    }
  }

  Color get _iconColor {
    switch (icebreaker.type) {
      case IcebreakerType.prompt:
        return AppColors.primary;
      case IcebreakerType.bio:
        return Colors.purple;
      case IcebreakerType.jewish:
        return AppColors.accentGold;
      case IcebreakerType.location:
        return Colors.blue;
      case IcebreakerType.generic:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_icon, size: 18, color: _iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                icebreaker.text,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.send,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for inline suggestions
class InlineIcebreakersChips extends StatelessWidget {
  const InlineIcebreakersChips({
    super.key,
    required this.icebreakers,
    required this.onSelect,
  });

  final List<Icebreaker> icebreakers;
  final Function(String text) onSelect;

  @override
  Widget build(BuildContext context) {
    if (icebreakers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: icebreakers.length.clamp(0, 4),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final icebreaker = icebreakers[index];
          return ActionChip(
            label: Text(
              _truncate(icebreaker.text, 25),
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => onSelect(icebreaker.text),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          );
        },
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
