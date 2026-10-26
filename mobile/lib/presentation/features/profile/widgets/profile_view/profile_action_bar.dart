import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../l10n/l10n.dart';

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
    final label = context.l10n.profileLikeName(firstName);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              key: const ValueKey('profile-decline'),
              onPressed: onPass,
              // The bar floats over the scrolling profile: an opaque fill,
              // or the text scrolling underneath shows through the word.
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: scheme.surfaceContainerHigh,
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(
                context.l10n.profileDecline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
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
