import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';

/// Where the profile stands overall: how many of the two levels are verified,
/// and whether a check is running right now.
class VerificationOverview {
  const VerificationOverview({required this.verifiedLevels, required this.busy});

  static const int totalLevels = 2;

  final int verifiedLevels;
  final bool busy;

  bool get complete => verifiedLevels == totalLevels;
  bool get started => verifiedLevels > 0;
}

/// The top of the Verification page: a large shield, the state of the profile
/// in one title, what the badge brings, and the progress over the two levels.
class VerificationHeader extends StatelessWidget {
  const VerificationHeader({super.key, required this.overview});

  final VerificationOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final complete = overview.complete;
    final title = complete
        ? l10n.verificationStateDoneTitle
        : (overview.started || overview.busy ? l10n.verificationStatePartialTitle : l10n.verificationStateNoneTitle);
    final body = complete
        ? l10n.verificationStateDoneBody
        : (overview.started ? l10n.verificationStatePartialBody : l10n.verificationStateNoneBody);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete ? scheme.primary : scheme.primaryContainer,
                ),
                child: Icon(
                  overview.started ? LucideIcons.shieldCheck : LucideIcons.shield,
                  size: 30,
                  color: complete ? scheme.onPrimary : scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(l10n.verificationTitle),
                  const SizedBox(height: 6),
                  IdentityHeadline(title, size: 26),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        IdentityParagraph(body, size: 15),
        const SizedBox(height: 16),
        VerificationProgress(done: overview.verifiedLevels),
      ],
    );
  }
}

/// Two segments, one per level, filled as the levels are verified, and the
/// count in words.
class VerificationProgress extends StatelessWidget {
  const VerificationProgress({super.key, required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.verificationProgress(done);
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < VerificationOverview.totalLevels; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i < done ? scheme.primary : scheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
