import 'package:flutter/widgets.dart';

import 'fold_cut.dart';

export 'fold_cut.dart' show FoldSplitAxis;

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

  @override
  Widget build(BuildContext context) => FoldCutBuilder(
    minPaneExtent: widget.minPaneExtent,
    builder: (context, cut) {
      final action = KeyedSubtree(key: _actionKey, child: widget.action);
      return _FoldSplitScope(
        axis: cut?.axis,
        child: switch (cut?.axis) {
          null => action,
          FoldSplitAxis.horizontal => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: cut!.leadExtent, child: widget.lead),
              SizedBox(height: cut.gap),
              Expanded(child: action),
            ],
          ),
          FoldSplitAxis.vertical => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: cut!.leadExtent, child: widget.lead),
              SizedBox(width: cut.gap),
              Expanded(child: action),
            ],
          ),
        },
      );
    },
  );
}

class _FoldSplitScope extends InheritedWidget {
  const _FoldSplitScope({required this.axis, required super.child});

  final FoldSplitAxis? axis;

  @override
  bool updateShouldNotify(_FoldSplitScope oldWidget) => oldWidget.axis != axis;
}
