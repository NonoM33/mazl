import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/l10n/l10n.dart';

/// Turns the iPhone's « Réduire les animations » on or off the way iOS does:
/// through the engine's accessibility flag, folded into `disableAnimations`
/// by [ReduceMotionScope] (see reduce_motion_scope_test.dart). Cleared after
/// the test.
void setReduceMotion(WidgetTester tester, {required bool on}) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// A [MaterialApp] whose subtree sees the iPhone setting, like the real app.
MaterialApp reduceMotionApp({Widget? home}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, child) => ReduceMotionScope(child: child!),
  home: home,
);

/// What visibly moves, turns or scales [target] at this very frame: one line
/// per ancestor that is not at rest. Empty when [target] stands still.
List<String> displacementsOf(Finder target) {
  final found = <String>[];
  final ancestors = find.ancestor(
    of: target,
    matching: find.byWidgetPredicate((_) => true),
  );
  for (final element in ancestors.evaluate()) {
    final widget = element.widget;
    if (widget is ScaleTransition && widget.scale.value != 1) {
      found.add('ScaleTransition ${widget.scale.value}');
    } else if (widget is SlideTransition &&
        widget.position.value != Offset.zero) {
      found.add('SlideTransition ${widget.position.value}');
    } else if (widget is RotationTransition && widget.turns.value != 0) {
      found.add('RotationTransition ${widget.turns.value}');
    } else if (widget is FractionalTranslation &&
        widget.translation != Offset.zero) {
      found.add('FractionalTranslation ${widget.translation}');
    } else if (widget is Transform && !widget.transform.isIdentity()) {
      found.add('Transform ${widget.transform}');
    }
  }
  return found;
}

/// The lowest opacity among the fades above [target] (1 when none).
double fadeOf(Finder target) {
  var opacity = 1.0;
  final ancestors = find.ancestor(
    of: target,
    matching: find.byWidgetPredicate((_) => true),
  );
  for (final element in ancestors.evaluate()) {
    final widget = element.widget;
    final value = switch (widget) {
      FadeTransition() => widget.opacity.value,
      Opacity() => widget.opacity,
      _ => 1.0,
    };
    if (value < opacity) opacity = value;
  }
  return opacity;
}

/// Every displacement seen on [target] over the next 700 ms, frame by frame.
/// For flutter_animate blocks, which start on a timer a few frames late: one
/// sample would pass for the wrong reason.
Future<Set<String>> displacementsWhilePlaying(
  WidgetTester tester,
  Finder target,
) async {
  final seen = <String>{};
  for (var frame = 0; frame < 44; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    seen.addAll(displacementsOf(target));
  }
  return seen;
}
