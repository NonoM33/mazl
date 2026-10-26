import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'fold_state.dart';

/// The actions anchored at the bottom of a screen (a main button, a row of
/// buttons), kept out of the fold of a half-open foldable iPhone.
///
/// Held like a book, the fold runs down the middle: a full-width button would
/// cross the curve. The actions then take one side of it, the one nearer the
/// thumb that holds the device (the side of the system's vertical bar, else
/// the wider side), and keep their full height. Laid flat like a laptop the
/// fold is above the bottom of the screen and nothing moves. On any other
/// window this is just [child].
class FoldSafeActions extends StatefulWidget {
  const FoldSafeActions({
    super.key,
    required this.child,
    this.minSideWidth = 200,
  });

  final Widget child;

  /// The narrowest side the actions accept; below it they stay full width.
  final double minSideWidth;

  @override
  State<FoldSafeActions> createState() => _FoldSafeActionsState();
}

class _FoldSafeActionsState extends State<FoldSafeActions> {
  Rect? _bounds;

  void _measure(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    if (bounds != _bounds) setState(() => _bounds = bounds);
  }

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context);
    final division = fold.activeDivision;
    if (division != null) {
      SchedulerBinding.instance.addPostFrameCallback(_measure);
    }
    final bounds = _bounds;
    final runsDown = division != null && division.height > division.width;
    if (!runsDown || bounds == null || !division.overlaps(bounds)) {
      return widget.child;
    }
    final leftRoom = (division.left - bounds.left).clamp(0.0, bounds.width);
    final rightRoom = (bounds.right - division.right).clamp(0.0, bounds.width);
    final preferRight = switch (fold.verticalBar) {
      VerticalBarSide.right => rightRoom >= widget.minSideWidth,
      VerticalBarSide.left => leftRoom < widget.minSideWidth,
      null => rightRoom >= leftRoom,
    };
    if (preferRight && rightRoom >= widget.minSideWidth) {
      return Padding(
        padding: EdgeInsets.only(left: bounds.width - rightRoom),
        child: widget.child,
      );
    }
    if (leftRoom >= widget.minSideWidth) {
      return Padding(
        padding: EdgeInsets.only(right: bounds.width - leftRoom),
        child: widget.child,
      );
    }
    return widget.child;
  }
}
