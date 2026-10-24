import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../l10n/l10n.dart';
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
      child: isOwnProfile ? _own(context) : _other(context),
    );
  }

  Widget _other(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundIconButton(
            // « Retour » pointe vers la droite en hébreu.
            icon: Directionality.of(context) == TextDirection.rtl
                ? LucideIcons.chevronRight
                : LucideIcons.chevronLeft,
            tooltip: context.l10n.commonBack,
            onPressed: onBack,
          ),
          RoundIconButton(
            icon: LucideIcons.ellipsis,
            tooltip: context.l10n.profileMoreOptions,
            onPressed: onOptions,
          ),
        ],
      );

  Widget _own(BuildContext context) => Row(
        children: [
          SectionLabel(context.l10n.profileMyProfile),
          const Spacer(),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(context.l10n.profileEdit),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: LucideIcons.settings,
            tooltip: context.l10n.profileSettings,
            onPressed: onSettings,
          ),
        ],
      );
}
