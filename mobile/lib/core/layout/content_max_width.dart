import 'package:flutter/material.dart';

import 'fold_state.dart';

/// Widest a single-column page grows: lines stay readable and the canon's
/// margins keep their meaning. Only reached on a regular-width window; a
/// compact one is narrower than this and is left untouched.
const double kContentMaxWidth = 560;

/// Centers a single-column page in at most [maxWidth] points, inside the
/// horizontal safe area.
///
/// The structure is the same at every width (only the number given to the
/// [SizedBox] changes), so the page below keeps its state when the window
/// grows or shrinks, e.g. when the device is unfolded. [child] still gets
/// tight constraints, exactly as when it filled the window.
class ContentMaxWidth extends StatelessWidget {
  const ContentMaxWidth({super.key, required this.child, this.maxWidth = kContentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    // The sides of the page are the safe area's: the system controls can sit
    // along one edge only, so each side keeps its own inset. Zero on a phone
    // held upright, the color above still fills the whole window.
    child: SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth < _maxWidthFor(context) ? constraints.maxWidth : _maxWidthFor(context),
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        ),
      ),
    ),
  );

  /// Held like a book and half open, the fold runs down the middle of the
  /// window: the page takes the whole width so that each side of the fold
  /// keeps a usable half (see [FoldAwareSplit]).
  double _maxWidthFor(BuildContext context) {
    final fold = FoldScope.of(context).activeDivision;
    return fold != null && fold.height > fold.width ? double.infinity : maxWidth;
  }
}
