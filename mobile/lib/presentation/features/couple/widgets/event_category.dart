import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// Catégories d'événements proposées en filtre, dans l'ordre d'affichage.
/// La clé `null` est « Tout ».
const eventCategoryFilters = <String?>[
  null,
  'dinner',
  'tasting',
  'party',
  'workshop',
  'brunch',
  'spiritual',
  'travel',
];

/// Libellé d'une puce de filtre : « Tout » pour la clé `null`, sinon le nom
/// de la catégorie.
String eventFilterLabel(AppLocalizations l10n, String? key) =>
    key == null ? l10n.coupleFeedFilterAll : eventCategoryLabel(l10n, key);

/// Libellé, dans la langue du membre, d'une catégorie renvoyée par l'API.
String eventCategoryLabel(AppLocalizations l10n, String? category) =>
    switch (category) {
      'dinner' => l10n.coupleFeedEventCategoryDinner,
      'tasting' => l10n.coupleFeedEventCategoryTasting,
      'party' => l10n.coupleFeedEventCategoryParty,
      'workshop' => l10n.coupleFeedEventCategoryWorkshop,
      'brunch' => l10n.coupleFeedEventCategoryBrunch,
      'spiritual' => l10n.coupleFeedEventCategorySpiritual,
      'travel' => l10n.coupleFeedEventCategoryTravel,
      'concert' => l10n.coupleFeedEventCategoryConcert,
      'game' => l10n.coupleFeedEventCategoryGame,
      _ => l10n.coupleFeedEventCategoryOther,
    };

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
