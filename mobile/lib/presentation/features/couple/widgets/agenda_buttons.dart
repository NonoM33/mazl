import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';

/// A pill button of the agenda: full ink for the main action of a page
/// (56 pt), a hairline outline for the others (44 pt). The whole pill, edge to
/// edge, is the control.
class AgendaPillButton extends StatelessWidget {
  const AgendaPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;

  /// Stretch to the width of the page (the main action).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = filled ? scheme.surface : scheme.onSurface;
    final pill = ConstrainedBox(
      constraints: BoxConstraints(minHeight: filled ? 56 : kMinTapTarget),
      child: Material(
        color: filled ? scheme.onSurface : Colors.transparent,
        shape: StadiumBorder(
          side: filled ? BorderSide.none : BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: filled ? 16 : 15,
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
    );
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: expand
          ? pill
          : Align(alignment: AlignmentDirectional.centerStart, child: pill),
    );
  }
}
