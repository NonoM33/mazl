import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// The bookmark of an activity: outlined when it is not saved, on the accent
/// when it is. The whole [size] x [size] circle is the control.
class OutingSaveButton extends StatelessWidget {
  const OutingSaveButton({
    super.key,
    required this.saved,
    required this.onPressed,
    this.size = 44,
  });

  final bool saved;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RoundIconButton(
      icon: saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
      tooltip: saved ? l10n.coupleOutingsUnsave : l10n.coupleOutingsSave,
      style: saved ? RoundButtonStyle.accent : RoundButtonStyle.outline,
      size: size,
      iconSize: size >= 48 ? 22 : 20,
      onPressed: onPressed,
    );
  }
}
