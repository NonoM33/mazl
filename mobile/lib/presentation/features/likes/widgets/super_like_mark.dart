import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The small « Super Like » mark laid over the tile of a like that is one.
class SuperLikeMark extends StatelessWidget {
  const SuperLikeMark({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tekhelet,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, size: 12, color: AppColors.paper),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The word that came with a Super Like, shown soberly over the photo of a
/// subscriber's tile: two lines at most, on the surface colour.
class LikeNoteBubble extends StatelessWidget {
  const LikeNoteBubble({super.key, required this.note, required this.label});

  final String note;

  /// Accessibility label (« Mot de Jeanne »).
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      value: note,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, height: 1.25, color: scheme.onSurface),
        ),
      ),
    );
  }
}
