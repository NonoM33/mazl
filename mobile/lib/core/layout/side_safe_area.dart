import 'package:flutter/material.dart';

import 'fold_state.dart';
import 'vertical_bar.dart';

/// Keeps the whole app out of the side safe-area insets, and opens the
/// vertical bar to the screen that owns it.
///
/// On the foldable iPhone the status bar and the camera live in a column
/// along one side (84 pt on the right of the outer display, closed; on the
/// right of the inner display held sideways or half open), not at the top.
/// Every screen, sheet, dialog and snackbar is drawn beside that column, so
/// no route can forget it. The column is filled with the page background:
/// nothing looks cut. Zero on a phone held upright, where the insets are
/// only at the top and the bottom, which each screen handles itself.
///
/// That column is also where iOS wants the app's own bars, below the system
/// elements ([VerticalBarGeometry]): the screen on top puts its bar in the
/// slot of [VerticalBarScope] (see [VerticalBarPublisher]) and this widget
/// draws it there, the only place outside the safe area where the app draws
/// something tappable.
class SideSafeArea extends StatefulWidget {
  const SideSafeArea({super.key, required this.child});

  final Widget child;

  @override
  State<SideSafeArea> createState() => _SideSafeAreaState();
}

class _SideSafeAreaState extends State<SideSafeArea> {
  final ValueNotifier<VerticalBarContent?> _slot = ValueNotifier(null);

  @override
  void dispose() {
    // A publisher below may still release the slot after this frame.
    final slot = _slot;
    WidgetsBinding.instance.addPostFrameCallback((_) => slot.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bar = VerticalBarGeometry.resolve(
      fold: FoldScope.of(context),
      size: media.size,
      viewPadding: media.viewPadding,
      platform: Theme.of(context).platform,
    );
    final duration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return VerticalBarScope(
      geometry: bar,
      slot: _slot,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          SafeArea(top: false, bottom: false, child: widget.child),
          if (bar != null)
            Positioned.fromRect(
              rect: bar.controls,
              child: Material(
                type: MaterialType.transparency,
                child: ValueListenableBuilder<VerticalBarContent?>(
                  valueListenable: _slot,
                  builder: (context, content, _) => AnimatedSwitcher(
                    duration: duration,
                    child: content == null
                        ? const SizedBox.expand()
                        : KeyedSubtree(
                            key: ObjectKey(content.owner),
                            child: content.child,
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
