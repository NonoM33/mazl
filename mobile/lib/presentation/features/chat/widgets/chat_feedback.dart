import 'package:flutter/material.dart';

/// One short line at the bottom, for an action that failed or just succeeded.
void showChatSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
}

/// Shows [error] when an action returned one (null means success).
void showChatError(BuildContext context, String? error) {
  if (error != null && context.mounted) showChatSnack(context, error);
}
