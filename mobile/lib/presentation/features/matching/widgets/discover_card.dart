import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/profile.dart' show Profile;
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/swipe_deck/swipe_deck.dart';
import '../../profile/l10n/profile_answer_labels.dart';

/// Carte de découverte : la photo, puis le nom, la ville et les puces dessous.
///
/// Aucun texte n'est posé sur la photo. Passer et aimer chevauchent le bord
/// bas de la photo, à droite ; les actions secondaires (annuler, super like,
/// boost) sont de petits boutons à contour à gauche.
class DiscoverCard extends StatefulWidget {
  const DiscoverCard({
    super.key,
    required this.profile,
    required this.onPass,
    required this.onLike,
    this.onTapProfile,
    this.swipeProgress,
    this.secondaryActions = const [],
  });

  final Profile profile;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback? onTapProfile;

  /// Avancement du balayage en cours : les boutons « Passer » et « J'aime »
  /// grossissent quand la carte va dans leur sens. Absent sur la carte du dessous.
  final ValueListenable<SwipeProgress>? swipeProgress;
  final List<Widget> secondaryActions;

  static const double _actionSize = 60;

  /// Part des boutons ronds qui dépasse sous le bord de la photo.
  static const double _overhang = _actionSize / 2;

  @override
  State<DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<DiscoverCard> {
  int _photoIndex = 0;

  Profile get _profile => widget.profile;

  void _onPhotoTap(TapUpDetails details, double width) {
    final count = _profile.photos.length;
    if (count < 2) return;
    final forward = details.localPosition.dx >= width / 2;
    setState(() {
      _photoIndex = (_photoIndex + (forward ? 1 : count - 1)) % count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildPhotoBlock()),
          _buildInfo(context),
        ],
      ),
    );
  }

  Widget _buildPhotoBlock() {
    final photos = _profile.photos;
    final index = photos.isEmpty ? 0 : _photoIndex.clamp(0, photos.length - 1);
    final url = photos.isEmpty ? null : photos[index];
    return Stack(
      children: [
        Positioned.fill(
          bottom: DiscoverCard._overhang,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onPhotoTap(details, constraints.maxWidth),
              child: ProfilePhoto(
                url: url,
                seed: _profile.id,
                radius: 32,
                iconSize: 72,
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _PhotoProgress(count: photos.length, current: index),
          ),
        if (_profile.isVerified)
          Positioned(
            top: 28,
            left: 16,
            child: _givesWayToLike(const _VerifiedPill()),
          ),
        if (widget.secondaryActions.isNotEmpty)
          Positioned(
            left: 16,
            bottom: 8,
            child: Row(
              textDirection: TextDirection.ltr,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.secondaryActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  widget.secondaryActions[i],
                ],
              ],
            ),
          ),
        Positioned(
          right: 16,
          bottom: 0,
          // Swiping right likes in every language: the buttons keep the same
          // sides as the gesture, so they do not mirror in Hebrew.
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              _followsSwipe(
                SwipeDirection.left,
                RoundIconButton(
                  icon: LucideIcons.x,
                  tooltip: context.l10n.matchingCardPass,
                  size: DiscoverCard._actionSize,
                  iconSize: 26,
                  onPressed: widget.onPass,
                ),
              ),
              const SizedBox(width: 12),
              _followsSwipe(
                SwipeDirection.right,
                RoundIconButton(
                  icon: LucideIcons.heart,
                  tooltip: context.l10n.matchingCardLike,
                  size: DiscoverCard._actionSize,
                  iconSize: 26,
                  style: RoundButtonStyle.accent,
                  onPressed: widget.onLike,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The like disc lands where the « Vérifiée » pill sits: the pill fades out
  /// as the disc fades in, so the two never show on top of each other.
  Widget _givesWayToLike(Widget pill) {
    final progress = widget.swipeProgress;
    return ValueListenableBuilder<SwipeProgress>(
      valueListenable: progress ?? const IdleSwipeProgress(),
      child: pill,
      builder: (context, p, child) => Opacity(
        key: const Key('verified-pill'),
        opacity: 1 - p.of(SwipeDirection.right),
        child: child,
      ),
    );
  }

  Widget _followsSwipe(SwipeDirection direction, Widget button) {
    final progress = widget.swipeProgress;
    if (progress == null) return button;
    return SwipeProgressScale(
      progress: progress,
      direction: direction,
      child: button,
    );
  }

  Widget _buildInfo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = _profile.displayName ?? context.l10n.matchingCardAnonymous;
    final meta = _metaLine(context);
    final tags = _tags(context.l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            hint: context.l10n.matchingCardViewProfile,
            child: InkWell(
              onTap: widget.onTapProfile,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text.rich(
                    TextSpan(
                      text: name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                        color: scheme.onSurface,
                      ),
                      children: [
                        if (_profile.age != null)
                          TextSpan(
                            text: '  ${_profile.age}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.6,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in tags) TagPill(tag)],
            ),
          ],
        ],
      ),
    );
  }

  /// « Ville · à X km » : le modèle n'expose pas encore de métier.
  String _metaLine(BuildContext context) {
    final parts = <String>[
      if (_hasText(_profile.location)) _profile.location!.trim(),
      if (_profile.distance != null) context.l10n.matchingCardDistance(_profile.distance!.round()),
    ];
    return parts.join(' · ');
  }

  List<String> _tags(AppLocalizations l10n) => [
    denominationFact(l10n, _profile.denomination),
    kashrutFact(l10n, _profile.kashrut),
    shabbatFact(l10n, _profile.shabbatObservance),
    intentionFact(l10n, _profile.relationshipIntention),
  ].whereType<String>().toList();

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: Key('photo-bar-$i'),
              height: 3,
              decoration: BoxDecoration(
                color: i == current
                    ? AppColors.ink
                    : AppColors.ink.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.check, size: 14, color: AppColors.tekhelet),
          const SizedBox(width: 4),
          Text(
            context.l10n.matchingCardVerified,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit bouton rond à contour : annuler, super like, boost.
///
/// [badge] affiche un compteur, [locked] une couronne (fonction premium).
class DiscoverMiniAction extends StatelessWidget {
  const DiscoverMiniAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
    this.locked = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? badge;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RoundIconButton(
          icon: icon,
          tooltip: tooltip,
          iconSize: 18,
          onPressed: onPressed,
        ),
        if (locked || badge != null)
          PositionedDirectional(
            top: -2,
            end: -2,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: locked
                    ? Icon(LucideIcons.lock, size: 10, color: scheme.surface)
                    : Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.surface,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
