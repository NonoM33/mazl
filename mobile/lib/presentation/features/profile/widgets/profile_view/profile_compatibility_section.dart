import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/api_service.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';
import '../../l10n/compatibility_labels.dart';
import 'profile_sections.dart';

/// Libellé et description d'un score de compatibilité.
({String label, String description}) compatibilitySummary(
  AppLocalizations l10n,
  CompatibilityScore c,
) {
  final top = [...c.factors]..sort((a, b) => b.score.compareTo(a.score));
  final description = top.isEmpty
      ? l10n.profileCompatibilityBasis
      : top.take(3).map((f) => f.verdict.label(l10n)).join(' · ');
  return (label: c.level.label(l10n), description: description);
}

/// Section « Compatibilité » : score pour les abonnés Pro, invitation sinon.
class ProfileCompatibilitySection extends StatelessWidget {
  const ProfileCompatibilitySection({
    super.key,
    required this.firstName,
    required this.hasPremium,
    required this.score,
    required this.onUnlock,
  });

  final String firstName;
  final bool hasPremium;
  final CompatibilityScore? score;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ProfileSection(
      label: context.l10n.profileCompatibility,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: hasPremium ? _score(context) : _locked(context),
      ),
    );
  }

  Widget _score(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final current = score;
    if (current == null) {
      return Text(
        l10n.profileCompatibilityUnavailable,
        style: TextStyle(fontSize: 15, color: muted),
      );
    }
    final summary = compatibilitySummary(l10n, current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${current.score}%',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600, letterSpacing: -2, height: 1),
        ),
        const SizedBox(height: 8),
        Text(
          summary.label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.3),
        ),
        const SizedBox(height: 6),
        Text(summary.description, style: TextStyle(fontSize: 14, height: 1.4, color: muted)),
      ],
    );
  }

  Widget _locked(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TagPill('mazl+', icon: LucideIcons.lock),
        const SizedBox(height: 14),
        Text(
          l10n.profileCompatibilityUnlockTitle(firstName),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.5, height: 1.25),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profileCompatibilityUnlockBody,
          style: TextStyle(fontSize: 14, height: 1.4, color: muted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onUnlock, child: Text(l10n.profileCompatibilityUnlock)),
        ),
      ],
    );
  }
}
