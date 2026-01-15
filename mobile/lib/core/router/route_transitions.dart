import 'package:flutter/material.dart';

/// Fade transition for smooth page changes
Widget fadeTransition(
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
Widget slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.0, 1.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  var offsetAnimation = animation.drive(tween);

  return SlideTransition(
    position: offsetAnimation,
    child: child,
  );
}

/// Slide left transition for navigation drill-down
Widget slideLeftTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  var offsetAnimation = animation.drive(tween);

  var fadeTween = Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: curve));
  var fadeAnimation = animation.drive(fadeTween);

  return FadeTransition(
    opacity: fadeAnimation,
    child: SlideTransition(
      position: offsetAnimation,
      child: child,
    ),
  );
}

/// Scale transition for focus/detail views
Widget scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const curve = Curves.easeOutCubic;

  var scaleTween =
      Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
  var scaleAnimation = animation.drive(scaleTween);

  var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
  var fadeAnimation = animation.drive(fadeTween);

  return FadeTransition(
    opacity: fadeAnimation,
    child: ScaleTransition(
      scale: scaleAnimation,
      child: child,
    ),
  );
}

/// Hero-like transition combining scale and fade
Widget heroTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const curve = Curves.easeOutCubic;

  var scaleTween =
      Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: curve));
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
Widget sharedAxisTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const curve = Curves.easeInOutCubic;

  // Outgoing page fades out and scales down slightly
  var secondaryFadeTween =
      Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: curve));
  var secondaryScaleTween =
      Tween(begin: 1.0, end: 0.95).chain(CurveTween(curve: curve));

  // Incoming page fades in and scales up
  var primaryFadeTween =
      Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
  var primaryScaleTween =
      Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: curve));

  return FadeTransition(
    opacity: animation.drive(primaryFadeTween),
    child: ScaleTransition(
      scale: animation.drive(primaryScaleTween),
      child: child,
    ),
  );
}
