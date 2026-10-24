import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Catégories d'événements proposées en filtre, dans l'ordre d'affichage.
/// La clé `null` est « Tout ».
const eventCategoryFilters = <({String? key, String label})>[
  (key: null, label: 'Tout'),
  (key: 'dinner', label: 'Dîner'),
  (key: 'tasting', label: 'Dégustation'),
  (key: 'party', label: 'Soirée'),
  (key: 'workshop', label: 'Atelier'),
  (key: 'brunch', label: 'Brunch'),
  (key: 'spiritual', label: 'Spirituel'),
  (key: 'travel', label: 'Week-end'),
];

/// Libellé français d'une catégorie renvoyée par l'API.
String eventCategoryLabel(String? category) {
  switch (category) {
    case 'dinner':
      return 'Dîner';
    case 'tasting':
      return 'Dégustation';
    case 'party':
      return 'Soirée';
    case 'workshop':
      return 'Atelier';
    case 'brunch':
      return 'Brunch';
    case 'spiritual':
      return 'Spirituel';
    case 'travel':
      return 'Week-end';
    case 'concert':
      return 'Concert';
    case 'game':
      return 'Jeux';
    default:
      return 'Événement';
  }
}

/// Icône Lucide d'une catégorie.
IconData eventCategoryIcon(String? category) {
  switch (category) {
    case 'dinner':
      return LucideIcons.utensils;
    case 'tasting':
      return LucideIcons.wine;
    case 'party':
      return LucideIcons.partyPopper;
    case 'workshop':
      return LucideIcons.palette;
    case 'brunch':
      return LucideIcons.croissant;
    case 'spiritual':
      return LucideIcons.sparkles;
    case 'travel':
      return LucideIcons.plane;
    case 'concert':
      return LucideIcons.music;
    case 'game':
      return LucideIcons.gamepad2;
    default:
      return LucideIcons.calendar;
  }
}

/// Emplacement d'image d'un événement sans photo : aplat neutre et icône grise.
class EventImagePlaceholder extends StatelessWidget {
  const EventImagePlaceholder({
    super.key,
    required this.category,
    required this.seed,
    this.iconSize = 40,
  });

  final String? category;

  /// Choisit la teinte, pour que deux événements voisins diffèrent.
  final int seed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.photoTints[seed.abs() % AppColors.photoTints.length];
    return ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          eventCategoryIcon(category),
          size: iconSize,
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}
