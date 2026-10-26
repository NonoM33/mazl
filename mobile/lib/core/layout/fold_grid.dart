import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'fold_cut.dart';

/// A grid of tiles at most [maxCrossAxisExtent] wide whose columns stay on
/// either page of a fold that runs down the grid (foldable iPhone held like a
/// book): the curve falls between two columns, no tile crosses it.
///
/// [cut] comes from a [FoldCutBuilder] around the scroll view, and
/// [crossAxisStart] is how far the grid starts from that box's left edge
/// (the scroll view's left padding). Without a fold down the grid it lays
/// out exactly like [SliverGridDelegateWithMaxCrossAxisExtent].
class FoldGridDelegate extends SliverGridDelegate {
  const FoldGridDelegate({
    required this.cut,
    required this.maxCrossAxisExtent,
    this.crossAxisStart = 0,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1,
    this.mainAxisExtent,
  });

  final FoldCut? cut;
  final double maxCrossAxisExtent;
  final double crossAxisStart;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final double? mainAxisExtent;

  SliverGridDelegateWithMaxCrossAxisExtent get _flat =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
        mainAxisExtent: mainAxisExtent,
      );

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final cut = this.cut;
    final extent = constraints.crossAxisExtent;
    if (cut == null ||
        cut.axis != FoldSplitAxis.vertical ||
        constraints.axis != Axis.vertical) {
      return _flat.getLayout(constraints);
    }
    // The fold from the grid's left edge. Tile offsets are from that edge
    // too (the layout, not the render object, mirrors a right-to-left grid).
    final foldLeft = (cut.start - crossAxisStart).clamp(0.0, extent);
    final foldRight = (cut.end - crossAxisStart).clamp(0.0, extent);
    final narrowest = math.min(foldLeft, extent - foldRight);
    if (narrowest <= 0) return _flat.getLayout(constraints);
    final perPage = math.max(
      1,
      ((narrowest + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing))
          .ceil(),
    );
    final tile = (narrowest - crossAxisSpacing * (perPage - 1)) / perPage;
    final stride = tile + crossAxisSpacing;
    // Each page's columns sit against the fold's margin; a wider page keeps
    // its extra room on its outer edge.
    final leftPage = [
      for (var i = 0; i < perPage; i++)
        foldLeft - perPage * stride + crossAxisSpacing + i * stride,
    ];
    final rightPage = [
      for (var i = 0; i < perPage; i++) foldRight + i * stride,
    ];
    final offsets = constraints.crossAxisDirection == AxisDirection.left
        ? [...rightPage.reversed, ...leftPage.reversed]
        : [...leftPage, ...rightPage];
    return _FoldGridLayout(
      offsets: offsets,
      tileCrossExtent: tile,
      tileMainExtent: mainAxisExtent ?? tile / childAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  @override
  bool shouldRelayout(FoldGridDelegate oldDelegate) =>
      oldDelegate.cut != cut ||
      oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
      oldDelegate.crossAxisStart != crossAxisStart ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      oldDelegate.childAspectRatio != childAspectRatio ||
      oldDelegate.mainAxisExtent != mainAxisExtent;
}

class _FoldGridLayout extends SliverGridLayout {
  const _FoldGridLayout({
    required this.offsets,
    required this.tileCrossExtent,
    required this.tileMainExtent,
    required this.mainAxisSpacing,
  });

  final List<double> offsets;
  final double tileCrossExtent;
  final double tileMainExtent;
  final double mainAxisSpacing;

  int get _columns => offsets.length;
  double get _rowStride => tileMainExtent + mainAxisSpacing;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) =>
      _rowStride > 0 ? _columns * (scrollOffset ~/ _rowStride) : 0;

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    final rows = _rowStride > 0 ? (scrollOffset / _rowStride).ceil() : 0;
    return math.max(0, _columns * rows - 1);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) => SliverGridGeometry(
    scrollOffset: (index ~/ _columns) * _rowStride,
    crossAxisOffset: offsets[index % _columns],
    mainAxisExtent: tileMainExtent,
    crossAxisExtent: tileCrossExtent,
  );

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0) return 0;
    final rows = (childCount + _columns - 1) ~/ _columns;
    return rows * _rowStride - mainAxisSpacing;
  }
}
