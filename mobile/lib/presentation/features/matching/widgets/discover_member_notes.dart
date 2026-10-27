import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/profile.dart' show Profile;
import '../../../../l10n/l10n.dart';
import '../../passport/l10n/passport_city_label.dart';

/// What a Discover card says about the member beyond the profile itself:
/// « De passage à X » when they use the Passeport (mazl+), and a Super Like
/// mark with its word when they sent the signed-in member one.
///
/// Nothing is drawn when the profile carries neither. The marks must not eat
/// the photo: on a short window (the foldable iPhone standing like a tent) they
/// shrink to one line of chips; elsewhere the word takes up to three lines,
/// unless [detailed] (the roomy half beside the photo) shows it whole.
class DiscoverMemberNotes extends StatelessWidget {
  const DiscoverMemberNotes({
    super.key,
    required this.profile,
    this.detailed = false,
  });

  final Profile profile;
  final bool detailed;

  /// Under this window height, the marks are chips on a single line.
  static const double compactBelowHeight = 560;

  @override
  Widget build(BuildContext context) {
    final city = profile.travelingCity;
    if (city == null && !profile.superLikedYou) return const SizedBox.shrink();
    final compact =
        !detailed && MediaQuery.sizeOf(context).height < compactBelowHeight;
    final traveling = city == null ? null : _TravelingPill(city: city);
    final padding = const EdgeInsets.only(top: 10);
    if (compact) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ?traveling,
            if (profile.superLikedYou)
              _SuperLikeChip(note: profile.superLikeNote),
          ],
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?traveling,
          if (traveling != null && profile.superLikedYou)
            const SizedBox(height: 8),
          if (profile.superLikedYou)
            _SuperLikeMark(
              note: profile.superLikeNote,
              maxLines: detailed ? null : 3,
            ),
        ],
      ),
    );
  }
}

class _TravelingPill extends StatelessWidget {
  const _TravelingPill({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('discover-traveling'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plane, size: 14, color: scheme.onSurface),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.discoverCardTraveling(passportServerCityLabel(l10n, city)),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Super Like on one line: its word when there is one, else the mark.
class _SuperLikeChip extends StatelessWidget {
  const _SuperLikeChip({required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final word = note;
    return Semantics(
      container: true,
      label: word == null
          ? l10n.discoverCardSuperLiked
          : '${l10n.discoverCardSuperLiked}. ${l10n.discoverCardSuperLikeNote(word)}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          key: const ValueKey('discover-super-liked'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.star,
                size: 14,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  word == null
                      ? l10n.discoverCardSuperLiked
                      : l10n.discoverCardSuperLikeNote(word),
                  key: word == null
                      ? null
                      : const ValueKey('discover-super-like-note'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperLikeMark extends StatelessWidget {
  const _SuperLikeMark({required this.note, required this.maxLines});

  final String? note;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final word = note;
    return Container(
      key: const ValueKey('discover-super-liked'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.star,
                size: 16,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.discoverCardSuperLiked,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (word != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.discoverCardSuperLikeNote(word),
              key: const ValueKey('discover-super-like-note'),
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
