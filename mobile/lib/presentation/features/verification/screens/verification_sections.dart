import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/models/verification.dart';
import '../../../../l10n/l10n.dart';
import '../identity/identity_parts.dart';
import '../../../common/widgets/fold_pages.dart';
import 'verification_level_card.dart';

/// Niveau 1 : le selfie en direct, comparé aux photos du profil.
class PhotoLevel extends StatelessWidget {
  const PhotoLevel({
    super.key,
    required this.step,
    required this.nextAttempt,
    required this.busy,
    required this.refused,
    required this.onVerify,
  });

  final VerificationStep step;
  final DateTime? nextAttempt;
  final bool busy;

  /// The last attempt was turned down.
  final bool refused;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blockedUntil = nextAttempt;
    final blocked = !step.verified && blockedUntil != null && blockedUntil.isAfter(DateTime.now());
    final verifiedAt = step.verifiedAt;
    final state = step.verified
        ? LevelState.verified
        : busy
        ? LevelState.inProgress
        : blocked
        ? LevelState.blocked
        : refused
        ? LevelState.refused
        : LevelState.todo;
    return LevelCard(
      eyebrow: l10n.verificationLevel1,
      title: l10n.verificationPhotoCardTitle,
      icon: LucideIcons.scanFace,
      state: state,
      verifiedOn: step.verified && verifiedAt != null ? l10n.verificationVerifiedOnDate(verifiedAt.toLocal()) : null,
      description: step.verified ? l10n.verificationPhotoVerifiedLine : l10n.verificationPhotoPitch,
      benefits: [
        LevelBenefit(LucideIcons.badgeCheck, l10n.verificationPhotoBenefitBadge),
        LevelBenefit(LucideIcons.images, l10n.verificationPhotoBenefitProof),
        LevelBenefit(LucideIcons.timer, l10n.verificationPhotoBenefitQuick),
      ],
      action: step.verified
          ? null
          : FoldSafeActions(
              child: ElevatedButton(
                onPressed: busy || blocked ? null : onVerify,
                child: busy ? const _BusyDot() : Text(l10n.verificationVerifyPhotoAction),
              ),
            ),
      footnote: blocked ? _blockedText(l10n, blockedUntil) : null,
    );
  }

  static String _blockedText(AppLocalizations l10n, DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return sameDay ? l10n.verificationBlockedToday(local) : l10n.verificationBlockedLater(local, local);
  }
}

/// Niveau 2 : l'identité lue sur la puce du passeport ou de la carte.
class IdentityLevel extends StatelessWidget {
  const IdentityLevel({
    super.key,
    required this.step,
    required this.enabled,
    required this.onVerify,
    required this.primary,
  });

  final VerificationStep step;
  final bool enabled;
  final VoidCallback onVerify;

  /// Its button is the main action of the page (level 1 is done).
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = step.verifiedAt;
    final label = Text(l10n.verificationVerifyIdentityAction);
    return LevelCard(
      eyebrow: l10n.verificationLevel2,
      title: l10n.verificationIdentityCardTitle,
      icon: LucideIcons.idCard,
      state: step.verified ? LevelState.verified : LevelState.todo,
      verifiedOn: step.verified && at != null ? l10n.verificationVerifiedOnDate(at.toLocal()) : null,
      description: step.verified ? l10n.verificationIdentityCheckedNoDate : l10n.verificationIdentityPitch,
      benefits: [
        LevelBenefit(LucideIcons.shieldCheck, l10n.verificationIdentityBenefitBadge),
        LevelBenefit(LucideIcons.nfc, l10n.verificationIdentityBenefitChip),
        LevelBenefit(LucideIcons.contactRound, l10n.verificationIdentityBenefitNeeds),
      ],
      action: step.verified
          ? null
          : FoldSafeActions(
              child: primary
                  ? ElevatedButton(onPressed: enabled ? onVerify : null, child: label)
                  : OutlinedButton(onPressed: enabled ? onVerify : null, child: label),
            ),
    );
  }
}

/// « Retirer ma vérification » : une action discrète, en couleur d'erreur.
class RemoveVerificationButton extends StatelessWidget {
  const RemoveVerificationButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: scheme.error,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: Icon(LucideIcons.trash2, size: 18)),
            const SizedBox(width: 8),
            Flexible(child: Text(context.l10n.verificationRemoveAction)),
          ],
        ),
      ),
    );
  }
}

/// Ce qui est comparé et ce qui est gardé, avec un cadenas.
class VerificationPrivacyNote extends StatelessWidget {
  const VerificationPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(LucideIcons.lock, size: 18, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.verificationConsent,
            style: TextStyle(fontSize: 13, height: 1.45, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Un refus à comprendre (erreur) ou une remarque (information).
class VerificationNotice extends StatelessWidget {
  const VerificationNotice({super.key, required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              error ? LucideIcons.circleAlert : LucideIcons.info,
              size: 18,
              color: error ? scheme.error : scheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, height: 1.45, color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// Statut illisible : le message et un seul bouton.
class VerificationRetry extends StatelessWidget {
  const VerificationRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // The words on the page where reading starts, the button on the other
    // when the fold cuts the screen.
    return FoldPages(
      crossAxisAlignment: CrossAxisAlignment.start,
      padding: const EdgeInsets.all(24),
      lead: [
        const IconDisc(icon: LucideIcons.circleAlert),
        const SizedBox(height: 22),
        IdentityParagraph(message),
      ],
      rest: [IdentityOutlineButton(context.l10n.commonRetry, onPressed: onRetry)],
    );
  }
}

class _BusyDot extends StatelessWidget {
  const _BusyDot();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface),
  );
}
