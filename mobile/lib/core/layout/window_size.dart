import 'package:flutter/widgets.dart';

/// How much room the app window has, in Apple's two size classes.
///
/// The layout follows the WIDTH of the window and nothing else: not the
/// orientation, not the device, not the pose. On the foldable iPhone the outer
/// display is compact and the inner display is regular; Split View on the
/// inner display or a narrow iPad window fall back to compact by themselves.
enum WindowSizeClass { compact, regular }

/// The ONE breakpoint of the app: logical points of width from which the
/// layout switches from compact to regular.
///
/// 600 is the compact/medium limit of Material's window size classes. It
/// falls between the widths the foldable iPhone is measured at (outer display
/// about 466 pt, inner display about 669 pt) with room on both sides, keeps
/// every regular iPhone in portrait (<= 440 pt) compact, and keeps half of
/// the inner display in Split View (about 334 pt) compact.
const double kRegularMinWidth = 600;

WindowSizeClass windowSizeClassForWidth(double width) =>
    width >= kRegularMinWidth
    ? WindowSizeClass.regular
    : WindowSizeClass.compact;

WindowSizeClass windowSizeClassOf(BuildContext context) =>
    windowSizeClassForWidth(MediaQuery.sizeOf(context).width);

bool isRegularWidth(BuildContext context) =>
    windowSizeClassOf(context) == WindowSizeClass.regular;
