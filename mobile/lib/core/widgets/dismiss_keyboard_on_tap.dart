import 'package:flutter/widgets.dart';

/// Closes the on-screen keyboard when the user taps outside a text field.
///
/// Meant to wrap the app's content through `MaterialApp.builder`. The
/// translucent behavior lets taps still reach buttons and fields below.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
