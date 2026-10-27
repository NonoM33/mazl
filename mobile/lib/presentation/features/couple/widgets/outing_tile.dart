import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import 'outing_labels.dart';
import 'outing_photo.dart';
import 'outing_save_button.dart';

const double kOutingTilePhotoHeight = 104;

/// A tile of the « Choisis pour vous deux » grid: the photo (or its tinted
/// stand-in), a title on two lines, one line of facts. An activity carries
/// its bookmark in the corner of the photo; an event has none (it is booked,
/// not saved).
class OutingTile extends StatelessWidget {
  const OutingTile({
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
    return Stack(
      children: [
        Material(
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kOutingTilePhotoHeight,
                  child: OutingPhoto(outing: outing, iconSize: 32),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outing.tileMeta(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!outing.isEvent)
          PositionedDirectional(
            top: 4,
            end: 4,
            child: OutingSaveButton(
              saved: outing.saved,
              onPressed: onToggleSave,
            ),
          ),
      ],
    );
  }
}
