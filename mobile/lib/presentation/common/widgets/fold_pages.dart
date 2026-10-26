import 'package:flutter/material.dart';

import '../../../core/layout/fold_cut.dart';
import '../../../core/layout/fold_message_view.dart';

/// Lays out [lead] and [rest] either side of the fold [cut]: [lead] on the
/// reading-start side.
Widget _inPanes(FoldCut cut, Widget lead, Widget rest) => switch (cut.axis) {
  FoldSplitAxis.vertical => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(width: cut.leadExtent, child: lead),
      SizedBox(width: cut.gap),
      Expanded(child: rest),
    ],
  ),
  FoldSplitAxis.horizontal => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: cut.leadExtent, child: lead),
      SizedBox(height: cut.gap),
      Expanded(child: rest),
    ],
  ),
};

/// A short, centered content (an empty state with its actions) split over the
/// two pages of a half-open foldable iPhone: [lead] (the words) on the page
/// where reading starts, [rest] (the actions) on the other, so that nothing
/// sits on the fold. Held like a laptop, [lead] above the fold and [rest]
/// below it. Anywhere else, [lead] then [rest] in one centered column.
///
/// For a message with an icon, a title, a line and one action,
/// [FoldMessageView] is the shared drawing; this is for the states whose
/// words or actions it does not fit.
class FoldPages extends StatelessWidget {
  const FoldPages({
    super.key,
    required this.lead,
    required this.rest,
    this.gap = 24,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 32),
  });

  final List<Widget> lead;
  final List<Widget> rest;

  /// Between [lead] and [rest] when they share a page.
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
    Widget page(List<Widget> children) => Center(
      child: SingleChildScrollView(padding: padding, child: column(children)),
    );
    return FoldCutBuilder(
      minPaneExtent: kFoldMessagePaneExtent,
      builder: (context, cut) {
        if (cut != null) return _inPanes(cut, page(lead), page(rest));
        return Center(
          child: Padding(
            padding: padding,
            child: column([...lead, SizedBox(height: gap), ...rest]),
          ),
        );
      },
    );
  }
}

/// A waiting state (a skeleton) that fills a screen, kept on the page where
/// reading starts of a half-open foldable iPhone instead of across the fold.
/// Anywhere else it is [child] as it is.
class FoldFirstPage extends StatelessWidget {
  const FoldFirstPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FoldCutBuilder(
    minPaneExtent: kFoldMessagePaneExtent,
    builder: (context, cut) =>
        cut == null ? child : _inPanes(cut, child, const SizedBox.shrink()),
  );
}

/// A spinner centered on the page where reading starts, for a screen that
/// waits for its first data: never on the fold of a half-open foldable iPhone.
class FoldSpinner extends StatelessWidget {
  const FoldSpinner({super.key});

  @override
  Widget build(BuildContext context) =>
      const FoldFirstPage(child: Center(child: CircularProgressIndicator()));
}
