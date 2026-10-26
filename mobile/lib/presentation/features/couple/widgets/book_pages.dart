import 'package:flutter/widgets.dart';

import '../../../../core/layout/fold_cut.dart';

/// The narrowest page a book accepts; narrower and a screen stays flat.
const double bookPaneExtent = 240;

/// Two pages side by side around the fold of a half-open foldable iPhone held
/// like a book: [lead] on the reading-start page, [action] on the other, the
/// curve between them empty. Build it only when a [FoldCutBuilder] reports a
/// vertical cut.
Widget bookPages(FoldCut cut, {required Widget lead, required Widget action}) =>
    Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: cut.leadExtent, child: lead),
        SizedBox(width: cut.gap),
        Expanded(child: action),
      ],
    );

/// Like [bookPages], for either way a half-open display is folded: side by
/// side around a fold that runs down the page, one above the other around a
/// fold that runs across it ([lead] on top, [action] below).
Widget splitPages(
  FoldCut cut, {
  required Widget lead,
  required Widget action,
}) => switch (cut.axis) {
  FoldSplitAxis.vertical => bookPages(cut, lead: lead, action: action),
  FoldSplitAxis.horizontal => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: cut.leadExtent, child: lead),
      SizedBox(height: cut.gap),
      Expanded(child: action),
    ],
  ),
};
