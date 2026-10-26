import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/router/app_router.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/auth/screens/route_error_screen.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';
import 'package:mazl/presentation/features/web_sessions/widgets/qr_scanner_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';
import '../../presentation/web_sessions/web_sessions_fakes.dart';
import 'duo_known_failures.dart';
import 'duo_screen_catalog.dart';
import 'duo_geometry.dart';
import 'duo_screens.dart';
import 'package:mazl/presentation/features/duo_tutorial/duo_tutorial_providers.dart';

import '../../core/duo_tutorial/fake_duo_scene_renderer.dart';

// Every screen of the app in every posture of the foldable iPhone (iPhone
// Duo), opened by its route through the real router in the demo session
// (offline, synthetic data). Screens that do not fit yet are listed in
// duo_known_failures.dart: a ratchet, the list only shrinks.

/// A route that cannot be measured at all (not a fit problem): the member
/// landed elsewhere, or the screen did not load.
class _NotMeasurable implements Exception {
  _NotMeasurable(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<void> _pumpFor(WidgetTester tester, int millis) async {
  for (var elapsed = 0; elapsed < millis; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Runs [action] to its end while time moves on in the test.
Future<T> _whileTimePasses<T>(WidgetTester tester, Future<T> action) async {
  var done = false;
  final result = action.whenComplete(() => done = true);
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return result;
}

/// Signs in to the demo and, for couple mode, forms the couple with Noémie
/// (301): the demo accepts the request 3 s after it was sent.
Future<void> _signIn(WidgetTester tester, DuoSession session) async {
  if (session == DuoSession.signedOut) return;
  await AuthService().signInAsDemo();
  if (session == DuoSession.couple) {
    DemoRoutes.respond(
      DemoRequest('POST', '/api/couple/request', const {}, const {
        'target_user_id': 301,
      }),
    );
    final later = DateTime.now().add(const Duration(seconds: 10));
    DemoStore.clock = () => later;
    await _whileTimePasses(tester, CoupleService().initialize());
    if (!CoupleService().isCoupleModeEnabled) {
      throw _NotMeasurable('the demo couple did not form');
    }
  }
}

/// What the framework reported while the screen was laid out and drawn.
class _Reports {
  final Set<String> layout = {};
  final Set<String> other = {};

  void add(FlutterErrorDetails details) {
    final text = details.exceptionAsString();
    final where = RegExp(
      r'file:///\S*?/mobile/(lib/[\w/.]+\.dart:\d+)',
    ).firstMatch(details.toDiagnosticsNode().toStringDeep())?.group(1);
    final overflow = RegExp(
      r'overflowed by ([\d.]+) pixels on the (\w+)',
    ).firstMatch(text);
    if (overflow != null) {
      layout.add(
        'overflow of ${overflow.group(1)} pt on the ${overflow.group(2)}'
        '${where == null ? '' : ' at $where'}',
      );
    } else if (RegExp(
      r'RenderBox|constraints|unbounded|RenderFlex|RenderViewport',
    ).hasMatch(text)) {
      layout.add('layout error: ${text.split('\n').first}');
    } else {
      other.add(text.split('\n').first);
    }
  }
}

/// Opens [screen] in [pose] and returns every problem found, one line each.
Future<List<String>> _measure(
  WidgetTester tester,
  DuoScreen screen,
  DuoPose pose,
) async {
  setDuoPose(tester, pose);
  await _signIn(tester, screen.session);
  final container = ProviderContainer(
    overrides: [
      if (screen.session == DuoSession.signedOut)
        isAuthenticatedProvider.overrideWithValue(false),
      // The tutorial's 3D scene is a web view: a fake renderer, as in its own tests.
      duoSceneRendererFactoryProvider.overrideWithValue(
        FakeDuoSceneRenderer.new,
      ),
      // What the demo server does not serve, and the camera.
      privacyConsentApiProvider.overrideWithValue(
        FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
      ),
      webSessionsApiProvider.overrideWithValue(
        FakeWebSessionsApi(
          sessions: [
            fakeSession('s1'),
            fakeSession('s2', browser: 'Safari sur iPad'),
          ],
        ),
      ),
      qrScannerBuilderProvider.overrideWithValue(
        (context, onCode) => const ColoredBox(color: Colors.black),
      ),
    ],
  );
  // The container is never closed: it would dispose the app's single
  // AuthService and CoupleService (same as profile_setup_duo_test). Only the
  // router is, so that it stops listening to them.
  final router = container.read(appRouterProvider)
    ..go(screen.path, extra: screen.extra);
  final controller = DuoPoseController(pose);

  // Every error of the framework is kept (the test framework would keep the
  // first only), and none fails the test by itself.
  final reports = _Reports();
  final previousHandler = FlutterError.onError;
  FlutterError.onError = reports.add;
  final problems = <String>[];
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          routerConfig: router,
          builder: duoAppBuilder(controller),
        ),
      ),
    );
    await _pumpFor(tester, screen.settleMillis);
    await settleFold(tester);
    if (screen.open != null) {
      await screen.open!(tester);
      await settleFold(tester);
    }
    if (find.byType(RouteErrorScreen).evaluate().isNotEmpty) {
      throw _NotMeasurable('${screen.path} is not a route of the app');
    }
    // The wait of a photo loaded from the network is not the screen loading.
    if (find
        .descendant(
          of: find.byType(Scaffold),
          matching: find.byType(CircularProgressIndicator),
        )
        .evaluate()
        .any(
          (e) => find
              .ancestor(
                of: find.byWidget(e.widget),
                matching: find.byType(CachedNetworkImage),
              )
              .evaluate()
              .isEmpty,
        )) {
      throw _NotMeasurable('${screen.id} is still loading after the wait');
    }
    final landed = router.state.uri.path;
    if (screen.open == null && screen.id != '/' && landed != screen.path) {
      throw _NotMeasurable('${screen.path} redirected to $landed');
    }

    problems.addAll(tappableProblems(tester, pose));
    problems.addAll(foldCrossingProblems(tester, pose));
    final primary = screen.primary?.call();
    if (primary != null) {
      if (primary.evaluate().isNotEmpty) {
        final notInView = primaryProblem(tester, pose, primary);
        if (notInView != null) {
          // The same button, said once.
          final box = RegExp(r' at (\d+,\d+ \d+x\d+)').firstMatch(notInView);
          problems
            ..removeWhere((p) => box != null && p.contains(' at ${box[1]}'))
            ..add(notInView);
        }
      } else if (pose == DuoPose.openPortrait) {
        // The largest posture shows everything: the catalog is wrong.
        throw _NotMeasurable(
          'the main action of ${screen.id} is not on the screen: '
          'the catalog does not find it',
        );
      } else {
        problems.add(
          'the main action is not even laid out: it is below the visible '
          'part of its list',
        );
      }
    }
    if (await scrollListsToTheEnd(tester)) {
      // What did not move shows twice: say it once.
      String boxOf(String line) =>
          RegExp(r' at (\d+,\d+ \d+x\d+)').firstMatch(line)?[1] ?? line;
      final seen = problems.map(boxOf).toSet();
      problems.addAll([
        for (final line in [
          ...tappableProblems(tester, pose),
          ...foldCrossingProblems(tester, pose),
        ])
          if (!seen.contains(boxOf(line))) '$line [at the end of the list]',
      ]);
    }
    problems.insertAll(0, reports.layout);

    // Let the splash and the demo timers run out before the test ends.
    await _pumpFor(tester, 3000);
    await tester.pumpWidget(const SizedBox());
    // The container outlives the test, and so would the conversation's
    // refresh timer.
    container.invalidate(chatControllerProvider);
    await tester.pump(const Duration(seconds: 1));
  } finally {
    FlutterError.onError = previousHandler;
    router.dispose();
  }
  for (final other in reports.other) {
    debugPrint('DUO_EXCEPTION|${screen.id}|${pose.name}|$other');
  }
  return problems;
}

DuoKnownFailure? _known(DuoScreen screen, DuoPose pose) {
  for (final failure in duoKnownFailures) {
    if (failure.screen == screen.id && failure.pose == pose) return failure;
  }
  return null;
}

/// The App Store, as a phone that can pay but has no product: the offer then
/// shows its fallback plans. Without an answer the plugin's channel never
/// replies and the offer stays on its spinner.
void _answerTheStore() {
  const channel =
      'dev.flutter.pigeon.in_app_purchase_storekit.InAppPurchase2API';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();
  messenger
    ..setMockMessageHandler(
      '$channel.canMakePayments',
      (message) async => codec.encodeMessage(<Object?>[true]),
    )
    ..setMockMessageHandler(
      '$channel.products',
      (message) async => codec.encodeMessage(<Object?>[<Object?>[]]),
    );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Real glyph widths: the test font is twice as wide as the app's.
  setUpAll(() async {
    await loadAppFonts();
    _answerTheStore();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    DemoStore.clock = DateTime.now;
    await CoupleService().reset();
    DevSession.stop();
  });

  test('the catalog has every route of the router, and only those', () {
    final container = ProviderContainer();
    final router = container.read(appRouterProvider);
    final declared = <String>{};
    void collect(List<RouteBase> routes, String parent) {
      for (final route in routes) {
        if (route is GoRoute) {
          final path = route.path.startsWith('/')
              ? route.path
              : '$parent/${route.path}';
          declared.add(path);
          collect(route.routes, path);
        } else if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            collect(branch.routes, parent);
          }
        } else {
          collect(route.routes, parent);
        }
      }
    }

    collect(router.configuration.routes, '');
    router.dispose();
    final catalogued = {
      for (final screen in duoScreens)
        if (!screen.id.contains(' > ')) screen.id,
    };
    expect(
      catalogued,
      declared,
      reason: 'add the new route to duo_screen_catalog.dart',
    );
  });

  test(
    'every id of the known failures is a screen and a pose of the crawl',
    () {
      final ids = duoScreens.map((s) => s.id).toSet();
      for (final failure in duoKnownFailures) {
        expect(ids, contains(failure.screen), reason: failure.reason);
      }
      expect(ids.length, duoScreens.length, reason: 'duplicate screen id');
    },
  );

  for (final screen in duoScreens) {
    for (final pose in DuoPose.values) {
      testWidgets('${screen.id} in ${pose.name}', (tester) async {
        // On iOS the shell puts the tabs in the vertical bar. The override
        // must be gone before the test ends, so not in a tearDown.
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final List<String> problems;
        try {
          problems = await http.runWithClient(
            () => _measure(tester, screen, pose),
            () => DemoHttpClient(
              MockClient((r) async => fail('real network reached: ${r.url}')),
              latency: Duration.zero,
            ),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        for (final problem in problems) {
          debugPrint('DUO_FAILURE|${screen.id}|${pose.name}|$problem');
        }
        final known = _known(screen, pose);
        if (known == null) {
          expect(
            problems,
            isEmpty,
            reason:
                '${screen.id} does not fit ${pose.name}. Fix the screen; '
                'if it cannot be fixed now, list it in duo_known_failures.dart',
          );
        } else {
          expect(
            problems,
            isNotEmpty,
            reason:
                '${screen.id} fits ${pose.name} now: delete its line '
                '(${known.reason}) from duo_known_failures.dart',
          );
        }
      });
    }
  }
}
