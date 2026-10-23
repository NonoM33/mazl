import 'dart:async';

import 'package:flutter/scheduler.dart';

/// Runs one frame-by-frame animation at a time on a single ticker. Starting
/// another one (a finger landing on the card, say) interrupts the first.
class DeckAnimator {
  DeckAnimator(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  bool Function(double seconds)? _step;
  Completer<bool>? _done;

  bool get running => _done != null;

  /// Calls [step] every frame with the seconds since the start, until it
  /// returns true. Completes with true when it ran to the end, false when
  /// something else took over first.
  Future<bool> run(bool Function(double seconds) step) {
    stop();
    final done = Completer<bool>();
    _done = done;
    _step = step;
    _ticker.start();
    return done.future;
  }

  /// Interrupts the animation in progress, if any.
  void stop() {
    if (_ticker.isActive) _ticker.stop();
    final done = _done;
    _done = null;
    _step = null;
    done?.complete(false);
  }

  void _onTick(Duration elapsed) {
    final step = _step;
    if (step == null) return;
    if (!step(elapsed.inMicroseconds / Duration.microsecondsPerSecond)) return;
    _ticker.stop();
    final done = _done;
    _done = null;
    _step = null;
    done?.complete(true);
  }

  void dispose() {
    stop();
    _ticker.dispose();
  }
}
