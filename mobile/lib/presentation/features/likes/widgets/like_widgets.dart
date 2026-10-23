import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/mazl_components.dart';

/// Carte d'un like visible (compte premium) : photo, « Prénom, âge » en bas à
/// gauche et, si fournies, les actions passer / aimer sous la photo.
class LikeCard extends StatelessWidget {
  const LikeCard({
    super.key,
    required this.name,
    this.age,
    this.pictureUrl,
    this.isVerified = false,
    this.seed = 0,
    this.photoHeight = 200,
    required this.onTap,
    this.onLike,
    this.onPass,
  });

  /// Hauteur de la rangée d'actions + son espacement, à ajouter à la photo.
  static const double actionsExtent = 52;

  final String name;
  final int? age;
  final String? pictureUrl;
  final bool isVerified;
  final int seed;
  final double photoHeight;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = age != null ? '$name, $age' : name;
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Voir le like de $title',
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: photoHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProfilePhoto(
                    url: pictureUrl,
                    seed: seed,
                    radius: 24,
                    iconSize: 40,
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.onSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
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
                              Icon(
                                LucideIcons.badgeCheck,
                                size: 14,
                                color: scheme.surface,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onLike != null && onPass != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundIconButton(
                icon: LucideIcons.x,
                tooltip: 'Passer $name',
                onPressed: onPass,
              ),
              const SizedBox(width: 12),
              RoundIconButton(
                icon: LucideIcons.heart,
                tooltip: 'Aimer $name',
                style: RoundButtonStyle.accent,
                onPressed: onLike,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tuile d'un like réservé aux abonnés : aplat brume et cadenas, jamais la
/// photo (elle n'est même pas chargée).
class LockedLikeTile extends StatelessWidget {
  const LockedLikeTile({super.key, required this.onTap, this.height = 120});

  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Profil masqué',
      hint: 'Disponible avec mazl+',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Icon(
              LucideIcons.lock,
              size: 24,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton en contour qui renvoie vers l'abonnement : « … avec mazl+ », où
/// « mazl » est en gras et le « + » en tekhelet.
class MazlPlusPill extends StatelessWidget {
  const MazlPlusPill({
    super.key,
    required this.prefix,
    required this.onPressed,
  });

  /// Texte qui précède « mazl+ », espace final compris : « Voir les 8 autres avec ».
  final String prefix;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${prefix}mazl+',
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Text.rich(
            TextSpan(
              text: prefix,
              children: [
                const TextSpan(
                  text: 'mazl',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '+',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
