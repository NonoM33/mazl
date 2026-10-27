import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storefront_models.dart';
import 'storefront_repository.dart';

/// What the app knows of the storefront. [tick] changes when time alone changes
/// what is true (a campaign that ends), so that watchers rebuild.
class StorefrontState {
  const StorefrontState({this.raw, this.tick = 0});

  /// The last answer, kept or fresh; null until there is one.
  final Storefront? raw;
  final int tick;

  /// The answer as of now: a campaign that is over is gone.
  Storefront get current => (raw ?? Storefront.empty).at(clock.now());
}

/// Loads the storefront at launch, again on return to the foreground and at
/// the next change announced by the server.
class StorefrontController extends StateNotifier<StorefrontState> {
  StorefrontController(
    this._repository, {
    this.minimumInterval = const Duration(seconds: 30),
    this.changeMargin = const Duration(seconds: 5),
    this.staleRetry = const Duration(seconds: 65),
  }) : super(const StorefrontState());

  final StorefrontRepository _repository;

  /// A refresh on return to the foreground waits this long after the last one.
  final Duration minimumInterval;

  /// The refresh at `nextChangeAt` comes this much later, for the clocks.
  final Duration changeMargin;

  /// The server caches its answer; when the change it announced is not in it
  /// yet, ask again after this delay.
  final Duration staleRetry;

  static const _maxStaleRetries = 3;

  Timer? _timer;
  DateTime? _lastAttempt;
  String _languageCode = 'fr';
  int _staleRetries = 0;
  bool _started = false;

  /// Counts the requests: an answer to an older one, arriving late, does not
  /// replace a newer one (the launch read, overtaken by a sign-in).
  int _requests = 0;

  /// Reads the answer kept on the phone, then the server's.
  Future<void> start(String languageCode) async {
    if (_started) return;
    _started = true;
    _languageCode = languageCode;
    final cached = await _repository.cached();
    if (!mounted) return;
    if (cached != null && state.raw == null) {
      state = StorefrontState(raw: cached, tick: state.tick);
      _schedule();
    }
    await refresh(languageCode: languageCode, force: true);
  }

  /// Asks the server. Without [force], not sooner than [minimumInterval] after
  /// the previous attempt. A failure keeps what is shown.
  Future<void> refresh({String? languageCode, bool force = false}) async {
    if (languageCode != null) _languageCode = languageCode;
    final now = clock.now();
    final last = _lastAttempt;
    if (!force && last != null && now.difference(last) < minimumInterval) {
      return;
    }
    _lastAttempt = now;
    final request = ++_requests;
    final fetched = await _repository.fetch(languageCode: _languageCode);
    if (!mounted || request != _requests) return;
    if (fetched != null) {
      state = StorefrontState(raw: fetched, tick: state.tick + 1);
    } else {
      // Time may have ended the campaign shown: let the watchers re-read.
      state = StorefrontState(raw: state.raw, tick: state.tick + 1);
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final next = state.raw?.nextChangeAt;
    if (next == null) return;
    final wait = next.difference(clock.now());
    if (wait.isNegative || wait == Duration.zero) {
      // The announced change is behind us and the answer still carries it:
      // the server's cache has not moved yet.
      if (_staleRetries < _maxStaleRetries) {
        _staleRetries++;
        _timer = Timer(staleRetry, () => refresh(force: true));
      }
      return;
    }
    _staleRetries = 0;
    _timer = Timer(wait + changeMargin, () => refresh(force: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
