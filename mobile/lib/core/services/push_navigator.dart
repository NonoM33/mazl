import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';
import 'push_destination.dart';

/// Opens the screen of a tapped push notification, as soon as the app can show
/// it: on a cold start the notification is delivered before the router exists
/// and before the member is signed in, so it waits (a short while) for both.
class PushNavigator {
  PushNavigator({
    required this.isReady,
    required this.open,
    this.retryEvery = const Duration(milliseconds: 500),
    this.giveUpAfter = const Duration(seconds: 30),
  });

  /// True when the router is mounted and the member is on a screen of the app.
  final bool Function() isReady;

  /// Goes to a path of the app.
  final void Function(String path) open;

  final Duration retryEvery;

  /// A notification the app could not open by then is out of date.
  final Duration giveUpAfter;

  String? _pending;
  Timer? _timer;
  Duration _waited = Duration.zero;

  /// Opens what [data] points to, now or once the app is ready. The last
  /// notification tapped wins. Nothing happens for a type that leads nowhere.
  void handle(Map<String, dynamic> data) {
    final path = pushDestination(data);
    if (path == null) return;
    _pending = path;
    _waited = Duration.zero;
    if (_openPending()) return;
    _timer ??= Timer.periodic(retryEvery, (_) => _retry());
  }

  void _retry() {
    _waited += retryEvery;
    if (_openPending() || _waited >= giveUpAfter) _stopWaiting();
  }

  bool _openPending() {
    final path = _pending;
    if (path == null) return true;
    if (!isReady()) return false;
    _pending = null;
    _stopWaiting();
    open(path);
    return true;
  }

  void _stopWaiting() {
    _timer?.cancel();
    _timer = null;
    if (_waited >= giveUpAfter) _pending = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}

/// The real router of the app, seen from the root navigator.
class RouterPushTarget {
  RouterPushTarget({required this.navigatorKey, required this.isAuthenticated});

  final GlobalKey<NavigatorState> navigatorKey;
  final bool Function() isAuthenticated;

  /// Screens a member passes through before the app proper.
  static const _beforeTheApp = [
    RoutePaths.splash,
    RoutePaths.onboarding,
    RoutePaths.login,
    RoutePaths.profileSetup,
  ];

  GoRouter? get _router {
    final context = navigatorKey.currentContext;
    return context == null ? null : GoRouter.maybeOf(context);
  }

  /// Signed in, router mounted, and past the splash, sign-in and profile setup
  /// (their redirects would swallow the destination).
  bool get isReady {
    final router = _router;
    if (router == null || !isAuthenticated()) return false;
    final location = router.routerDelegate.currentConfiguration.uri.path;
    return !_beforeTheApp.contains(location);
  }

  void open(String path) => _router?.go(path);
}
