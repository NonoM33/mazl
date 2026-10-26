import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analytics_event.dart';
import 'analytics_transport.dart';

/// What the member decided about the measurement.
enum AnalyticsConsentState { unknown, granted, denied }

typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function() callback);

Timer _periodic(Duration interval, void Function() callback) =>
    Timer.periodic(interval, (_) => callback());

/// The usage measurement of the app (docs/analytics/plan-de-marquage.md).
///
/// - Consent unknown: events wait in MEMORY (never on disk), 100 at most, with
///   the time they happened. Nothing leaves.
/// - Granted and signed in: the memory is flushed, then events go out in
///   batches (every [flushInterval], at [batchThreshold] waiting events, and
///   when the app goes to the background).
/// - Denied: everything is dropped at once and nothing is kept or sent.
/// - Signed out: the queue is emptied and the consent forgotten.
class Analytics {
  Analytics({
    required AnalyticsTransport transport,
    DateTime Function()? clock,
    PeriodicTimerFactory? periodicTimer,
    this.flushInterval = const Duration(seconds: 10),
  }) : _transport = transport,
       _clock = clock ?? DateTime.now,
       _periodicTimer = periodicTimer ?? _periodic;

  static const maxPending = 100;
  static const batchThreshold = 20;

  /// The server takes 50 events per request.
  static const maxBatch = 50;

  final AnalyticsTransport _transport;
  final DateTime Function() _clock;
  final PeriodicTimerFactory _periodicTimer;
  final Duration flushInterval;

  final List<QueuedEvent> _queue = [];
  AnalyticsConsentState _consent = AnalyticsConsentState.unknown;
  bool _signedIn = false;
  bool _flushing = false;
  Timer? _timer;

  AnalyticsConsentState get consent => _consent;

  @visibleForTesting
  int get pendingCount => _queue.length;

  bool get _canSend => _consent == AnalyticsConsentState.granted && _signedIn;

  /// Records [event] (a `null` one, refused by its formats, is ignored).
  void track(AnalyticsEvent? event) {
    if (event == null || _consent == AnalyticsConsentState.denied) return;
    _queue.add(QueuedEvent(event, _clock().toUtc()));
    _trim();
    if (_canSend && _queue.length >= batchThreshold) unawaited(flush());
  }

  /// The member is signed in.
  void signedIn() {
    _signedIn = true;
    _syncTimer();
  }

  /// The member signed out: nothing of the previous member stays.
  void signedOut() {
    _signedIn = false;
    _consent = AnalyticsConsentState.unknown;
    _queue.clear();
    _syncTimer();
  }

  /// The consent read from the server. A consent that was already on file is
  /// not announced again; "never asked" (`null`) keeps the events waiting.
  void consentLoaded({required bool? granted}) {
    if (granted == null) {
      if (_consent != AnalyticsConsentState.unknown) {
        _consent = AnalyticsConsentState.unknown;
        _syncTimer();
      }
      return;
    }
    _apply(granted);
  }

  /// The member has just answered the question (or changed their mind).
  void consentDecided({required bool granted}) {
    final wasGranted = _consent == AnalyticsConsentState.granted;
    _apply(granted);
    if (granted && !wasGranted) {
      final first = AnalyticsEvent.analyticsConsentGranted();
      if (first != null) {
        _queue.insert(0, QueuedEvent(first, _clock().toUtc()));
        _trim();
      }
      unawaited(flush());
    }
  }

  /// Sends what waits, batch after batch, until empty or until one fails.
  Future<void> flush() async {
    if (_flushing || !_canSend) return;
    _flushing = true;
    try {
      while (_canSend && _queue.isNotEmpty) {
        final batch = _queue.take(maxBatch).toList();
        final result = await _send(batch);
        if (!_canSend) return;
        if (result == AnalyticsSendResult.retry) {
          _trim();
          return;
        }
        _queue.removeWhere(batch.contains);
      }
    } finally {
      _flushing = false;
    }
  }

  /// The app leaves the foreground.
  Future<void> onBackground() => flush();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<AnalyticsSendResult> _send(List<QueuedEvent> batch) async {
    try {
      return await _transport.send(batch);
    } catch (e) {
      debugPrint('Analytics send error: ${e.runtimeType}');
      return AnalyticsSendResult.retry;
    }
  }

  void _apply(bool granted) {
    if (granted) {
      _consent = AnalyticsConsentState.granted;
    } else {
      _consent = AnalyticsConsentState.denied;
      _queue.clear();
    }
    _syncTimer();
  }

  void _trim() {
    final extra = _queue.length - maxPending;
    if (extra > 0) _queue.removeRange(0, extra);
  }

  void _syncTimer() {
    if (_canSend) {
      _timer ??= _periodicTimer(flushInterval, () => unawaited(flush()));
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }
}
