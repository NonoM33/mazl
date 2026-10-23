import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';

/// How long a couple has existed, in calendar days (not 24 h slices):
/// 23:30 then 00:10 the next day is already "1 jour".
String coupleDurationLabel(DateTime since, DateTime now) {
  final start = DateTime.utc(since.year, since.month, since.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = today.difference(start).inDays;
  if (days <= 0) return "Depuis aujourd'hui";
  if (days == 1) return '1 jour';
  return '$days jours';
}

/// The couple mode card of the settings: active couple, request waiting for
/// an answer, or the invitation to activate the mode.
class SettingsCoupleCard extends StatelessWidget {
  const SettingsCoupleCard({
    super.key,
    required this.service,
    required this.onOpenSpace,
    required this.onOpenCalendar,
    required this.onActivate,
    required this.onLeave,
    required this.onCancelRequest,
  });

  final CoupleService service;
  final VoidCallback onOpenSpace;
  final VoidCallback onOpenCalendar;
  final VoidCallback onActivate;
  final VoidCallback onLeave;
  final VoidCallback onCancelRequest;

  @override
  Widget build(BuildContext context) {
    final couple = service.coupleData;
    final pending = service.pendingRequest;
    final Widget content;
    if (service.isCoupleModeEnabled && couple != null) {
      content = _ActiveCouple(
        couple: couple,
        onOpenSpace: onOpenSpace,
        onOpenCalendar: onOpenCalendar,
        onLeave: onLeave,
      );
    } else if (pending != null) {
      content = _PendingRequest(request: pending, onCancel: onCancelRequest);
    } else {
      content = _Invitation(onActivate: onActivate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: content,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.heartHandshake,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveCouple extends StatelessWidget {
  const _ActiveCouple({
    required this.couple,
    required this.onOpenSpace,
    required this.onOpenCalendar,
    required this.onLeave,
  });

  final CoupleData couple;
  final VoidCallback onOpenSpace;
  final VoidCallback onOpenCalendar;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final since = couple.relationshipStartDate;
    final detail = [
      'Avec ${couple.partnerName ?? 'votre partenaire'}',
      if (since != null) coupleDurationLabel(since.toLocal(), DateTime.now()),
    ].join(' · ');
    const compact = EdgeInsets.symmetric(horizontal: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardTitle(title: 'Mode couple actif', detail: detail),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onOpenSpace,
                style: ElevatedButton.styleFrom(
                  padding: compact,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'Espace couple',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onOpenCalendar,
                style: OutlinedButton.styleFrom(
                  padding: compact,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'Calendrier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onLeave,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(
            'Quitter le mode couple',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PendingRequest extends StatelessWidget {
  const _PendingRequest({required this.request, required this.onCancel});

  final CoupleRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final name = request.targetName?.trim().split(' ').first ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardTitle(
          title: name.isEmpty ? 'Demande envoyée' : 'Demande envoyée à $name',
          detail: 'En attente de sa réponse',
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text(
            'Annuler la demande',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Invitation extends StatelessWidget {
  const _Invitation({required this.onActivate});

  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _CardTitle(title: "Vous avez trouvé l'amour ?")),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onActivate,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Activer'),
        ),
      ],
    );
  }
}
