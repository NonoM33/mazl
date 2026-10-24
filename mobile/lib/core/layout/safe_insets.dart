import 'package:flutter/widgets.dart';

/// The horizontal safe-area insets by reading side instead of by screen side.
///
/// The system reports `left` and `right`; the layout speaks `start` and `end`
/// so that it flips with the language (right to left in Hebrew). The two
/// insets can differ: never assume `start == end`.
extension SafeInsetsByDirection on EdgeInsets {
  double startFor(TextDirection direction) => direction == TextDirection.rtl ? right : left;

  double endFor(TextDirection direction) => direction == TextDirection.rtl ? left : right;
}
