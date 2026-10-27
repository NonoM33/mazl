import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'like_fill/like_fill.dart';
import 'rolling_count/rolling_count.dart';

/// Le mot-symbole « mazl. », point en tekhelet.
class MazlWordmark extends StatelessWidget {
  const MazlWordmark({super.key, this.size = 26, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    // A logo, not a sentence: the dot stays after the word in Hebrew too.
    return Text.rich(
      textDirection: TextDirection.ltr,
      TextSpan(
        text: 'mazl',
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      semanticsLabel: 'mazl',
      style: AppTypography.wordmark(size, ink),
    );
  }
}

/// Étiquette de section en Geist Mono capitales.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color, this.count});

  final String text;
  final Color? color;

  /// The number inside [text], when it is a live count: its digits roll as it
  /// changes instead of jumping.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final muted = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final style = AppTypography.eyebrow(muted);
    final shown = text.toUpperCase();
    final live = count;
    if (live == null) return Text(shown, style: style);
    return RollingCount(value: live, sentence: shown, style: style);
  }
}

/// Photo de profil ou, à défaut, un aplat neutre avec une silhouette.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    this.url,
    this.seed = 0,
    this.radius = 32,
    this.iconSize = 40,
  });

  final String? url;

  /// Choisit la teinte de repli, pour que deux profils voisins diffèrent.
  final int seed;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.photoTints[seed.abs() % AppColors.photoTints.length];
    final fallback = ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          LucideIcons.user,
          size: iconSize,
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
    final hasUrl = url != null && url!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(color: tint),
              errorWidget: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}

/// Puce d'information : « Massorti », « Shabbat en famille ».
class TagPill extends StatelessWidget {
  const TagPill(
    this.label, {
    super.key,
    this.icon,
    this.onDark = false,
    this.onCard = false,
  });

  final String label;
  final IconData? icon;
  final bool onDark;

  /// Posée sur une carte brume : la puce prend le fond de page pour rester
  /// visible (brume sur brume ne se voit pas).
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = onDark
        ? Colors.white
        : (onCard ? scheme.surface : scheme.surfaceContainer);
    final foreground = onDark ? AppColors.ink : scheme.onSurface;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

enum RoundButtonStyle { outline, ink, accent }

/// Smallest tap target Apple allows, whatever the drawn size of a control.
const double kMinTapTarget = 44;

/// Bouton rond à icône : retour, options, passer, aimer, envoyer.
///
/// Dessiné plus petit que 44 pt, il garde une zone tactile de 44 x 44 pt
/// autour du cercle.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.style = RoundButtonStyle.outline,
    this.fillsFromTouch = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final RoundButtonStyle style;

  /// A heart button: a disc grows from the exact touch point (see [LikeFill]).
  final bool fillsFromTouch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, BorderSide side) = switch (style) {
      RoundButtonStyle.outline => (
        scheme.surface,
        scheme.onSurface,
        BorderSide(color: scheme.outline),
      ),
      RoundButtonStyle.ink => (
        scheme.onSurface,
        scheme.surface,
        BorderSide.none,
      ),
      RoundButtonStyle.accent => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        BorderSide.none,
      ),
    };
    final onPressed = this.onPressed;
    if (fillsFromTouch && onPressed != null) {
      return Semantics(
        button: true,
        label: tooltip,
        child: LikeFill(
          onTap: onPressed,
          background: bg,
          // On the accent fill the disc is a deeper tekhelet; elsewhere the
          // accent itself. The icon turns to the colour that reads on it.
          fillColor: style == RoundButtonStyle.accent
              ? Color.lerp(scheme.primaryContainer, scheme.shadow, 0.4)!
              : scheme.primary,
          shape: CircleBorder(side: side),
          size: Size.square(size),
          minHitSize: size >= kMinTapTarget ? null : kMinTapTarget,
          builder: (context, fill) => Center(
            child: Icon(
              icon,
              size: iconSize,
              color: style == RoundButtonStyle.accent
                  ? fg
                  : Color.lerp(fg, scheme.onPrimary, fill),
            ),
          ),
        ),
      );
    }
    final circle = SizedBox.square(
      dimension: size,
      child: Material(
        color: bg,
        shape: CircleBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Icon(icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: tooltip,
      child: size >= kMinTapTarget
          ? circle
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: onPressed,
              child: SizedBox.square(
                dimension: kMinTapTarget,
                child: Center(child: circle),
              ),
            ),
    );
  }
}

/// Une ligne « libellé ......... valeur » séparée par un filet.
class FactRow extends StatelessWidget {
  const FactRow({
    super.key,
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
