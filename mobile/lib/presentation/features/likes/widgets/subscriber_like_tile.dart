import 'package:flutter/material.dart';

import '../../../../core/models/likes.dart';
import '../../../../l10n/l10n.dart';
import 'like_widgets.dart';
import 'super_like_mark.dart';

/// The card of a like for a subscriber: [LikeCard] as it always was, plus the
/// Super Like mark and, when one came with it, the word of the sender.
class SubscriberLikeTile extends StatelessWidget {
  const SubscriberLikeTile({
    super.key,
    required this.like,
    required this.onTap,
    required this.onLike,
    required this.onPass,
  });

  /// Room under the photo taken by the name pill (padding 6+6, 15 pt text)
  /// and its margin, so the note sits just above it.
  static const double _pillBand = 10 + 34 + 6;

  final LikeProfile like;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = like.displayName ?? l10n.matchingCardAnonymous;
    final note = like.note;
    return Stack(
      children: [
        LikeCard(
          name: name,
          age: like.age,
          pictureUrl: like.photoUrl,
          isVerified: like.isVerified,
          seed: like.userId,
          onTap: onTap,
          onLike: onLike,
          onPass: onPass,
        ),
        if (like.isSuperLike)
          PositionedDirectional(
            top: 10,
            start: 10,
            end: 10,
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SuperLikeMark(label: l10n.likesSuperLikeBadge),
              ),
            ),
          ),
        if (note != null)
          PositionedDirectional(
            start: 10,
            end: 10,
            bottom: LikeCard.actionsExtent + 8 + _pillBand,
            child: IgnorePointer(
              child: LikeNoteBubble(
                note: note,
                label: l10n.likesNoteLabel(name),
              ),
            ),
          ),
      ],
    );
  }
}
