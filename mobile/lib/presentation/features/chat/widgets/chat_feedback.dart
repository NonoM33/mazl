import 'package:flutter/material.dart';

/// Where chat messages (snackbars) must stop: the conversation screen knows
/// where its composer starts, and a message floats 12 px above it instead of
/// covering it (same rule as the floating tab bar).
class ChatSnackAnchor extends InheritedWidget {
  const ChatSnackAnchor({super.key, required this.bottomGap, required super.child});

  /// Distance from the bottom of the screen the message must keep, computed
  /// when the message is shown (the composer grows with its text).
  final double Function() bottomGap;

  static ChatSnackAnchor? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChatSnackAnchor>();

  @override
  bool updateShouldNotify(ChatSnackAnchor oldWidget) => false;
}

/// One short line, for an action that failed or just succeeded.
void showChatSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final gap = ChatSnackAnchor.maybeOf(context)?.bottomGap();
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: gap == null ? null : EdgeInsets.fromLTRB(16, 0, 16, gap),
      ),
    );
}

/// Shows [error] when an action returned one (null means success).
void showChatError(BuildContext context, String? error) {
  if (error != null && context.mounted) showChatSnack(context, error);
}
