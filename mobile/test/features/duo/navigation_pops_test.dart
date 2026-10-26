import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/router/app_router.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';

// Renaud on 2026-10-27: on the foldable iPhone closed, the back button of a
// screen is at the top of the vertical bar. The bar is drawn above the
// navigator: the button must still pop THIS screen (a button that looks up the
// navigator from where the bar is drawn would do nothing). Each case opens a
// screen on top of another through the real router, taps the button in the
// column and expects to be back on the screen below.

class _Case {
  const _Case(this.name, this.below, this.screen, this.back);

  final String name;
  final String below;
  final String screen;

  /// The button, as the member finds it.
  final String back;
}

const _cases = [
  _Case(
    'profile of another member',
    '/discover',
    '/discover/profile/201',
    'Retour',
  ),
  _Case('conversation', '/chat', '/chat/101', 'Retour'),
  _Case(
    'settings page with an app bar',
    '/profile',
    '/profile/settings/analytics',
    'Retour',
  ),
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _run(WidgetTester tester, DuoPose pose, _Case scenario) async {
  setDuoPose(tester, pose);
  await AuthService().signInAsDemo();
  final container = ProviderContainer(
    overrides: [
      privacyConsentApiProvider.overrideWithValue(
        FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
      ),
    ],
  );
  final router = container.read(appRouterProvider)..go(scenario.below);
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
          builder: duoAppBuilder(DuoPoseController(pose)),
        ),
      ),
    );
    await _settle(tester);
    await settleFold(tester);
    expect(router.state.uri.path, scenario.below);

    router.push(scenario.screen);
    await _settle(tester);
    await settleFold(tester);
    expect(router.state.uri.path, scenario.screen);

    // An icon button says « Retour » by its tooltip, a round one by its label.
    final back = find
        .byWidgetPredicate(
          (widget) =>
              (widget is Tooltip && widget.message == scenario.back) ||
              (widget is Semantics &&
                  (widget.properties.button ?? false) &&
                  widget.properties.label == scenario.back),
        )
        .hitTestable()
        .first;
    expect(back, findsOneWidget, reason: 'a back button on the screen');
    final column = pose.verticalBar!.controls.inflate(0.5);
    final rect = tester.getRect(back);
    expect(
      column.contains(rect.topLeft) && column.contains(rect.bottomRight),
      isTrue,
      reason: 'back at $rect, column $column',
    );

    await tester.tap(back);
    await _settle(tester);
    expect(
      router.state.uri.path,
      scenario.below,
      reason: 'the button of the column did not pop the screen',
    );
    await tester.pumpWidget(const SizedBox());
    container.invalidate(chatControllerProvider);
    await tester.pump(const Duration(seconds: 1));
  } finally {
    router.dispose();
  }
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await CoupleService().reset();
    DevSession.stop();
  });

  for (final scenario in _cases) {
    for (final pose in [DuoPose.closed, DuoPose.tent]) {
      testWidgets('${scenario.name}, ${pose.name}: back is in the column and '
          'pops the screen', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await http.runWithClient(
            () => _run(tester, pose, scenario),
            () => DemoHttpClient(
              MockClient((r) async => fail('real network reached: ${r.url}')),
              latency: Duration.zero,
            ),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
