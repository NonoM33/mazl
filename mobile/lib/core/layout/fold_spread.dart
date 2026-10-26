import 'package:flutter/widgets.dart';

import 'fold_cut.dart';

/// A scrolling page that reads like a book when the foldable iPhone is held
/// half open: [start] on the reading-start page, [end] on the other, each
/// scrolling on its own, nothing in the curve between them.
///
/// Anywhere else (flat, closed, laptop pose, any other device) it is one list
/// of [start] then [end]: a list that scrolls across a fold moves its rows out
/// of the curve. Each child keeps its state when the device folds or unfolds
/// (same element, reparented with a global key), as long as it is built.
class FoldSpread extends StatefulWidget {
  const FoldSpread({
    super.key,
    required this.start,
    required this.end,
    this.padding = EdgeInsets.zero,
    this.minPaneExtent = 240,
  });

  final List<Widget> start;
  final List<Widget> end;

  /// Around the single list, and around each page of the book.
  final EdgeInsetsGeometry padding;

  /// The narrowest page the book accepts; below it the list stays single.
  final double minPaneExtent;

  @override
  State<FoldSpread> createState() => _FoldSpreadState();
}

class _FoldSpreadState extends State<FoldSpread> {
  final List<GlobalKey> _keys = [];

  List<Widget> _keyed(List<Widget> children, int offset) {
    while (_keys.length < offset + children.length) {
      _keys.add(GlobalKey(debugLabel: 'fold-spread-${_keys.length}'));
    }
    return [
      for (var i = 0; i < children.length; i++)
        KeyedSubtree(key: _keys[offset + i], child: children[i]),
    ];
  }

  @override
  Widget build(BuildContext context) => FoldCutBuilder(
    minPaneExtent: widget.minPaneExtent,
    builder: (context, cut) {
      final start = _keyed(widget.start, 0);
      final end = _keyed(widget.end, widget.start.length);
      if (cut?.axis != FoldSplitAxis.vertical) {
        return ListView(padding: widget.padding, children: [...start, ...end]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: cut!.leadExtent,
            child: ListView(padding: widget.padding, children: start),
          ),
          SizedBox(width: cut.gap),
          Expanded(
            child: ListView(padding: widget.padding, children: end),
          ),
        ],
      );
    },
  );
}
