import 'package:flutter/widgets.dart';

import 'vertical_bar.dart';

/// The navigation of a screen: back or close first, then its actions.
///
/// With a vertical bar (the foldable iPhone closed, sideways or held like a
/// book), the buttons go to the top of the column, under the status bar, one
/// below the other in that order, as iOS does with a navigation bar: within
/// reach of the thumb that holds the device. Without one, the screen draws
/// [inline] where it always did (usually its top-left corner).
class BarNavigation extends StatelessWidget {
  const BarNavigation({super.key, required this.buttons, required this.inline});

  /// In order: navigation (back, close), main action, other buttons.
  final List<Widget> buttons;

  /// How the screen draws the same buttons without a vertical bar.
  final Widget inline;

  /// Space between two buttons in the column (Apple: 12 pt).
  static const gap = 12.0;

  /// Height of each button's row: an icon button takes all the height it is
  /// given (BackButton grows to the column's), so each one gets Apple's 48.
  static const rowExtent = 48.0;

  @override
  Widget build(BuildContext context) {
    if (VerticalBarScope.geometryOf(context) == null) return inline;
    return VerticalBarPublisher(
      navigation: true,
      bar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            SizedBox(
              height: rowExtent,
              child: Center(child: buttons[i]),
            ),
          ],
        ],
      ),
    );
  }
}
