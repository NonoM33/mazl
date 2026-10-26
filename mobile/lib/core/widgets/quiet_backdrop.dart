import 'package:flutter/material.dart';

import '../services/quiet_display.dart';
import '../theme/app_colors.dart';

/// While the Shabbat display is on, paints the page background of the whole
/// app in its night: the side column of the foldable iPhone (camera and status
/// bar), which the app fills with the theme's page background, would otherwise
/// stay as bright as the day beside a dark screen.
///
/// The widget tree below never changes shape (the theme is always provided),
/// so the navigation stack and every screen keep their state.
class QuietBackdrop extends StatelessWidget {
  const QuietBackdrop({super.key, this.quiet, required this.child});

  /// The app's own by default.
  final QuietDisplay? quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final listenable = (quiet ?? QuietDisplay.instance).listenable;
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      child: child,
      builder: (context, on, child) {
        final theme = Theme.of(context);
        return Theme(
          data: on
              ? theme.copyWith(
                  scaffoldBackgroundColor: AppColors.shabbatDisplayBackground,
                )
              : theme,
          child: child!,
        );
      },
    );
  }
}
