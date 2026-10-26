import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'fold_state.dart';

/// How a page is cut by the fold of a half-open foldable iPhone.
enum FoldSplitAxis {
  /// The fold runs across the page (device set down like a laptop).
  horizontal,

  /// The fold runs down the page (device held like a book).
  vertical,
}

/// Where the fold cuts a box, in the box's own coordinates.
@immutable
class FoldCut {
  const FoldCut({
    required this.axis,
    required this.start,
    required this.gap,
    required this.leadExtent,
  });

  final FoldSplitAxis axis;

  /// Where the fold begins: from the box's left edge (fold down the page) or
  /// its top edge (fold across the page), whatever the reading direction.
  final double start;

  /// Extent of the fold region itself.
  final double gap;

  /// Extent of the part on the reading-start side: the top part, or the left
  /// part (the right one when reading right to left).
  final double leadExtent;

  /// Where the fold ends, from the same edge as [start].
  double get end => start + gap;

  /// Where [fold] (in the box's coordinates) cuts a box of [size], or `null`
  /// when it does not cross it with [minPane] points on both sides.
  static FoldCut? of(
    Rect fold,
    Size size,
    double minPane,
    TextDirection direction,
  ) {
    final box = Offset.zero & size;
    if (!fold.overlaps(box)) return null;
    if (fold.width >= fold.height) {
      final top = fold.top.clamp(0.0, size.height);
      final bottom = fold.bottom.clamp(0.0, size.height);
      if (top < minPane || size.height - bottom < minPane) return null;
      return FoldCut(
        axis: FoldSplitAxis.horizontal,
        start: top,
        gap: bottom - top,
        leadExtent: top,
      );
    }
    final left = fold.left.clamp(0.0, size.width);
    final right = fold.right.clamp(0.0, size.width);
    if (left < minPane || size.width - right < minPane) return null;
    return FoldCut(
      axis: FoldSplitAxis.vertical,
      start: left,
      gap: right - left,
      // The reading-start side is the right one in Hebrew.
      leadExtent: direction == TextDirection.rtl ? size.width - right : left,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FoldCut &&
      other.axis == axis &&
      other.start == start &&
      other.gap == gap &&
      other.leadExtent == leadExtent;

  @override
  int get hashCode => Object.hash(axis, start, gap, leadExtent);
}

/// Builds [builder] with where the fold of a half-open foldable iPhone cuts
/// this box, `null` when it does not (flat, closed, any other device, or a
/// fold closer than [minPaneExtent] to an edge).
///
/// The fold is reported in window coordinates: the box measures where it sits
/// after each frame while a fold is there, and builds again when that moves.
class FoldCutBuilder extends StatefulWidget {
  const FoldCutBuilder({
    super.key,
    required this.builder,
    this.minPaneExtent = 160,
  });

  final Widget Function(BuildContext context, FoldCut? cut) builder;
  final double minPaneExtent;

  @override
  State<FoldCutBuilder> createState() => _FoldCutBuilderState();
}

class _FoldCutBuilderState extends State<FoldCutBuilder> {
  Offset? _origin;

  void _measureOrigin(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    if (origin != _origin) setState(() => _origin = origin);
  }

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context).activeDivision;
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Re-measured whenever the fold or the room of the box changes.
        if (fold != null) {
          SchedulerBinding.instance.addPostFrameCallback(_measureOrigin);
        }
        final size = constraints.biggest;
        final cut = (fold == null || _origin == null || !size.isFinite)
            ? null
            : FoldCut.of(
                fold.shift(-_origin!),
                size,
                widget.minPaneExtent,
                direction,
              );
        return widget.builder(context, cut);
      },
    );
  }
}
