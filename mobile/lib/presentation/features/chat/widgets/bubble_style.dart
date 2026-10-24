import 'package:flutter/material.dart';

/// Shape and size rules of a bubble (docs/design/CHAT.md §2).
abstract class BubbleStyle {
  static const big = Radius.circular(22);
  static const stacked = Radius.circular(8);
  static const tail = Radius.circular(6);

  /// Within a group the side against the margin is squeezed to 8 so bubbles
  /// stack; the last bubble carries the 6 px tail.
  ///
  /// Directional: my bubbles sit on the END side (right in French, left in
  /// Hebrew) and carry the tail there; the others sit on the START side.
  static BorderRadiusDirectional radius({
    required bool mine,
    required bool first,
    required bool last,
  }) {
    final top = first ? big : stacked;
    final bottom = last ? tail : stacked;
    return mine
        ? BorderRadiusDirectional.only(
            topStart: big,
            topEnd: top,
            bottomStart: big,
            bottomEnd: bottom,
          )
        : BorderRadiusDirectional.only(
            topStart: top,
            topEnd: big,
            bottomStart: bottom,
            bottomEnd: big,
          );
  }

  /// 270 px, or 75 % of the screen when it is wider than 360.
  static double maxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 360 ? 270 : width * 0.75;
  }

  static const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 11);

  /// Gap above a bubble: 2 inside a group, 12 between groups.
  static double gapAbove({required bool first}) => first ? 12 : 2;
}

/// Colours of the content drawn inside a bubble, from the colour scheme only.
class BubbleColors {
  const BubbleColors._({
    required this.background,
    required this.text,
    required this.muted,
    required this.inset,
  });

  final Color background;
  final Color text;
  final Color muted;

  /// Fill of a card nested in the bubble (quote, link preview).
  final Color inset;

  factory BubbleColors.of(BuildContext context, {required bool mine}) {
    final scheme = Theme.of(context).colorScheme;
    return mine
        ? BubbleColors._(
            background: scheme.primary,
            text: scheme.onPrimary,
            muted: scheme.onPrimary.withValues(alpha: 0.78),
            inset: scheme.onPrimary.withValues(alpha: 0.14),
          )
        : BubbleColors._(
            background: scheme.surfaceContainer,
            text: scheme.onSurface,
            muted: scheme.onSurfaceVariant,
            inset: scheme.surface,
          );
  }
}
