import 'package:flutter/material.dart';

import '../../../common/widgets/mazl_components.dart';

/// Pastille ronde d'un match : anneau tekhelet quand il est récent, filet
/// gris sinon, prénom dessous. Touche pour ouvrir la conversation.
class AvatarRing extends StatelessWidget {
  const AvatarRing({
    super.key,
    required this.name,
    this.pictureUrl,
    this.seed = 0,
    this.isNew = false,
    this.onTap,
  });

  static const double size = 68;

  final String name;
  final String? pictureUrl;
  final int seed;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = isNew ? scheme.primary : scheme.outline;
    return Semantics(
      button: true,
      label: isNew ? 'Nouveau match, $name' : 'Match, $name',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const ValueKey('avatar-ring'),
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
                child: ProfilePhoto(
                  url: pictureUrl,
                  seed: seed,
                  radius: size,
                  iconSize: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
