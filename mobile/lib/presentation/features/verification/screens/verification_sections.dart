import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/verification.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';

const String consentText =
    'Nous comparons votre visage à vos photos. Les images ne sont pas conservées ; '
    'seule une empreinte chiffrée l\'est, supprimable à tout moment.';

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
              if (verified) ...[const SizedBox(width: 12), const TagPill('Vérifiée', icon: LucideIcons.check)],
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
    final blockedUntil = nextAttempt;
    final blocked = !step.verified && blockedUntil != null && blockedUntil.isAfter(DateTime.now());
    return _Level(
      eyebrow: 'Niveau 1',
      title: 'Photo vérifiée',
      verified: step.verified,
      children: [
        if (step.verified) ...[
          IdentityParagraph(_verifiedLine(step.verifiedAt), size: 15),
          const SizedBox(height: 20),
          IdentityOutlineButton('Retirer ma vérification', onPressed: busy ? null : onRemove),
        ] else ...[
          const IdentityParagraph(consentText, size: 15),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy || blocked ? null : onVerify,
            child: busy ? const _BusyDot() : const Text('Vérifier ma photo'),
          ),
          if (blocked) ...[
            const SizedBox(height: 10),
            Text(
              'Limite atteinte, nouvel essai possible ${_whenText(blockedUntil)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ],
    );
  }

  static String _verifiedLine(DateTime? at) => at == null
      ? 'Votre visage correspond à vos photos.'
      : 'Vérifiée le ${DateFormat('dd/MM/yyyy').format(at.toLocal())}.';

  static String _whenText(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    final time = DateFormat('HH:mm').format(local);
    return sameDay ? 'à $time' : 'le ${DateFormat('dd/MM').format(local)} à $time';
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
    final at = step.verifiedAt;
    return _Level(
      eyebrow: 'Niveau 2',
      title: 'Identité vérifiée',
      verified: step.verified,
      children: [
        IdentityParagraph(
          step.verified
              ? (at == null
                    ? 'Document contrôlé par sa puce.'
                    : 'Contrôlée le ${DateFormat('dd/MM/yyyy').format(at.toLocal())}.')
              : 'Passeport ou carte d\'identité, lu par sa puce. Un selfie confirme que c\'est bien vous.',
          size: 15,
        ),
        if (!step.verified) ...[
          const SizedBox(height: 20),
          IdentityOutlineButton('Vérifier mon identité', onPressed: enabled ? onVerify : null),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconDisc(icon: LucideIcons.circleAlert),
          const SizedBox(height: 22),
          IdentityParagraph(message),
          const SizedBox(height: 24),
          IdentityOutlineButton('Réessayer', onPressed: onRetry),
        ],
      ),
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
