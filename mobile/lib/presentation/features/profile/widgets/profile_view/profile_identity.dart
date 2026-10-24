import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../common/widgets/mazl_components.dart';

/// Prénom, âge et ligne « Ville · à X km ».
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.name,
    required this.metaLine,
    this.age,
  });

  final String name;
  final int? age;
  final String metaLine;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: name,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.4,
              height: 1.05,
            ),
            children: [
              if (age != null)
                TextSpan(
                  text: '  $age',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.8,
                    color: muted,
                  ),
                ),
            ],
          ),
        ),
        if (metaLine.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(metaLine, style: TextStyle(fontSize: 14, color: muted)),
        ],
      ],
    );
  }
}

/// Statut de vérification. Touchable sur son propre profil, où il mène à
/// l'écran de vérification.
class ProfileVerificationTag extends StatelessWidget {
  const ProfileVerificationTag({
    super.key,
    required this.isVerified,
    this.level,
    this.onTap,
  });

  final bool isVerified;
  final String? level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = isVerified
        ? (level == 'verified_plus' ? 'Vérifié+' : 'Vérifié')
        : 'Vérifier mon profil';
    final tag = TagPill(
      label,
      icon: isVerified ? LucideIcons.badgeCheck : LucideIcons.shieldCheck,
    );
    if (onTap == null) return Align(alignment: Alignment.centerLeft, child: tag);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: isVerified ? 'Statut de vérification : $label' : label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(widthFactor: 1, child: tag),
          ),
        ),
      ),
    );
  }
}
