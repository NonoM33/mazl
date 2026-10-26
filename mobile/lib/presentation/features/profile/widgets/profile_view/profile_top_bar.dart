import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/layout/bar_navigation.dart';
import '../../../../../core/layout/vertical_bar.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';

/// Rangée du haut : retour + options sur le profil d'un autre,
/// « Modifier » + réglages sur le sien.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar.other({
    super.key,
    required VoidCallback this.onBack,
    required VoidCallback this.onOptions,
  }) : isOwnProfile = false,
       onEdit = null,
       onSettings = null;

  const ProfileTopBar.own({
    super.key,
    required VoidCallback this.onEdit,
    required VoidCallback this.onSettings,
  }) : isOwnProfile = true,
       onBack = null,
       onOptions = null;

  final bool isOwnProfile;
  final VoidCallback? onBack;
  final VoidCallback? onOptions;
  final VoidCallback? onEdit;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) =>
      isOwnProfile ? _own(context) : _other(context);

  Widget _backButton(BuildContext context) => RoundIconButton(
    // « Retour » pointe vers la droite en hébreu.
    icon: Directionality.of(context) == TextDirection.rtl
        ? LucideIcons.chevronRight
        : LucideIcons.chevronLeft,
    tooltip: context.l10n.commonBack,
    onPressed: onBack,
  );

  Widget _optionsButton(BuildContext context) => RoundIconButton(
    icon: LucideIcons.ellipsis,
    tooltip: context.l10n.profileMoreOptions,
    onPressed: onOptions,
  );

  Widget _settingsButton(BuildContext context) => RoundIconButton(
    icon: LucideIcons.settings,
    tooltip: context.l10n.profileSettings,
    onPressed: onSettings,
  );

  /// Avec une colonne verticale (iPhone Duo), retour et options vont en haut
  /// de la colonne : rien ne se dessine ici.
  Widget _other(BuildContext context) => BarNavigation(
    buttons: [_backButton(context), _optionsButton(context)],
    inline: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_backButton(context), _optionsButton(context)],
      ),
    ),
  );

  /// « Modifier » reste sur place (un texte ne tient pas dans la colonne) ;
  /// les réglages, une icône, vont en haut de la colonne quand il y en a une.
  Widget _own(BuildContext context) {
    final inColumn = VerticalBarScope.geometryOf(context) != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
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
          if (inColumn)
            BarNavigation(
              buttons: [_settingsButton(context)],
              inline: const SizedBox.shrink(),
            )
          else ...[
            const SizedBox(width: 8),
            _settingsButton(context),
          ],
        ],
      ),
    );
  }
}
