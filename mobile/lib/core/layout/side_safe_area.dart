import 'package:flutter/material.dart';

/// Keeps the whole app out of the side safe-area insets.
///
/// On the foldable iPhone the status bar and the camera live in a column
/// along one side (84 pt on the right of the outer display, closed; on the
/// right of the inner display held sideways or half open), not at the top.
/// Every screen, sheet, dialog and snackbar is drawn beside that column, so
/// no route can forget it. The column is filled with the page background:
/// nothing looks cut. Zero on a phone held upright, where the insets are
/// only at the top and the bottom, which each screen handles itself.
class SideSafeArea extends StatelessWidget {
  const SideSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(top: false, bottom: false, child: child),
  );
}
