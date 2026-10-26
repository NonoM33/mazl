import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/couple_failure_label.dart';

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

  /// The failure state: what went wrong, and a way to try again. The title
  /// is « Chargement impossible » (in the member's language) unless [title]
  /// says otherwise.
  factory CoupleMessageView.failure(
    CoupleFailure failure, {
    Key? key,
    String? title,
    VoidCallback? onRetry,
  }) => _CoupleFailureView(
    key: key,
    failure: failure,
    failureTitle: title,
    onRetry: onRetry,
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
    return FoldSafeActions(
      child: Center(
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
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

/// The failure state of [CoupleMessageView]: it writes its sentences in the
/// member's language, so it needs the context to do so.
class _CoupleFailureView extends CoupleMessageView {
  const _CoupleFailureView({
    super.key,
    required this.failure,
    required this.failureTitle,
    required this.onRetry,
  }) : super(title: '');

  final CoupleFailure failure;
  final String? failureTitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CoupleMessageView(
      icon: LucideIcons.alertCircle,
      title: failureTitle ?? l10n.coupleSpaceLoadFailedTitle,
      line: failure.label(l10n),
      actionLabel: onRetry == null ? null : l10n.commonRetry,
      onAction: onRetry,
    );
  }
}
