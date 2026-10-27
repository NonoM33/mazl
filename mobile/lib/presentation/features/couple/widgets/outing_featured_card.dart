import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import 'couple_kit.dart';
import 'activity_visual.dart' show AccentPill;
import 'outing_labels.dart';
import 'outing_photo.dart';
import 'outing_save_button.dart';

const double kOutingFeaturedPhotoHeight = 176;

/// The outing put forward: a big card with its photo on top, what it is, when
/// and where, and the way in. An event is booked (« Réserver pour nous
/// deux »); an activity is looked at (« Voir ») and can be bookmarked.
class OutingFeaturedCard extends StatelessWidget {
  const OutingFeaturedCard({
    super.key,
    required this.outing,
    required this.onOpen,
    required this.onToggleSave,
  });

  final Outing outing;
  final VoidCallback onOpen;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final subtitle = outing.subtitle;
    final meta = outing.featuredMeta(l10n);
    return CoupleCard(
      radius: 28,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kOutingFeaturedPhotoHeight,
            child: OutingPhoto(outing: outing, iconSize: 48),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outing.isEvent) ...[
                  AccentPill(l10n.coupleOutingsEventBadge),
                  const SizedBox(height: 12),
                ],
                Text(
                  outing.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          outing.isEvent
                              ? l10n.coupleOutingsBookForUs
                              : l10n.coupleOutingsView,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!outing.isEvent) ...[
                      const SizedBox(width: 12),
                      OutingSaveButton(
                        saved: outing.saved,
                        size: 48,
                        onPressed: onToggleSave,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
