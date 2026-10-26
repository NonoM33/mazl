import 'package:flutter/widgets.dart';

import 'fold_state.dart';

/// Where the app's own bars go when the system uses a vertical bar.
///
/// On the foldable iPhone, closed or held sideways, iOS gathers its status
/// bar, its Dynamic Island AND the app's bars (tab bar, toolbar buttons, back
/// button) in one column along a side (84 pt), within reach of the thumb. A
/// system tab bar moves there by itself; a custom one (ours) must be put
/// there. Apple: the tab bar stays bottom aligned in that column, below the
/// system elements; only the inner display held upright keeps horizontal bars.
@immutable
class VerticalBarGeometry {
  const VerticalBarGeometry({
    required this.side,
    required this.strip,
    required this.controlsTop,
  });

  /// Room left above the app's controls, below the system elements.
  static const double gap = 12;

  /// Distance between the bottom of the app's controls and the screen edge.
  static const double bottomMargin = 24;

  /// Top of the column reserved for the system when it says nothing (iOS
  /// before 27.1 cannot, a test may not): the status cluster measured on the
  /// outer display is 174 pt tall, the highest of every pose.
  static const double fallbackReservedTop = 174;

  final VerticalBarSide side;

  /// The whole column, in window coordinates.
  final Rect strip;

  /// Where the app's controls may start: below every system element.
  final double controlsTop;

  /// The part of the column the app's controls may use.
  Rect get controls => Rect.fromLTRB(
    strip.left,
    controlsTop,
    strip.right,
    strip.bottom - bottomMargin,
  );

  /// The vertical bar of a window of [size] with [viewPadding], as the system
  /// reports it in [fold]; on iOS without a report, a one-sided column
  /// (no top inset, a single side inset of 60 pt or more) is taken for one.
  /// `null` when the bars are horizontal.
  static VerticalBarGeometry? resolve({
    required FoldState fold,
    required Size size,
    required EdgeInsets viewPadding,
    required TargetPlatform platform,
  }) {
    final side = fold.verticalBar ?? _guessSide(viewPadding, platform);
    if (side == null) return null;
    final width = side == VerticalBarSide.left
        ? viewPadding.left
        : viewPadding.right;
    if (width <= 0) return null;
    final strip = side == VerticalBarSide.left
        ? Rect.fromLTWH(0, 0, width, size.height)
        : Rect.fromLTWH(size.width - width, 0, width, size.height);
    final inStrip = fold.occlusions.where((rect) => rect.overlaps(strip));
    final reserved = inStrip.isEmpty
        ? fallbackReservedTop
        : inStrip.map((rect) => rect.bottom).reduce((a, b) => a > b ? a : b);
    return VerticalBarGeometry(
      side: side,
      strip: strip,
      controlsTop: reserved + gap,
    );
  }

  static VerticalBarSide? _guessSide(
    EdgeInsets padding,
    TargetPlatform platform,
  ) {
    if (platform != TargetPlatform.iOS || padding.top > 0) return null;
    const column = 60.0;
    if (padding.right >= column && padding.left == 0) {
      return VerticalBarSide.right;
    }
    if (padding.left >= column && padding.right == 0) {
      return VerticalBarSide.left;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is VerticalBarGeometry &&
      other.side == side &&
      other.strip == strip &&
      other.controlsTop == controlsTop;

  @override
  int get hashCode => Object.hash(side, strip, controlsTop);
}

/// What a screen puts in the vertical bar, and who put it there.
@immutable
class VerticalBarContent {
  const VerticalBarContent({required this.owner, required this.child});

  final Object owner;
  final Widget child;
}

/// The column of the vertical bar, for the screens below [SideSafeArea]:
/// whether there is one, where, and the slot where a screen puts its bar.
class VerticalBarScope extends InheritedWidget {
  const VerticalBarScope({
    super.key,
    required this.geometry,
    required this.slot,
    required super.child,
  });

  /// `null` when the bars are horizontal.
  final VerticalBarGeometry? geometry;
  final ValueNotifier<VerticalBarContent?> slot;

  static VerticalBarScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VerticalBarScope>();

  /// The vertical bar of the window, `null` when the bars are horizontal or
  /// outside a [SideSafeArea].
  static VerticalBarGeometry? geometryOf(BuildContext context) =>
      _of(context)?.geometry;

  static ValueNotifier<VerticalBarContent?>? slotOf(BuildContext context) =>
      _of(context)?.slot;

  @override
  bool updateShouldNotify(VerticalBarScope oldWidget) =>
      oldWidget.geometry != geometry || oldWidget.slot != slot;
}

/// Puts [bar] in the vertical bar while the screen around it is the one on
/// top (no page, sheet or dialog over it: like iOS, which hands the column to
/// the sheet's own controls), and takes it back otherwise. Draws nothing in
/// place.
class VerticalBarPublisher extends StatefulWidget {
  const VerticalBarPublisher({super.key, required this.bar});

  final Widget bar;

  @override
  State<VerticalBarPublisher> createState() => _VerticalBarPublisherState();
}

class _VerticalBarPublisherState extends State<VerticalBarPublisher> {
  ValueNotifier<VerticalBarContent?>? _slot;

  @override
  Widget build(BuildContext context) {
    final slot = VerticalBarScope.slotOf(context);
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    if (slot != _slot) _release();
    _slot = slot;
    // The slot is drawn by an ancestor: it changes after this frame, never
    // during its build.
    final content = onTop
        ? VerticalBarContent(owner: this, child: widget.bar)
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || slot == null) return;
      if (content != null) {
        slot.value = content;
      } else if (slot.value?.owner == this) {
        slot.value = null;
      }
    });
    return const SizedBox.shrink();
  }

  void _release() {
    final slot = _slot;
    if (slot == null || slot.value?.owner != this) return;
    // Never notify the slot's listeners while the tree is being torn down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (slot.value?.owner == this) slot.value = null;
    });
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }
}
