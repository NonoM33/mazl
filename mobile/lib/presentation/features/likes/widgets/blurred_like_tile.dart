import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/likes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../logic/like_age.dart';
import 'super_like_mark.dart';
import '../../../../core/images/mazl_network_image.dart';

/// The tile of a received like for a member without mazl+ (contract of
/// docs/premium/MONETISATION.md §1): a tiny blurred copy of the photo drawn
/// enlarged, « Quelqu'un » instead of the first name (even if the server sent
/// it), the verified badge, how long ago, and the Super Like mark. A tap opens
/// the offer.
///
/// The picture is a real 48 px image, never a "deblurred" one: it is stretched
/// with a good filter, and a gradient of the charter stands in without it.
class BlurredLikeTile extends StatelessWidget {
  const BlurredLikeTile({
    super.key,
    required this.like,
    required this.onTap,
    this.index = 0,
    this.now = DateTime.now,
  });

  /// Present when there is no usable photo.
  static const fallbackKey = Key('blurred-like-fallback');

  final LikeProfile like;
  final VoidCallback onTap;

  /// Position in the grid: picks the tint of the gradient so that two
  /// neighbours differ.
  final int index;

  /// Injectable clock, for tests.
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ago = likeAgeText(l10n, like.likedAt, now());
    return Semantics(
      button: true,
      label: l10n.likesBlurredLabel(ago),
      hint: l10n.likesBlurredHint,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Backdrop(url: like.blurredPhotoUrl, index: index),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    if (like.isSuperLike)
                      Flexible(
                        child: SuperLikeMark(label: l10n.likesSuperLikeBadge),
                      ),
                    const Spacer(),
                    const _LockChip(),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: _IdentityPill(
                    name: l10n.likesAnonymousName,
                    ago: ago,
                    isVerified: like.isVerified,
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

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url, required this.index});

  final String? url;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fallback = _GradientFallback(index: index);
    final photo = url;
    if (photo == null) return fallback;
    return MazlNetworkImage(
      url: photo,
      filterQuality: FilterQuality.high,
      placeholder: (_) => fallback,
      errorBuilder: (_) => fallback,
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final tint =
        AppColors.photoTints[index.abs() % AppColors.photoTints.length];
    return DecoratedBox(
      key: BlurredLikeTile.fallbackKey,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, Color.lerp(tint, AppColors.tekheletLight, 0.55)!],
        ),
      ),
    );
  }
}

class _IdentityPill extends StatelessWidget {
  const _IdentityPill({
    required this.name,
    required this.ago,
    required this.isVerified,
  });

  final String name;
  final String ago;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.surface,
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.badgeCheck, size: 14, color: scheme.surface),
              ],
            ],
          ),
          Text(
            ago,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.surface),
          ),
        ],
      ),
    );
  }
}

class _LockChip extends StatelessWidget {
  const _LockChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
      child: Icon(LucideIcons.lock, size: 14, color: scheme.onSurface),
    );
  }
}
