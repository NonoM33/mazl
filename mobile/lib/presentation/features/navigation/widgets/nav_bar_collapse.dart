import 'package:flutter/widgets.dart';

/// Folds the tab bar into the current tab's icon while the user reads down a
/// page, and unfolds it when they come back up quickly or reach the top.
/// Pure logic: the screen feeds it scroll updates, the bar listens to it.
class NavBarCollapseController extends ChangeNotifier {
  NavBarCollapseController({Duration Function()? clock}) : _clock = clock ?? _stopwatchClock();

  /// Downward distance, in one direction, before the bar folds.
  static const collapseDistance = 40.0;

  /// Upward speed (px/s) that reads as "I want the tabs back".
  static const expandSpeed = 1000.0;

  final Duration Function() _clock;
  bool _collapsed = false;
  double _downDistance = 0;
  Duration? _lastUpdate;

  bool get collapsed => _collapsed;

  void expand() => _set(false);

  /// [delta] > 0 when the content moves up, i.e. the user scrolls down.
  void onScroll({required double delta, required double pixels, required double minExtent, Duration? timestamp}) {
    final now = timestamp ?? _clock();
    final elapsed = _lastUpdate == null ? null : now - _lastUpdate!;
    _lastUpdate = now;

    if (pixels <= minExtent + 0.5) {
      _downDistance = 0;
      _set(false);
      return;
    }
    if (delta > 0) {
      _downDistance += delta;
      if (_downDistance >= collapseDistance) _set(true);
    } else if (delta < 0) {
      _downDistance = 0;
      if (_isFast(-delta, elapsed)) _set(false);
    }
  }

  /// Adapter for the [NotificationListener] wrapping the tab pages: vertical
  /// scroll updates only (horizontal carousels and card swipes are ignored).
  bool handleNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && notification.metrics.axis == Axis.vertical) {
      final delta = notification.scrollDelta;
      if (delta != null) {
        onScroll(delta: delta, pixels: notification.metrics.pixels, minExtent: notification.metrics.minScrollExtent);
      }
    }
    return false;
  }

  static bool _isFast(double distance, Duration? elapsed) {
    if (elapsed == null || elapsed <= Duration.zero) return false;
    return distance / (elapsed.inMicroseconds / Duration.microsecondsPerSecond) >= expandSpeed;
  }

  void _set(bool collapsed) {
    if (_collapsed == collapsed) return;
    _collapsed = collapsed;
    notifyListeners();
  }

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }
}
