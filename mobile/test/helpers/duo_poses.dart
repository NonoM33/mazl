import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/layout/side_safe_area.dart';

/// The poses of the foldable iPhone (iPhone Duo): window size in logical
/// points and safe-area padding, as measured on the iOS 27.1 simulator.
/// Closed is the outer display; the others are the inner one.
///
/// The status bar and the camera sit in an 84 pt column along ONE side when
/// the device is closed (right), held sideways or half open (right), and at
/// the top when it is open and upright.
enum DuoPose {
  closed(Size(466, 678), EdgeInsets.only(right: 84, bottom: 34)),
  openPortrait(Size(669, 951), EdgeInsets.only(top: 82, bottom: 34)),
  openLandscape(Size(951, 669), EdgeInsets.only(right: 84, bottom: 34)),

  /// Held like a book, half open: the fold runs down the middle.
  halfOpenBook(
    Size(951, 669),
    EdgeInsets.only(right: 84, bottom: 34),
    fold: Rect.fromLTWH(451, 0, 49, 669),
  ),

  /// Set on a table like a laptop, half open: the fold runs across the middle.
  halfOpenLaptop(
    Size(669, 951),
    EdgeInsets.only(top: 82, bottom: 34),
    fold: Rect.fromLTWH(0, 451, 669, 49),
  ),

  /// Half of the inner display, beside another app.
  splitView(Size(469, 669), EdgeInsets.only(bottom: 34));

  const DuoPose(this.size, this.padding, {this.fold});

  final Size size;
  final EdgeInsets padding;

  /// The active division region (the curve, margins included), in window
  /// coordinates. Only in the two half-open poses.
  final Rect? fold;

  FoldState get foldState => fold == null
      ? FoldState(
          hinge: this == closed ? HingeStatus.closed : HingeStatus.fullyOpen,
        )
      : FoldState(hinge: HingeStatus.partiallyOpen, divisions: [fold!]);

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
/// tappable element lies inside the safe area of [pose] and none touches its
/// fold. [reason] names the screen in the failure message.
void expectFitsDuoPose(WidgetTester tester, DuoPose pose, String reason) {
  final error = tester.takeException();
  expect(error, isNull, reason: '$reason in ${pose.name}: $error');
  for (final element in _tappables(tester)) {
    final box = element.renderObject! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final label =
        '$reason in ${pose.name}: ${element.widget.runtimeType} '
        'at $rect';
    expect(
      pose.safeRect.inflate(0.5).contains(rect.topLeft) &&
          pose.safeRect.inflate(0.5).contains(rect.bottomRight),
      isTrue,
      reason: '$label is outside the safe area ${pose.safeRect}',
    );
    if (pose.fold != null) {
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
