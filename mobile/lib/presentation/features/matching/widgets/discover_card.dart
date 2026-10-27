import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_aware_split.dart';
import '../../../../core/models/profile.dart' show Profile;
import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/swipe_deck/swipe_deck.dart';
import '../../profile/l10n/profile_answer_labels.dart';
import '../../profile/widgets/profile_view/profile_sections.dart';
import '../../profile/widgets/profile_view/profile_view_content.dart'
    show lookingForLabel;
import '../../profile/widgets/profile_view/profile_view_data.dart';

/// Carte de découverte : la photo, puis le nom, la ville et les puces dessous.
///
/// Aucun texte n'est posé sur la photo. Passer et aimer chevauchent le bord
/// bas de la photo, à droite ; les actions secondaires (annuler, super like,
/// boost) sont de petits boutons à contour à gauche.
///
/// Sur un iPhone pliable à moitié plié, le pli coupe la carte : la photo reste
/// du côté où l'on regarde (au-dessus du pli, ou du côté de lecture), le nom,
/// les puces et TOUS les boutons passent de l'autre côté, hors de la courbe.
/// La carte garde son état (photo affichée) en se pliant.
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
  static const double sectionGap = 24;

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
    return FoldAwareSplit(
      lead: _buildLead(context),
      action: Builder(builder: _buildCard),
    );
  }

  BoxDecoration _cardDecoration(ColorScheme scheme) => BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: scheme.outlineVariant),
  );

  /// Half open: the photo alone, on the half where the member looks.
  Widget _buildLead(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: _buildPhotoBlock(overlayActions: false),
    );
  }

  /// Flat: the whole card. Split by the fold: the photo is the lead's, and
  /// the name, the details and the buttons fill the other half.
  Widget _buildCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final split = FoldAwareSplit.axisOf(context) != null;
    return Container(
      decoration: _cardDecoration(scheme),
      child: split
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The other half is wide enough for the whole profile: what
                // « Voir le profil » would open is read right here.
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('discover-detail'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfo(
                          context,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          detailed: true,
                        ),
                        _buildDetails(context),
                      ],
                    ),
                  ),
                ),
                _buildSplitActions(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPhotoBlock(overlayActions: true)),
                _buildInfo(
                  context,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                ),
              ],
            ),
    );
  }

  /// The four buttons under the details, on the half the fold leaves for them.
  Widget _buildSplitActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Wrap(
        textDirection: TextDirection.ltr,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (widget.secondaryActions.isNotEmpty) _buildSecondaryActions(),
          _buildPassAndLike(),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() => Row(
    textDirection: TextDirection.ltr,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < widget.secondaryActions.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        widget.secondaryActions[i],
      ],
    ],
  );

  // Swiping right likes in every language: the buttons keep the same sides as
  // the gesture, so they do not mirror in Hebrew.
  Widget _buildPassAndLike() => Row(
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
          fillsFromTouch: true,
          onPressed: widget.onLike,
        ),
      ),
    ],
  );

  /// The photo, its progress bars and the « Vérifiée » pill. With
  /// [overlayActions] the buttons straddle its bottom edge (flat card).
  Widget _buildPhotoBlock({required bool overlayActions}) {
    final photos = _profile.photos;
    final index = photos.isEmpty ? 0 : _photoIndex.clamp(0, photos.length - 1);
    final url = photos.isEmpty ? null : photos[index];
    return Stack(
      children: [
        Positioned.fill(
          bottom: overlayActions ? DiscoverCard._overhang : 0,
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
        if (overlayActions && widget.secondaryActions.isNotEmpty)
          Positioned(left: 16, bottom: 8, child: _buildSecondaryActions()),
        if (overlayActions)
          Positioned(right: 16, bottom: 0, child: _buildPassAndLike()),
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

  /// The profile's details under the name, as its full page shows them: about,
  /// the essentials, what they look for. The full page stays one tap away for
  /// every photo and the report options.
  Widget _buildDetails(BuildContext context) {
    final l10n = context.l10n;
    final data = ProfileViewData(
      name: _profile.displayName ?? l10n.matchingCardAnonymous,
      location: _profile.location,
      age: _profile.age,
      distance: _profile.distance,
      bio: _profile.bio,
      lookingFor: _profile.lookingFor,
      gender: _profile.gender,
      denomination: _profile.denomination,
      kashrut: _profile.kashrut,
      shabbatObservance: _profile.shabbatObservance,
      photos: _profile.photos,
      isVerified: _profile.isVerified,
      verificationLevel: _profile.verificationLevel,
    );
    final bio = data.bio?.trim();
    final facts = data.facts(l10n);
    final lookingFor = lookingForLabel(l10n, data.lookingFor);
    final intention = intentionFact(l10n, _profile.relationshipIntention);
    // Apple's 24 pt between two sections, as on the full profile page.
    final sections = <Widget>[
      if (bio != null && bio.isNotEmpty)
        ProfileTextSection(label: l10n.profileAbout, text: bio),
      if (facts.isNotEmpty) ProfileFactsSection(facts: facts),
      if (lookingFor != null)
        ProfileTextSection(label: l10n.profileLookingFor, text: lookingFor),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (intention != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TagPill(intention),
            ),
          for (final section in sections) ...[
            const SizedBox(height: sectionGap),
            section,
          ],
          if (widget.onTapProfile != null) ...[
            const SizedBox(height: sectionGap),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _viewProfileButton(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _viewProfileButton(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('discover-view-profile'),
    onPressed: widget.onTapProfile,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: const StadiumBorder(),
    ),
    icon: const Icon(LucideIcons.chevronRight, size: 18),
    iconAlignment: IconAlignment.end,
    label: Text(context.l10n.matchingCardViewProfile),
  );

  Widget _buildInfo(
    BuildContext context, {
    required EdgeInsets padding,
    bool detailed = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final name = _profile.displayName ?? context.l10n.matchingCardAnonymous;
    final meta = _metaLine(context);
    final tags = _tags(context.l10n);
    return Padding(
      padding: padding,
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
          // In the detailed half the essentials below say the same.
          if (!detailed && tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in tags) TagPill(tag)],
            ),
          ],
          if (!detailed && widget.onTapProfile != null) ...[
            const SizedBox(height: 12),
            _viewProfileButton(context),
          ],
        ],
      ),
    );
  }

  /// « Ville · à X km » : le modèle n'expose pas encore de métier.
  String _metaLine(BuildContext context) {
    final parts = <String>[
      if (_hasText(_profile.location)) _profile.location!.trim(),
      if (_profile.distance != null)
        context.l10n.matchingCardDistance(_profile.distance!.round()),
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

/// One faint segment per photo, and an ink one that slides to the photo shown
/// (docs/design/MOUVEMENT.md §3) instead of jumping; under reduced motion it
/// is there at once.
class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({required this.count, required this.current});

  static const _gap = 4.0;
  static const _height = 3.0;

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final reduced = MazlMotion.reduced(context);
    final segment = BorderRadius.circular(2);
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - _gap * (count - 1)) / count;
          return Stack(
            children: [
              for (var i = 0; i < count; i++)
                PositionedDirectional(
                  start: i * (width + _gap),
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Container(
                    key: Key('photo-bar-$i'),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      borderRadius: segment,
                    ),
                  ),
                ),
              AnimatedPositionedDirectional(
                duration: reduced
                    ? Duration.zero
                    : MazlMotion.photoIndicatorSlide,
                curve: MazlMotion.photoIndicatorCurve,
                start: current * (width + _gap),
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  key: const Key('photo-bar-current'),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: segment,
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
