import 'package:flutter/widgets.dart';

/// Folds the iPhone's « Réduire les animations » into
/// [MediaQueryData.disableAnimations] for everything below it.
///
/// Flutter does not set `disableAnimations` from that iOS setting: it exposes
/// it separately, as `AccessibilityFeatures.reduceMotion`. Placed at the app
/// root, this makes every widget that honours `disableAnimations` (ours
/// through [MazlMotion.reduced], and Flutter's own) follow the setting, and
/// follow it again when it changes while the app runs.
class ReduceMotionScope extends StatefulWidget {
  const ReduceMotionScope({super.key, required this.child});

  final Widget child;

  @override
  State<ReduceMotionScope> createState() => _ReduceMotionScopeState();
}

class _ReduceMotionScopeState extends State<ReduceMotionScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // MediaQuery does not change when only reduceMotion does: listen ourselves.
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = View.of(
      context,
    ).platformDispatcher.accessibilityFeatures.reduceMotion;
    if (!reduceMotion || media.disableAnimations) return widget.child;
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: widget.child,
    );
  }
}
