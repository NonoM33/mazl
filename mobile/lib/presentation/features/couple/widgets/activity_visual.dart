import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/theme/app_colors.dart';

/// Icône Lucide d'une catégorie d'activité : jamais d'émoji.
IconData activityCategoryIcon(String category) => switch (category) {
  'wellness' => LucideIcons.flower2,
  'gastronomy' => LucideIcons.utensils,
  'culture' => LucideIcons.drama,
  'sport' => LucideIcons.dumbbell,
  'travel' => LucideIcons.plane,
  'spiritual' => LucideIcons.bookOpen,
  'diy' => LucideIcons.palette,
  'romantic' => LucideIcons.heart,
  _ => LucideIcons.sparkles,
};

/// L'image d'une activité ou, à défaut, un aplat neutre opaque avec l'icône de
/// sa catégorie, petite et centrée.
class ActivityVisual extends StatelessWidget {
  const ActivityVisual({super.key, required this.activity, this.iconSize = 40});

  final CoupleActivity activity;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint =
        AppColors.photoTints[activity.id.abs() % AppColors.photoTints.length];
    final fallback = ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          activityCategoryIcon(activity.category),
          size: iconSize,
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
    final url = activity.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: tint),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// Pilule pleine sur l'accent : « Partenaire MAZL », « -15 % Partenaire ».
class AccentPill extends StatelessWidget {
  const AccentPill(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onPrimary),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
