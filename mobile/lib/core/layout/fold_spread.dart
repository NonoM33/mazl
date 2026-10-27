import 'package:flutter/widgets.dart';

import 'fold_cut.dart';

/// A scrolling page that reads like a book when the foldable iPhone is held
/// half open: [start] on the reading-start page, [end] on the other, each
/// scrolling on its own, nothing in the curve between them.
///
/// Anywhere else (flat, closed, laptop pose, any other device) it is one list
/// of [start] then [end]: a list that scrolls across a fold moves its rows out
/// of the curve. A page that asks for it with [wideFrom] puts the two side by
/// side on any window that wide, fold or not. Each child keeps its state when
/// the device folds or unfolds (same element, reparented with a global key),
/// as long as it is built.
/// The breathing room kept where a volet meets the fold.
const double _voletGap = 12;

class FoldSpread extends StatefulWidget {
  const FoldSpread({
    super.key,
    required this.start,
    required this.end,
    this.padding = EdgeInsets.zero,
    this.minPaneExtent = 240,
    this.wideFrom,
    this.laptopVolets = false,
  });

  final List<Widget> start;
  final List<Widget> end;

  /// Around the single list, and around each page of the book.
  final EdgeInsetsGeometry padding;

  /// The narrowest page the book accepts; below it the list stays single.
  final double minPaneExtent;

  /// From this width on, with no fold to split it, the page is also two lists
  /// side by side ([start] then [end], in the reading direction). `null`
  /// (the default): a single list whatever the width.
  final double? wideFrom;

  /// Set down like a laptop (the fold runs across the page), the page is cut
  /// clean at the fold in two volets (docs: regles/iphone-duo.md §3): [start]
  /// above, fixed (the title and the key information; it scrolls on its own
  /// only if it is taller than the room above the fold), [end] below, which
  /// scrolls alone. Nothing sits, nor passes, in the fold. `false` (the
  /// default): one list that scrolls across the fold, as before.
  final bool laptopVolets;

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
      if (widget.laptopVolets && cut?.axis == FoldSplitAxis.horizontal) {
        final padding = widget.padding.resolve(Directionality.of(context));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: cut!.leadExtent,
              child: ListView(
                padding: padding.copyWith(bottom: _voletGap),
                children: start,
              ),
            ),
            SizedBox(height: cut.gap),
            Expanded(
              child: ListView(
                padding: padding.copyWith(top: _voletGap),
                children: end,
              ),
            ),
          ],
        );
      }
      if (cut?.axis != FoldSplitAxis.vertical) {
        final wideFrom = widget.wideFrom;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (wideFrom == null || constraints.maxWidth < wideFrom) {
              return ListView(
                padding: widget.padding,
                children: [...start, ...end],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(padding: widget.padding, children: start),
                ),
                Expanded(
                  child: ListView(padding: widget.padding, children: end),
                ),
              ],
            );
          },
        );
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
