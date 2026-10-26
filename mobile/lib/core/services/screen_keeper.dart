import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// What the Shabbat display asks of the phone: stay lit and keep the system
/// bars away. [WakelockScreenKeeper] in the app, a fake in the tests.
abstract interface class ScreenKeeper {
  /// Keeps the screen on and hides the status bar.
  Future<void> hold();

  /// Gives the screen back to the system.
  Future<void> release();
}

/// The screen kept on by `wakelock_plus` (the Flutter community plugin that
/// sets `isIdleTimerDisabled` on iOS), the status bar hidden by the framework.
class WakelockScreenKeeper implements ScreenKeeper {
  const WakelockScreenKeeper();

  @override
  Future<void> hold() async {
    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Future<void> release() async {
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
