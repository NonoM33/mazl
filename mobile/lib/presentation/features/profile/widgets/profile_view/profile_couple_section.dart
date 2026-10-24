import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../l10n/l10n.dart';
import 'profile_sections.dart';

enum CoupleEntryState {
  /// In a couple with THIS member.
  inCouple,

  /// In a couple with somebody else.
  coupleWithSomeoneElse,

  /// A request to this member is waiting for their answer.
  pending,

  /// This member asked to activate the couple mode.
  received,

  /// Nothing yet: a request can be sent.
  available,
}

/// Entrée du mode couple, affichée sur le profil d'un match.
class ProfileCoupleSection extends StatelessWidget {
  const ProfileCoupleSection({
    super.key,
    required this.state,
    required this.userName,
    this.isSending = false,
    this.onActivate,
    this.onCancel,
    this.onRespond,
  });

  final CoupleEntryState state;
  final String userName;

  final bool isSending;
  final VoidCallback? onActivate;
  final VoidCallback? onCancel;
  final VoidCallback? onRespond;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return ProfileSection(
      label: l10n.profileCoupleMode,
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
              title: l10n.profileCoupleInCoupleTitle,
              body: l10n.profileCoupleInCoupleBody(userName),
            ),
          CoupleEntryState.coupleWithSomeoneElse => _info(
              context,
              icon: LucideIcons.heartHandshake,
              title: l10n.profileCoupleElsewhereTitle,
              body: l10n.profileCoupleElsewhereBody,
            ),
          CoupleEntryState.received => _info(
              context,
              icon: LucideIcons.heartHandshake,
              title: l10n.profileCoupleReceivedTitle,
              body: l10n.profileCoupleReceivedBody(userName),
              action: ElevatedButton(onPressed: onRespond, child: Text(l10n.profileCoupleRespond)),
            ),
          CoupleEntryState.pending => _info(
              context,
              icon: LucideIcons.clock,
              title: l10n.profileCouplePendingTitle,
              body: l10n.profileCouplePendingBody(userName),
              action: OutlinedButton(onPressed: onCancel, child: Text(l10n.profileCoupleCancelRequest)),
            ),
          CoupleEntryState.available => _info(
              context,
              icon: LucideIcons.heartHandshake,
              title: l10n.profileCoupleAvailableTitle,
              body: l10n.profileCoupleAvailableBody,
              action: ElevatedButton(
                onPressed: isSending ? null : onActivate,
                child: isSending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.profileCoupleActivate(userName)),
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
