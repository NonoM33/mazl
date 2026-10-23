import 'package:flutter/material.dart';

/// The only way to open a bottom sheet in the app.
///
/// - On the ROOT navigator: a sheet opened from a tab must cover the floating
///   tab bar. Flutter's default is the nearest navigator, i.e. the tab's own,
///   which draws the sheet inside the page, under the bar.
/// - Frame from the theme (paper background, top radius 28, one 36x5 hairline
///   drag handle): the content never draws its own background, corners or
///   handle, otherwise the handle appears twice.
/// - Content padded 24, above the keyboard and the home indicator.
///
/// `test/features/design/sheet_rules_test.dart` refuses any other call.
Future<T?> showMazlSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool padded = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    barrierColor: barrierColor,
    builder: (sheetContext) => MazlSheetBody(padded: padded, child: builder(sheetContext)),
  );
}

/// Keeps the content above the keyboard and the home indicator, with the
/// design system's padding. [padded] false is for full-bleed lists of tiles,
/// which carry their own horizontal padding.
class MazlSheetBody extends StatelessWidget {
  const MazlSheetBody({super.key, required this.child, this.padded = true});

  static const padding = 24.0;

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padded
              ? const EdgeInsets.fromLTRB(padding, 0, padding, padding)
              : const EdgeInsets.only(bottom: padding / 2),
          child: child,
        ),
      ),
    );
  }
}
