import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/web_sessions/web_session_models.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import 'web_session_format.dart';
import '../../../../l10n/l10n.dart';

/// Asks whether to connect the computer. Resolves true to connect, false to
/// refuse; a dismissed sheet counts as a refusal.
Future<bool> confirmPairing(BuildContext context, WebPairing pairing) async {
  final approved = await showMazlSheet<bool>(
    context,
    isDismissible: false,
    isScrollControlled: true,
    builder: (_) => _ConfirmPairingBody(pairing: pairing),
  );
  return approved ?? false;
}

class _ConfirmPairingBody extends StatelessWidget {
  const _ConfirmPairingBody({required this.pairing});

  final WebPairing pairing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.webSessionsConfirmLabel, color: AppColors.tekhelet),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              l10n.webSessionsConfirmTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          FactRow(
            label: l10n.webSessionsConfirmBrowser,
            value: pairing.browser,
          ),
          if (pairing.address != null)
            FactRow(
              label: l10n.webSessionsConfirmAddress,
              value: pairing.address!,
            ),
          FactRow(
            label: l10n.webSessionsConfirmAskedAt,
            value: clockTimeLabel(l10n, pairing.createdAt),
            last: true,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.webSessionsConfirmWarning,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.webSessionsConfirmApprove),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.webSessionsConfirmDeny),
          ),
        ],
      ),
    );
  }
}
