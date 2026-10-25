import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'fold_state.dart';

/// How a page is cut by the fold of a half-open foldable iPhone.
enum FoldSplitAxis {
  /// The fold runs across the page (device held like a laptop): [FoldAwareSplit.lead]
  /// above it, [FoldAwareSplit.action] below it, within reach and stable on a table.
  horizontal,

  /// The fold runs down the page (device held like a book): [FoldAwareSplit.lead]
  /// on the reading-start side, [FoldAwareSplit.action] on the other.
  vertical,
}

/// A page in two parts that the fold of a half-open display separates, as
/// Apple's guidance for the foldable iPhone asks: text and images move away
/// from the curve, interactive elements go to the bottom half (laptop pose)
/// or to a side (book pose), nothing interactive sits in the curve.
///
/// [lead] is glanceable content (title, explanation, progress); it is only
/// drawn while the page is split. [action] holds the fields and buttons and
/// is ALWAYS drawn: flat, it fills the page. It keeps its state across folds
/// (same element, reparented with a global key), so folding never loses what
/// the member typed. Below it, [FoldAwareSplit.axisOf] tells whether the page
/// is split, e.g. to leave out a header that [lead] already shows.
///
/// The page splits only when the fold crosses it with at least
/// [minPaneExtent] points on both sides; otherwise it stays flat.
class FoldAwareSplit extends StatefulWidget {
  const FoldAwareSplit({
    super.key,
    required this.lead,
    required this.action,
    this.minPaneExtent = 160,
  });

  final Widget lead;
  final Widget action;
  final double minPaneExtent;

  /// The split of the nearest [FoldAwareSplit] above [context], `null` when
  /// the page is flat or not inside one.
  static FoldSplitAxis? axisOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FoldSplitScope>()?.axis;

  @override
  State<FoldAwareSplit> createState() => _FoldAwareSplitState();
}

class _FoldAwareSplitState extends State<FoldAwareSplit> {
  final GlobalKey _actionKey = GlobalKey(debugLabel: 'fold-action');

  /// Where this page sits in the window, measured after each frame: the fold
  /// is reported in window coordinates.
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
        // Re-measured whenever the fold or the room of the page changes.
        if (fold != null) {
          SchedulerBinding.instance.addPostFrameCallback(_measureOrigin);
        }
        final size = constraints.biggest;
        final cut = (fold == null || _origin == null || !size.isFinite)
            ? null
            : _FoldCut.of(
                fold.shift(-_origin!),
                size,
                widget.minPaneExtent,
                direction,
              );
        final action = KeyedSubtree(key: _actionKey, child: widget.action);
        return _FoldSplitScope(
          axis: cut?.axis,
          child: switch (cut) {
            null => action,
            _FoldCut(axis: FoldSplitAxis.horizontal) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: cut.leadExtent, child: widget.lead),
                SizedBox(height: cut.gap),
                Expanded(child: action),
              ],
            ),
            _FoldCut(axis: FoldSplitAxis.vertical) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: cut.leadExtent, child: widget.lead),
                SizedBox(width: cut.gap),
                Expanded(child: action),
              ],
            ),
          },
        );
      },
    );
  }
}

/// Where the fold cuts a page of [size], in the page's own coordinates.
class _FoldCut {
  const _FoldCut(this.axis, this.leadExtent, this.gap);

  final FoldSplitAxis axis;

  /// Extent of the lead pane, from the page's start edge to the fold.
  final double leadExtent;

  /// Extent of the fold region itself.
  final double gap;

  static _FoldCut? of(
    Rect fold,
    Size size,
    double minPane,
    TextDirection direction,
  ) {
    final page = Offset.zero & size;
    if (!fold.overlaps(page)) return null;
    final runsAcross = fold.width >= fold.height;
    if (runsAcross) {
      final top = fold.top.clamp(0.0, size.height);
      final bottom = fold.bottom.clamp(0.0, size.height);
      if (top < minPane || size.height - bottom < minPane) return null;
      return _FoldCut(FoldSplitAxis.horizontal, top, bottom - top);
    }
    final left = fold.left.clamp(0.0, size.width);
    final right = fold.right.clamp(0.0, size.width);
    if (left < minPane || size.width - right < minPane) return null;
    // The lead pane is on the reading-start side: the right one in Hebrew.
    final leadExtent = direction == TextDirection.rtl
        ? size.width - right
        : left;
    return _FoldCut(FoldSplitAxis.vertical, leadExtent, right - left);
  }
}

class _FoldSplitScope extends InheritedWidget {
  const _FoldSplitScope({required this.axis, required super.child});

  final FoldSplitAxis? axis;

  @override
  bool updateShouldNotify(_FoldSplitScope oldWidget) => oldWidget.axis != axis;
}
