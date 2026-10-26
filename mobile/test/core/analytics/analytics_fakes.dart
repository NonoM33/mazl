import 'dart:async';

import 'package:mazl/core/analytics/analytics_transport.dart';

/// A transport that records the batches and answers what the test says.
class FakeAnalyticsTransport implements AnalyticsTransport {
  final batches = <List<QueuedEvent>>[];
  AnalyticsSendResult result = AnalyticsSendResult.sent;

  /// When set, a send waits for it (an answer still in flight).
  Completer<AnalyticsSendResult>? gate;

  List<String> get sentNames => [
    for (final batch in batches) ...batch.map((e) => e.event.name),
  ];

  @override
  Future<AnalyticsSendResult> send(List<QueuedEvent> batch) async {
    batches.add(List.of(batch));
    final pending = gate;
    if (pending != null) return pending.future;
    return result;
  }
}

/// A clock that moves only when told.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 10, 26, 10);
  DateTime now;
  DateTime call() => now;
  void advance(Duration by) => now = now.add(by);
}

/// Periodic timers fired by hand.
class FakeTimers {
  final active = <_FakeTimer>[];
  int started = 0;

  Timer call(Duration interval, void Function() callback) {
    started++;
    final timer = _FakeTimer(callback, active.remove);
    active.add(timer);
    return timer;
  }

  void fire() {
    for (final timer in List.of(active)) {
      timer.callback();
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.callback, this._onCancel);
  final void Function() callback;
  final void Function(_FakeTimer) _onCancel;
  bool _active = true;

  @override
  void cancel() {
    _active = false;
    _onCancel(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
