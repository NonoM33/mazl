import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_message_view.dart';
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
  Widget build(BuildContext context) => FoldMessageView(
    icon: icon,
    title: title,
    line: line,
    actionLabel: actionLabel,
    onAction: onAction,
  );
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
