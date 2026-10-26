import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/models/verification.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';
import '../../../common/widgets/fold_pages.dart';

/// Un niveau de vérification : étiquette, titre, état, texte, action. Les
/// niveaux sont séparés par un filet, sans carte.
class _Level extends StatelessWidget {
  const _Level({required this.eyebrow, required this.title, required this.verified, required this.children});

  final String eyebrow;
  final String title;
  final bool verified;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(eyebrow),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: IdentityHeadline(title, size: 24)),
              if (verified) ...[
                const SizedBox(width: 12),
                TagPill(context.l10n.verificationVerifiedPill, icon: LucideIcons.check),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Niveau 1 : le selfie en direct, comparé aux photos du profil.
class PhotoLevel extends StatelessWidget {
  const PhotoLevel({
    super.key,
    required this.step,
    required this.nextAttempt,
    required this.busy,
    required this.onVerify,
    required this.onRemove,
  });

  final VerificationStep step;
  final DateTime? nextAttempt;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blockedUntil = nextAttempt;
    final blocked = !step.verified && blockedUntil != null && blockedUntil.isAfter(DateTime.now());
    final verifiedAt = step.verifiedAt;
    return _Level(
      eyebrow: l10n.verificationLevel1,
      title: l10n.verificationPhotoTitle,
      verified: step.verified,
      children: [
        if (step.verified) ...[
          IdentityParagraph(
            verifiedAt == null
                ? l10n.verificationPhotoVerifiedLine
                : l10n.verificationPhotoVerifiedOn(verifiedAt.toLocal()),
            size: 15,
          ),
          const SizedBox(height: 20),
          IdentityOutlineButton(l10n.verificationRemoveAction, onPressed: busy ? null : onRemove),
        ] else ...[
          IdentityParagraph(l10n.verificationConsent, size: 15),
          const SizedBox(height: 20),
          FoldSafeActions(
            child: ElevatedButton(
              onPressed: busy || blocked ? null : onVerify,
              child: busy ? const _BusyDot() : Text(l10n.verificationVerifyPhotoAction),
            ),
          ),
          if (blocked) ...[
            const SizedBox(height: 10),
            Text(_blockedText(l10n, blockedUntil), style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ],
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
  const IdentityLevel({super.key, required this.step, required this.enabled, required this.onVerify});

  final VerificationStep step;
  final bool enabled;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = step.verifiedAt;
    return _Level(
      eyebrow: l10n.verificationLevel2,
      title: l10n.verificationIdentityTitle,
      verified: step.verified,
      children: [
        IdentityParagraph(
          step.verified
              ? (at == null ? l10n.verificationIdentityCheckedNoDate : l10n.verificationIdentityCheckedOn(at.toLocal()))
              : l10n.verificationIdentityPitch,
          size: 15,
        ),
        if (!step.verified) ...[
          const SizedBox(height: 20),
          IdentityOutlineButton(l10n.verificationVerifyIdentityAction, onPressed: enabled ? onVerify : null),
        ],
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
      rest: [
        IdentityOutlineButton(context.l10n.commonRetry, onPressed: onRetry),
      ],
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
