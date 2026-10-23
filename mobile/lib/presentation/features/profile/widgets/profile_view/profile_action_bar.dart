import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../common/widgets/mazl_components.dart';

/// Rangée flottante du bas : passer, puis « J'aime » suivi du prénom.
class ProfileActionBar extends StatelessWidget {
  const ProfileActionBar({
    super.key,
    required this.firstName,
    required this.onPass,
    required this.onLike,
  });

  static const height = 64.0;

  final String firstName;
  final VoidCallback onPass;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = "J'aime $firstName";
    return Row(
      children: [
        RoundIconButton(
          icon: LucideIcons.x,
          tooltip: 'Passer',
          size: height,
          iconSize: 26,
          onPressed: onPass,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: SizedBox(
              height: height,
              child: Material(
                color: scheme.onSurface,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onLike,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            color: scheme.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.heart, size: 22, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
