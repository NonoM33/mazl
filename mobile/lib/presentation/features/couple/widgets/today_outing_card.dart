import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';
import 'event_category.dart';

/// « IDÉE POUR JEUDI »: a picture at the start, the outing proposed for
/// today, and the way to its page.
class TodayOutingCard extends StatelessWidget {
  const TodayOutingCard({
    super.key,
    required this.outing,
    required this.onOpen,
  });

  final Outing outing;
  final VoidCallback onOpen;

  String _eyebrow(BuildContext context) {
    final l10n = context.l10n;
    final startsAt = outing.startsAt;
    if (startsAt == null) return l10n.coupleTodayIdeaGeneric;
    final weekday = DateFormat.EEEE(l10n.localeName).format(startsAt.toLocal());
    return l10n.coupleTodayIdeaFor(weekday);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CoupleCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 112, child: _Picture(outing: outing)),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SectionLabel(_eyebrow(context)),
                    const SizedBox(height: 4),
                    Text(outing.title, style: theme.textTheme.titleMedium),
                    if (outing.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(outing.subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.outing});

  final Outing outing;

  @override
  Widget build(BuildContext context) {
    final fallback = EventImagePlaceholder(category: null, seed: outing.id);
    final url = outing.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
