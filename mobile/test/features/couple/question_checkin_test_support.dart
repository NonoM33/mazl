import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import 'couple_flow_fakes.dart';

/// A couple service that knows a couple whose partner is Noémie (id 12).
Future<CoupleService> coupleOf({
  String? partnerName = 'Noémie',
  bool inCouple = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = FakeCoupleApi()
    ..couple = inCouple ? contractCouple(partnerName: partnerName ?? '') : null;
  final service = CoupleService.forTesting(
    api: api,
    pollInterval: const Duration(days: 1),
  );
  await service.refresh();
  addTearDown(service.dispose);
  return service;
}

CoupleDailyApi apiOn(CoupleTransport transport) =>
    CoupleDailyApi(transport: transport, callerId: () => 12);

/// Runs [home] on a phone-sized window (one column).
Future<void> pumpPhone(
  WidgetTester tester,
  Widget home, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: home,
    ),
  );
  await settle(tester);
}

/// Runs [home] as the route `/here`, with a recorder at `/there`.
Future<List<String>> pumpRouted(
  WidgetTester tester,
  Widget home, {
  required List<String> targets,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final visited = <String>[];
  final router = GoRouter(
    initialLocation: '/here',
    routes: [
      GoRoute(path: '/here', builder: (_, _) => home),
      for (final target in targets)
        GoRoute(
          path: target,
          builder: (_, _) {
            visited.add(target);
            return const Scaffold(body: Text('elsewhere'));
          },
        ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      routerConfig: router,
    ),
  );
  await settle(tester);
  return visited;
}

/// Runs [home] in the iPhone Duo [pose].
Future<DuoPoseController> pumpInPose(
  WidgetTester tester,
  DuoPose pose,
  Widget home, {
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(controller),
      home: ContentMaxWidth(child: home),
    ),
  );
  await settle(tester);
  return controller;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
}

Rect rectOf(WidgetTester tester, Finder finder) {
  expect(finder, findsAtLeastNWidgets(1), reason: finder.toString());
  return tester.getRect(finder.first);
}

bool buttonEnabled(WidgetTester tester, Finder button) =>
    tester.widget<ElevatedButton>(button).onPressed != null;
