import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'profile_sections.dart';

enum CoupleEntryState { inCouple, pending, available }

/// Entrée du mode couple, affichée sur le profil d'un match.
class ProfileCoupleSection extends StatelessWidget {
  const ProfileCoupleSection({
    super.key,
    required this.state,
    required this.userName,
    this.partnerName,
    this.isSending = false,
    this.onActivate,
    this.onCancel,
  });

  final CoupleEntryState state;
  final String userName;

  /// Nom de la personne avec qui l'on est déjà en couple (état [CoupleEntryState.inCouple]).
  final String? partnerName;
  final bool isSending;
  final VoidCallback? onActivate;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ProfileSection(
      label: 'Mode couple',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: switch (state) {
          CoupleEntryState.inCouple => _info(
              context,
              icon: LucideIcons.heartHandshake,
              title: 'Déjà en couple',
              body: 'Tu es en mode couple avec ${partnerName ?? 'quelqu\'un'}.',
            ),
          CoupleEntryState.pending => _info(
              context,
              icon: LucideIcons.clock,
              title: 'Demande envoyée',
              body: '$userName n\'a pas encore répondu.',
              action: OutlinedButton(onPressed: onCancel, child: const Text('Annuler la demande')),
            ),
          CoupleEntryState.available => _info(
              context,
              icon: LucideIcons.heartHandshake,
              title: 'Passer au mode couple',
              body: 'Vous avez matché. Activez le mode couple pour partager des activités ensemble.',
              action: ElevatedButton(
                onPressed: isSending ? null : onActivate,
                child: isSending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Activer avec $userName'),
              ),
            ),
        },
      ),
    );
  }

  Widget _info(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(fontSize: 14, height: 1.4, color: muted)),
        if (action != null) ...[
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: action),
        ],
      ],
    );
  }
}
