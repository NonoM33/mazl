import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// The opening of the Today page: the two overlapping photos with the
/// eyebrow « MAZL COUPLE · JOUR 214 », then the greeting on two lines.
/// [compact] is for the laptop pose, where all of it must stay above the fold.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.days,
    required this.partnerName,
    required this.memberName,
    required this.memberPhotoUrl,
    required this.partnerPhotoUrl,
    this.compact = false,
  });

  final int days;
  final String partnerName;

  /// The member's first name, `null` when the account does not tell it.
  final String? memberName;
  final String? memberPhotoUrl;
  final String? partnerPhotoUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final member = memberName;
    final greeting = member == null
        ? l10n.coupleTodayTitleNoName(partnerName)
        : l10n.coupleTodayTitle(member, partnerName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _OverlappingPhotos(
              size: compact ? 32 : 40,
              first: memberPhotoUrl,
              second: partnerPhotoUrl,
            ),
            const SizedBox(width: 12),
            Expanded(child: SectionLabel(l10n.coupleTodayEyebrow(days))),
          ],
        ),
        SizedBox(height: compact ? 8 : 20),
        Text(
          compact ? greeting.replaceAll('\n', ' ') : greeting,
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ],
    );
  }
}

class _OverlappingPhotos extends StatelessWidget {
  const _OverlappingPhotos({
    required this.size,
    required this.first,
    required this.second,
  });

  final double size;
  final String? first;
  final String? second;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.surface;
    Widget photo(String? url, int seed) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: SizedBox.square(
        dimension: size,
        child: ProfilePhoto(
          url: url,
          seed: seed,
          radius: size / 2,
          iconSize: size / 2,
        ),
      ),
    );
    const overlap = 12.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: size * 2 - overlap + 4,
        height: size + 4,
        child: Stack(
          children: [
            PositionedDirectional(start: 0, child: photo(first, 0)),
            PositionedDirectional(
              start: size - overlap + 4,
              child: photo(second, 1),
            ),
          ],
        ),
      ),
    );
  }
}
