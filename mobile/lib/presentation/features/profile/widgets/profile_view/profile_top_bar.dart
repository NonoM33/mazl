import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../common/widgets/mazl_components.dart';

/// Rangée du haut : retour + options sur le profil d'un autre,
/// « Modifier » + réglages sur le sien.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar.other({
    super.key,
    required VoidCallback this.onBack,
    required VoidCallback this.onOptions,
  })  : isOwnProfile = false,
        onEdit = null,
        onSettings = null;

  const ProfileTopBar.own({
    super.key,
    required VoidCallback this.onEdit,
    required VoidCallback this.onSettings,
  })  : isOwnProfile = true,
        onBack = null,
        onOptions = null;

  final bool isOwnProfile;
  final VoidCallback? onBack;
  final VoidCallback? onOptions;
  final VoidCallback? onEdit;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: isOwnProfile ? _own() : _other(),
    );
  }

  Widget _other() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Retour',
            onPressed: onBack,
          ),
          RoundIconButton(
            icon: LucideIcons.ellipsis,
            tooltip: "Plus d'options",
            onPressed: onOptions,
          ),
        ],
      );

  Widget _own() => Row(
        children: [
          const SectionLabel('Mon profil'),
          const Spacer(),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Modifier'),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: LucideIcons.settings,
            tooltip: 'Réglages',
            onPressed: onSettings,
          ),
        ],
      );
}
