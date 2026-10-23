import 'package:flutter/widgets.dart';

/// Where the [PairedAvatars] badge sits.
enum PairBadgePlacement {
  /// In the row, between the two avatars, [PairedAvatars.restGap] on each side.
  between,

  /// Over the point where the two avatars touch.
  overlay,
}

/// Two avatars that start apart and settle together around a badge (a heart).
/// Shared by the « Mazal Tov » screen and the match sheet, so the two moments
/// speak the same visual language.
///
/// [progress] runs 0 → 1: each avatar travels [startOffset] toward the centre,
/// the badge never moves. The caller owns the animation (curve included).
class PairedAvatars extends StatelessWidget {
  const PairedAvatars({
    super.key,
    required this.progress,
    required this.first,
    required this.second,
    required this.badge,
    required this.startOffset,
    this.placement = PairBadgePlacement.between,
    this.restGap = 12,
  });

  /// 0 = avatars [startOffset] further out, 1 = at rest.
  final Animation<double> progress;
  final Widget first;
  final Widget second;
  final Widget badge;
  final double startOffset;
  final PairBadgePlacement placement;

  /// Space between the badge and each avatar at rest ([PairBadgePlacement.between]).
  final double restGap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final gap = startOffset * (1 - progress.value);
        final left = Transform.translate(offset: Offset(-gap, 0), child: first);
        final right = Transform.translate(offset: Offset(gap, 0), child: second);
        if (placement == PairBadgePlacement.overlay) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [left, right]),
              badge,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            left,
            SizedBox(width: restGap),
            badge,
            SizedBox(width: restGap),
            right,
          ],
        );
      },
    );
  }
}
