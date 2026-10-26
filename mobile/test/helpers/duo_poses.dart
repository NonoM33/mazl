import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/layout/side_safe_area.dart';
import 'package:mazl/core/layout/vertical_bar.dart';

/// The poses of the foldable iPhone (iPhone Duo): window size in logical
/// points and safe-area padding, as measured on the iOS 27.1 simulator with
/// Device Hub (Closed, Partially Open, Open, Rotate).
/// Closed is the outer display; the others are the inner one.
///
/// The status bar and the camera sit in an 84 pt column along ONE side when
/// the device is closed (right), held sideways or half open (right), and at
/// the top when it is open and upright.
enum DuoPose {
  closed(Size(466, 678), EdgeInsets.only(right: 84, bottom: 34)),

  /// Closed and turned sideways, standing on a table like a tent (outer
  /// display facing the room): the camera column is on the left.
  tent(Size(678, 466), EdgeInsets.only(left: 84, bottom: 34)),
  openPortrait(Size(669, 951), EdgeInsets.only(top: 82, bottom: 34)),
  openLandscape(Size(951, 669), EdgeInsets.only(right: 84, bottom: 34)),

  /// Held like a book, half open: the fold runs down the middle.
  halfOpenBook(
    Size(951, 669),
    EdgeInsets.only(right: 84, bottom: 34),
    fold: Rect.fromLTWH(455.5, 0, 40, 669),
  ),

  /// Set on a table like a laptop, half open: the fold runs across the middle.
  halfOpenLaptop(
    Size(669, 951),
    EdgeInsets.only(top: 82, bottom: 34),
    fold: Rect.fromLTWH(0, 455.5, 669, 40),
  ),

  /// Half of the inner display, beside another app.
  splitView(Size(469, 669), EdgeInsets.only(bottom: 34));

  const DuoPose(this.size, this.padding, {this.fold});

  final Size size;
  final EdgeInsets padding;

  /// The active division region (the curve, margins included), in window
  /// coordinates. Only in the two half-open poses.
  final Rect? fold;

  /// What the native side reports in this pose, as measured on the iOS 27.1
  /// simulator (Device Hub, 2026-10-26): the hinge, the fold (40 pt), the
  /// preferred edge of the vertical bar (reported even when the bars are
  /// horizontal) and the system's occlusions.
  FoldState get foldState {
    final hinge = fold != null
        ? HingeStatus.partiallyOpen
        : (this == closed || this == tent)
        ? HingeStatus.closed
        : HingeStatus.fullyOpen;
    final occlusions = switch (this) {
      closed => const [
        Rect.fromLTWH(399.7, 29.3, 37, 37),
        Rect.fromLTWH(382, 0, 84, 174),
      ],
      tent => const [
        Rect.fromLTWH(29.3, 29.3, 37, 37),
        Rect.fromLTWH(0, 0, 84, 82),
      ],
      openLandscape || halfOpenBook => const [Rect.fromLTWH(867, 0, 84, 124)],
      openPortrait || halfOpenLaptop => const [Rect.fromLTWH(0, 0, 124, 84)],
      splitView => const <Rect>[],
    };
    return FoldState(
      hinge: hinge,
      divisions: fold == null ? const [] : [fold!],
      verticalBar: this == splitView
          ? null
          : this == tent
          ? VerticalBarSide.left
          : VerticalBarSide.right,
      occlusions: occlusions,
      angle: hinge == HingeStatus.closed ? 0 : (fold == null ? 3.14159 : 1.9),
    );
  }

  /// The system's vertical bar in this pose, `null` when the bars are
  /// horizontal.
  VerticalBarGeometry? get verticalBar => VerticalBarGeometry.resolve(
    fold: foldState,
    size: size,
    viewPadding: padding,
    platform: TargetPlatform.iOS,
  );

  /// Where interactive elements may be: inside the safe area, out of the fold.
  Rect get safeRect => padding.deflateRect(Offset.zero & size);
}

/// Puts the test window in [pose] (3x display, like the device) and undoes it
/// at the end of the test.
void setDuoPose(WidgetTester tester, DuoPose pose) {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = pose.size * 3
    ..padding = FakeViewPadding(
      left: pose.padding.left * 3,
      top: pose.padding.top * 3,
      right: pose.padding.right * 3,
      bottom: pose.padding.bottom * 3,
    )
    ..viewPadding = FakeViewPadding(
      left: pose.padding.left * 3,
      top: pose.padding.top * 3,
      right: pose.padding.right * 3,
      bottom: pose.padding.bottom * 3,
    );
  addTearDown(tester.view.reset);
}

/// Wraps [app] the way `MazlApp` wraps every route: the fold of [pose]
/// reaches the screens and the side column of the status bar is kept clear.
/// Use it as `MaterialApp.builder`.
TransitionBuilder duoAppBuilder(ValueListenable<DuoPose> pose) =>
    (context, child) => ValueListenableBuilder<DuoPose>(
      valueListenable: pose,
      builder: (context, pose, _) => FoldScope(
        state: pose.foldState,
        child: SideSafeArea(child: child ?? const SizedBox.shrink()),
      ),
    );

/// Every element that reacts to a tap and is on screen.
Iterable<Element> _tappables(WidgetTester tester) => find
    .byWidgetPredicate(
      (widget) =>
          (widget is GestureDetector && widget.onTap != null) ||
          (widget is InkWell && widget.onTap != null) ||
          widget is EditableText ||
          widget is Slider ||
          widget is RangeSlider,
    )
    .hitTestable()
    .evaluate();

/// No overflow was reported while the screen laid out in [pose], every
/// tappable element lies inside the safe area of [pose] (or in the app's part
/// of the system's vertical bar), none is under a system element, and none
/// outside a scrolling list touches the fold. [reason] names the screen in the
/// failure message.
void expectFitsDuoPose(WidgetTester tester, DuoPose pose, String reason) {
  final error = tester.takeException();
  expect(error, isNull, reason: '$reason in ${pose.name}: $error');
  final bar = pose.verticalBar?.controls;
  for (final element in _tappables(tester)) {
    final box = element.renderObject! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final label =
        '$reason in ${pose.name}: ${element.widget.runtimeType} '
        'at $rect';
    bool inside(Rect area) =>
        area.inflate(0.5).contains(rect.topLeft) &&
        area.inflate(0.5).contains(rect.bottomRight);
    // The app's bars may also sit in the system's vertical bar, below the
    // status bar and the Dynamic Island.
    expect(
      inside(pose.safeRect) || (bar != null && inside(bar)),
      isTrue,
      reason:
          '$label is outside the safe area ${pose.safeRect}'
          '${bar == null ? '' : ' and the vertical bar $bar'}',
    );
    for (final occluded in pose.foldState.occlusions) {
      expect(
        rect.overlaps(occluded),
        isFalse,
        reason: '$label is under the system at $occluded',
      );
    }
    // Apple: keep interactive elements out of the curve; scrolling content
    // does not need to avoid it (the member scrolls it out of the way).
    final scrolls = element.findAncestorWidgetOfExactType<Scrollable>() != null;
    if (pose.fold != null && !scrolls) {
      expect(
        rect.overlaps(pose.fold!),
        isFalse,
        reason: '$label touches the fold ${pose.fold}',
      );
    }
  }
}

/// Lets a pending fold measurement settle (one post-frame pass).
Future<void> settleFold(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// A notifier for [duoAppBuilder] that tests move from pose to pose.
class DuoPoseController extends ValueNotifier<DuoPose> {
  DuoPoseController(super.value);

  /// Moves the window and the fold to [pose] in one step, like folding.
  Future<void> moveTo(WidgetTester tester, DuoPose pose) async {
    setDuoPose(tester, pose);
    value = pose;
    await settleFold(tester);
  }
}
