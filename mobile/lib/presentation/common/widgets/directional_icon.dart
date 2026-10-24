import 'package:flutter/widgets.dart';

/// An icon that points somewhere (back, next, a chevron): mirrored in a
/// right-to-left language, where « back » points right.
///
/// Material's `Icons.arrow_back` already mirrors itself; Lucide icons do not.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
    if (Directionality.of(context) == TextDirection.ltr) return glyph;
    return Transform.flip(flipX: true, child: glyph);
  }
}
