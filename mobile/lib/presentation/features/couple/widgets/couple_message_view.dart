import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// A centered title, one line and at most one action: the empty and the error
/// state of every couple content screen.
class CoupleMessageView extends StatelessWidget {
  const CoupleMessageView({
    super.key,
    required this.title,
    this.line,
    this.icon = LucideIcons.sparkles,
    this.actionLabel,
    this.onAction,
  });

  /// The failure state: what went wrong, and a way to try again.
  factory CoupleMessageView.failure(
    CoupleFailure failure, {
    Key? key,
    String title = 'Chargement impossible',
    VoidCallback? onRetry,
  }) => CoupleMessageView(
    key: key,
    icon: LucideIcons.alertCircle,
    title: title,
    line: failure.message,
    actionLabel: onRetry == null ? null : 'Réessayer',
    onAction: onRetry,
  );

  final String title;
  final String? line;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: muted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (line != null) ...[
              const SizedBox(height: 8),
              Text(
                line!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A floating error message, for an action that did not go through.
void showCoupleError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
