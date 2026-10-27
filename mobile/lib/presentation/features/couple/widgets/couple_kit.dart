import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';

/// The pieces the screens of the daily couple space share (the validated
/// mockups: surface cards of radius 24 to 28, a mono eyebrow over a big
/// title, pills, one accent). Colors come from the theme, never from here.
const double kCoupleCardRadius = 24;

/// A surface card ("brume" in light, the card color in dark), or a hairline
/// outlined one.
class CoupleCard extends StatelessWidget {
  const CoupleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = kCoupleCardRadius,
    this.outlined = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool outlined;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      container: semanticLabel != null,
      child: Material(
        color: outlined ? Colors.transparent : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: outlined ? BorderSide(color: scheme.outline) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      ),
    );
  }
}

/// The eyebrow and the big title that open a tab: « NOVEMBRE 2026 » over
/// « Agenda à deux ».
class CoupleHeader extends StatelessWidget {
  const CoupleHeader({super.key, required this.title, this.eyebrow});

  final String title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        SectionLabel(eyebrow!),
        const SizedBox(height: 8),
      ],
      Text(title, style: Theme.of(context).textTheme.displaySmall),
    ],
  );
}

/// A choice pill (a filter, a mood): full ink when selected. Drawn 40 pt
/// high, 44 pt to touch: the whole pill, edge to edge, is the control.
class CouplePill extends StatelessWidget {
  const CouplePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.surface : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Material(
          color: selected ? scheme.onSurface : scheme.surfaceContainer,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.family,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
