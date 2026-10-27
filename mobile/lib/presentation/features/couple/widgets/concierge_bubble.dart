import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// One message of a concierge conversation. Mine on the end side in the
/// accent; the other member's, the assistant's and the team's on the start
/// side on a surface, each under its own eyebrow.
class ConciergeBubble extends StatelessWidget {
  const ConciergeBubble({
    super.key,
    required this.message,
    required this.partnerName,
  });

  final ConciergeMessage message;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final mine = message.mine;
    final eyebrow = switch (message.role) {
      _ when mine => null,
      ConciergeRole.member => partnerName,
      ConciergeRole.assistant => l10n.coupleConciergeRoleAssistant,
      ConciergeRole.staff => l10n.coupleConciergeRoleTeam,
    };
    final background = mine ? scheme.primary : scheme.surfaceContainer;
    final foreground = mine ? scheme.onPrimary : scheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.86),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: SectionLabel(eyebrow),
                ),
                const SizedBox(height: 4),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(20),
                    topEnd: const Radius.circular(20),
                    bottomStart: Radius.circular(mine ? 20 : 6),
                    bottomEnd: Radius.circular(mine ? 6 : 20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    message.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The discreet « … » shown while the assistant prepares its answer.
class ConciergeTyping extends StatelessWidget {
  const ConciergeTyping({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        label: context.l10n.coupleConciergeWaiting,
        liveRegion: true,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '…',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
