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
    required this.passThrough,
    this.navigationSlot,
    required super.child,
  });

  /// `null` when the bars are horizontal.
  final VerticalBarGeometry? geometry;
  final ValueNotifier<VerticalBarContent?> slot;

  /// The top of the column: the navigation of the screen on top (back or
  /// close first, then its actions), as iOS puts a navigation bar there.
  final ValueNotifier<VerticalBarContent?>? navigationSlot;

  /// The see-through route on top, if any ([VerticalBarPassThrough]).
  final ValueNotifier<Object?> passThrough;

  static VerticalBarScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VerticalBarScope>();

  /// The vertical bar of the window, `null` when the bars are horizontal or
  /// outside a [SideSafeArea].
  static VerticalBarGeometry? geometryOf(BuildContext context) =>
      _of(context)?.geometry;

  static ValueNotifier<VerticalBarContent?>? slotOf(BuildContext context) =>
      _of(context)?.slot;

  static ValueNotifier<VerticalBarContent?>? navigationSlotOf(
    BuildContext context,
  ) => _of(context)?.navigationSlot;

  static ValueNotifier<Object?>? passThroughOf(BuildContext context) =>
      _of(context)?.passThrough;

  @override
  bool updateShouldNotify(VerticalBarScope oldWidget) =>
      oldWidget.geometry != geometry ||
      oldWidget.slot != slot ||
      oldWidget.navigationSlot != navigationSlot ||
      oldWidget.passThrough != passThrough;
}

/// Puts [bar] in the vertical bar while the screen around it is the one on
/// top (no page, sheet or dialog over it: like iOS, which hands the column to
/// the sheet's own controls), and takes it back otherwise. Draws nothing in
/// place.
class VerticalBarPublisher extends StatefulWidget {
  const VerticalBarPublisher({
    super.key,
    required this.bar,
    this.navigation = false,
  });

  final Widget bar;

  /// Into the top of the column (the screen's navigation) rather than the
  /// bottom (its tabs).
  final bool navigation;

  @override
  State<VerticalBarPublisher> createState() => _VerticalBarPublisherState();
}

class _VerticalBarPublisherState extends State<VerticalBarPublisher> {
  ValueNotifier<VerticalBarContent?>? _slot;
  ValueNotifier<Object?>? _passThrough;

  void _onPassThrough() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final passThrough = VerticalBarScope.passThroughOf(context);
    if (passThrough == _passThrough) return;
    _passThrough?.removeListener(_onPassThrough);
    _passThrough = passThrough?..addListener(_onPassThrough);
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.navigation
        ? VerticalBarScope.navigationSlotOf(context)
        : VerticalBarScope.slotOf(context);
    // Covered only by a see-through route (a detail drawn in this screen's
    // pane), the screen is still the one the user acts on.
    // A tab kept alive offstage (its ticker mode off) never publishes over
    // the tab on screen.
    final onTop =
        TickerMode.valuesOf(context).enabled &&
        ((ModalRoute.isCurrentOf(context) ?? true) ||
            _passThrough?.value != null);
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
    _passThrough?.removeListener(_onPassThrough);
    _release();
    super.dispose();
  }
}

/// Marks a route that draws nothing of its own and lets the screen below show
/// it (a detail opened in the tab shell's pane): while that route is the one
/// on top, the screen below keeps its vertical bar. A dialog or a page over
/// it takes the bar back, as over any screen. Draws nothing.
class VerticalBarPassThrough extends StatefulWidget {
  const VerticalBarPassThrough({super.key});

  @override
  State<VerticalBarPassThrough> createState() => _VerticalBarPassThroughState();
}

class _VerticalBarPassThroughState extends State<VerticalBarPassThrough> {
  ValueNotifier<Object?>? _passThrough;

  @override
  Widget build(BuildContext context) {
    final passThrough = VerticalBarScope.passThroughOf(context);
    if (passThrough != _passThrough) _release();
    _passThrough = passThrough;
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    // The publisher below rebuilds on this change: never during this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || passThrough == null) return;
      if (onTop) {
        passThrough.value = this;
      } else if (passThrough.value == this) {
        passThrough.value = null;
      }
    });
    return const SizedBox.shrink();
  }

  void _release() {
    final passThrough = _passThrough;
    if (passThrough == null || passThrough.value != this) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (passThrough.value == this) passThrough.value = null;
    });
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }
}
