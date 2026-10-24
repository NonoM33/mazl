import 'package:flutter/material.dart';

import '../layout/content_max_width.dart';
import '../motion/mazl_motion.dart';

// Every `xTransition` is the motion `xMotion` around a page kept in at most
// [kContentMaxWidth] points, centered: on a regular-width window (inner display
// of a foldable phone, tablet) a single-column screen keeps readable lines.
// A compact window is narrower than that and is not touched. The pages that
// are drawn by the tab shell on a regular window (AdaptiveDetailPage) use the
// bare motions.

/// Fade transition for smooth page changes. Under reduced motion every other
/// transition here becomes this one: no slide, no scale.
Widget fadeMotion(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}

/// Slide up transition for modals and bottom sheets style
Widget slideUpMotion(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MazlMotion.reduced(context)) {
    return fadeMotion(context, animation, secondaryAnimation, child);
  }

  const begin = Offset(0.0, 1.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  var offsetAnimation = animation.drive(tween);

  return SlideTransition(position: offsetAnimation, child: child);
}

/// Slide left transition for navigation drill-down
Widget slideLeftMotion(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MazlMotion.reduced(context)) {
    return fadeMotion(context, animation, secondaryAnimation, child);
  }

  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  var offsetAnimation = animation.drive(tween);

  var fadeTween = Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: curve));
  var fadeAnimation = animation.drive(fadeTween);

  return FadeTransition(
    opacity: fadeAnimation,
    child: SlideTransition(position: offsetAnimation, child: child),
  );
}

/// Scale transition for focus/detail views
Widget scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MazlMotion.reduced(context)) {
    return fadeMotion(context, animation, secondaryAnimation, child);
  }

  const curve = Curves.easeOutCubic;

  var scaleTween = Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
  var scaleAnimation = animation.drive(scaleTween);

  var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
  var fadeAnimation = animation.drive(fadeTween);

  return FadeTransition(
    opacity: fadeAnimation,
    child: ScaleTransition(scale: scaleAnimation, child: child),
  );
}

/// Hero-like transition combining scale and fade
Widget heroMotion(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MazlMotion.reduced(context)) {
    return fadeMotion(context, animation, secondaryAnimation, child);
  }

  const curve = Curves.easeOutCubic;

  var scaleTween = Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: curve));
  var scaleAnimation = animation.drive(scaleTween);

  var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
  var fadeAnimation = animation.drive(fadeTween);

  return FadeTransition(
    opacity: fadeAnimation,
    child: ScaleTransition(
      scale: scaleAnimation,
      alignment: Alignment.center,
      child: child,
    ),
  );
}

/// Shared axis transition (Material Design 3)
Widget sharedAxisMotion(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MazlMotion.reduced(context)) {
    return fadeMotion(context, animation, secondaryAnimation, child);
  }

  const curve = Curves.easeInOutCubic;

  // Outgoing page fades out and scales down slightly
  var secondaryFadeTween = Tween(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: curve));
  var secondaryScaleTween = Tween(
    begin: 1.0,
    end: 0.95,
  ).chain(CurveTween(curve: curve));

  // Incoming page fades in and scales up
  var primaryFadeTween = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: curve));
  var primaryScaleTween = Tween(
    begin: 1.05,
    end: 1.0,
  ).chain(CurveTween(curve: curve));

  return FadeTransition(
    opacity: animation.drive(primaryFadeTween),
    child: ScaleTransition(
      scale: animation.drive(primaryScaleTween),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(secondaryFadeTween),
        child: ScaleTransition(
          scale: secondaryAnimation.drive(secondaryScaleTween),
          child: child,
        ),
      ),
    ),
  );
}

Widget fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => fadeMotion(
  context,
  animation,
  secondaryAnimation,
  ContentMaxWidth(child: child),
);

Widget slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => slideUpMotion(
  context,
  animation,
  secondaryAnimation,
  ContentMaxWidth(child: child),
);

Widget slideLeftTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => slideLeftMotion(
  context,
  animation,
  secondaryAnimation,
  ContentMaxWidth(child: child),
);

Widget heroTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => heroMotion(
  context,
  animation,
  secondaryAnimation,
  ContentMaxWidth(child: child),
);

Widget sharedAxisTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => sharedAxisMotion(
  context,
  animation,
  secondaryAnimation,
  ContentMaxWidth(child: child),
);
