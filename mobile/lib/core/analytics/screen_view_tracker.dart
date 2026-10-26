import 'package:go_router/go_router.dart';

import 'analytics.dart';
import 'analytics_event.dart';

/// Emits `screen_viewed` each time the router shows another screen, with the
/// NAME of the route (`discover`), never its path: a path may carry the id of
/// a member or a conversation. A route nobody named says nothing.
class ScreenViewTracker {
  ScreenViewTracker({required this.router, required this.analytics});

  final GoRouter router;
  final Analytics analytics;

  String? _last;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    router.routerDelegate.addListener(_onChange);
    _onChange();
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    router.routerDelegate.removeListener(_onChange);
  }

  void _onChange() {
    final configuration = router.routerDelegate.currentConfiguration;
    final route = configuration.isEmpty ? null : configuration.last.route;
    final name = route is GoRoute ? route.name : null;
    if (name == _last) return;
    _last = name;
    if (name != null) analytics.track(AnalyticsEvent.screenViewed(name));
  }
}
