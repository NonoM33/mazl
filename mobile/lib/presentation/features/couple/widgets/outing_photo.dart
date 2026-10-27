import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_daily.dart';

/// The photo of an outing. Without one (no address, or the picture does not
/// load) a tinted block with the icon of its kind stands in: never an empty
/// hole. The tint comes from the theme so it reads in light and dark.
class OutingPhoto extends StatelessWidget {
  const OutingPhoto({super.key, required this.outing, this.iconSize = 36});

  final Outing outing;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(outing: outing, iconSize: iconSize);
    final url = outing.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _Tint(seed: outing.id),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _Tint extends StatelessWidget {
  const _Tint({super.key, required this.seed, this.child});

  final int seed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.05 + 0.025 * (seed.abs() % 4)),
      scheme.surfaceContainerHighest,
    );
    return ColoredBox(color: tint, child: child);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.outing, required this.iconSize});

  final Outing outing;
  final double iconSize;

  @override
  Widget build(BuildContext context) => _Tint(
    key: Key('outing-photo-fallback-${outing.id}'),
    seed: outing.id,
    child: Center(
      child: Icon(
        outing.isEvent ? LucideIcons.calendarHeart : LucideIcons.sparkles,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
