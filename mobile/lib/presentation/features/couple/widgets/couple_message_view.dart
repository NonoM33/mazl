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
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (line != null) ...[
              const SizedBox(height: 8),
              Text(
                line!,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
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
