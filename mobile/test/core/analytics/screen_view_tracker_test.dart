import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/analytics/analytics_event.dart';
import 'package:mazl/core/analytics/screen_view_tracker.dart';
import 'package:mazl/core/router/app_router.dart';

import 'analytics_fakes.dart';

Widget _page(String text) => Scaffold(body: Text(text));

GoRouter _router() => GoRouter(
  initialLocation: '/discover',
  routes: [
    GoRoute(
      path: '/discover',
      name: 'discover',
      builder: (_, _) => _page('discover'),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      name: 'chatDetail',
      builder: (_, _) => _page('chat'),
    ),
    // A route nobody named: nothing may be said about it.
    GoRoute(path: '/secret/:id', builder: (_, _) => _page('secret')),
  ],
);

class _Rig {
  _Rig() {
    analytics =
        Analytics(
            transport: transport,
            clock: FakeClock().call,
            periodicTimer: FakeTimers().call,
          )
          ..signedIn()
          ..consentLoaded(granted: true);
  }

  final transport = FakeAnalyticsTransport();
  late final Analytics analytics;

  Future<List<String>> screens() async {
    await analytics.flush();
    return [
      for (final batch in transport.batches)
        for (final queued in batch)
          if (queued.event.name == 'screen_viewed')
            queued.event.properties['screen']! as String,
    ];
  }
}

void main() {
  testWidgets('emits the NAME of the route, never the path', (tester) async {
    final rig = _Rig();
    final router = _router();
    final tracker = ScreenViewTracker(router: router, analytics: rig.analytics)
      ..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/chat/42');
    await tester.pumpAndSettle();

    final screens = await rig.screens();
    expect(screens, ['discover', 'chatDetail']);
    expect(screens.join(), isNot(contains('42')));
    expect(screens.join(), isNot(contains('/')));
    tracker.dispose();
  });

  testWidgets('a route without a name emits nothing', (tester) async {
    final rig = _Rig();
    final router = _router();
    final tracker = ScreenViewTracker(router: router, analytics: rig.analytics)
      ..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/secret/7');
    await tester.pumpAndSettle();

    expect(await rig.screens(), ['discover']);
    tracker.dispose();
  });

  testWidgets('the same screen staying up is counted once', (tester) async {
    final rig = _Rig();
    final router = _router();
    final tracker = ScreenViewTracker(router: router, analytics: rig.analytics)
      ..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/discover');
    await tester.pumpAndSettle();
    router.refresh();
    await tester.pumpAndSettle();
    router.go('/chat/1');
    await tester.pumpAndSettle();
    router.go('/chat/2');
    await tester.pumpAndSettle();

    expect(await rig.screens(), ['discover', 'chatDetail']);
    tracker.dispose();
  });

  testWidgets('coming back to a screen counts again', (tester) async {
    final rig = _Rig();
    final router = _router();
    final tracker = ScreenViewTracker(router: router, analytics: rig.analytics)
      ..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/chat/1');
    await tester.pumpAndSettle();
    router.go('/discover');
    await tester.pumpAndSettle();

    expect(await rig.screens(), ['discover', 'chatDetail', 'discover']);
    tracker.dispose();
  });

  testWidgets('a stopped tracker says nothing more', (tester) async {
    final rig = _Rig();
    final router = _router();
    final tracker = ScreenViewTracker(router: router, analytics: rig.analytics)
      ..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    tracker.dispose();

    router.go('/chat/1');
    await tester.pumpAndSettle();

    expect(await rig.screens(), ['discover']);
  });

  test('every named route of the real router is a valid screen name', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final names = <String>{};
    void collect(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute && route.name != null) names.add(route.name!);
        if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            collect(branch.routes);
          }
        }
        collect(route.routes);
      }
    }

    collect(router.configuration.routes);
    expect(names, isNotEmpty);
    for (final name in names) {
      expect(
        AnalyticsEvent.screenViewed(name),
        isNotNull,
        reason: '"$name" would be dropped by the formats of the plan',
      );
    }
  });
}
