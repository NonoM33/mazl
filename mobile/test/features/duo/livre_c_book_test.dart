import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:mazl/core/router/app_router.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/verification/screens/verification_sections.dart';
import 'package:mazl/presentation/features/web_sessions/widgets/qr_scanner_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';
import '../../presentation/web_sessions/web_sessions_fakes.dart';

/// Runs [body] in the demo session, offline, on iOS (the tabs then sit in the
/// vertical bar), as the sweep of every screen does.
Future<T> _inDemo<T>(Future<T> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    return await http.runWithClient(
      body,
      () => DemoHttpClient(
        MockClient((r) async => fail('real network reached: ${r.url}')),
        latency: Duration.zero,
      ),
    );
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<DuoPoseController> _open(
  WidgetTester tester,
  String path,
  DuoPose pose, {
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  await AuthService().signInAsDemo();
  final container = ProviderContainer(
    overrides: [
      privacyConsentApiProvider.overrideWithValue(
        FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
      ),
      webSessionsApiProvider.overrideWithValue(
        FakeWebSessionsApi(sessions: [fakeSession('s1')]),
      ),
      qrScannerBuilderProvider.overrideWithValue(
        (context, onCode) =>
            const ColoredBox(key: Key('camera'), color: Colors.black),
      ),
    ],
  );
  final router = container.read(appRouterProvider)..go(path);
  final controller = DuoPoseController(pose);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: router,
        builder: duoAppBuilder(controller),
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await CoupleService().reset();
    DevSession.stop();
  });

  final fold = DuoPose.halfOpenBook.fold!;

  /// [finder] lies wholly on the page where the reading starts (LTR: left).
  void expectStartPage(WidgetTester tester, Finder finder, String what) {
    expect(finder, findsOneWidget, reason: what);
    expect(
      tester.getRect(finder).right,
      lessThanOrEqualTo(fold.left),
      reason: '$what is not on the start page',
    );
  }

  /// [finder] lies wholly on the other page (LTR: right).
  void expectEndPage(WidgetTester tester, Finder finder, String what) {
    expect(finder, findsOneWidget, reason: what);
    expect(
      tester.getRect(finder).left,
      greaterThanOrEqualTo(fold.right),
      reason: '$what is not on the end page',
    );
  }

  Future<DuoPoseController> book(WidgetTester tester, String path) =>
      _inDemo(() => _open(tester, path, DuoPose.halfOpenBook));

  testWidgets('/profile: photos and identity, then the rest', (tester) async {
    await book(tester, '/profile');
    expectStartPage(tester, find.text('MON PROFIL'), 'the title row');
    expectStartPage(tester, find.text('Modifier'), 'the edit button');
    expectEndPage(tester, find.text('Complétez votre profil'), 'the card');
  });

  testWidgets('/profile flat: the completion card stays above the identity', (
    tester,
  ) async {
    await _inDemo(() => _open(tester, '/profile', DuoPose.openPortrait));
    final card = tester.getRect(find.text('Complétez votre profil'));
    final photos = tester.getRect(find.text('Ajouter des photos'));
    expect(card.left, lessThan(fold.left), reason: 'one column');
    expect(card.top, greaterThan(photos.bottom), reason: 'order unchanged');
  });

  testWidgets('/profile/edit: photos and bio, then prompts and fields', (
    tester,
  ) async {
    await book(tester, '/profile/edit');
    expectStartPage(tester, find.text('Photos'), 'the photos');
    expectStartPage(tester, find.text('À propos'), 'the bio');
    expectEndPage(tester, find.text('Mes Prompts'), 'the prompts');
    expectEndPage(tester, find.text('Ce que je recherche'), 'the intention');
  });

  testWidgets('/profile/edit: what was typed survives folding', (tester) async {
    final pose = await book(tester, '/profile/edit');
    await tester.enterText(find.byType(TextFormField).first, 'Bonjour Jeanne');
    await pose.moveTo(tester, DuoPose.openLandscape);
    expect(find.text('Bonjour Jeanne'), findsOneWidget);
    await pose.moveTo(tester, DuoPose.halfOpenBook);
    expect(find.text('Bonjour Jeanne'), findsOneWidget);
  });

  testWidgets('/profile/settings: account on one page, the rest on the other', (
    tester,
  ) async {
    await book(tester, '/profile/settings');
    expectStartPage(tester, find.text('COMPTE'), 'the account section');
    expectStartPage(tester, find.text('DÉCOUVERTE'), 'discovery');
    expectEndPage(tester, find.text('MODE COUPLE'), 'the couple section');
    expectEndPage(tester, find.text('CONFIDENTIALITÉ ET SÉCURITÉ'), 'privacy');
  });

  testWidgets('/profile/settings flat: one column in the same order', (
    tester,
  ) async {
    await _inDemo(
      () => _open(tester, '/profile/settings', DuoPose.openPortrait),
    );
    final account = tester.getRect(find.text('COMPTE'));
    final couple = tester.getRect(find.text('MODE COUPLE'));
    expect(couple.left, account.left);
    expect(couple.top, greaterThan(account.bottom));
  });

  testWidgets('/profile/settings/computers: connect, then the computers', (
    tester,
  ) async {
    await book(tester, '/profile/settings/computers');
    expectStartPage(tester, find.text('MAZL SUR ORDINATEUR'), 'the label');
    expectStartPage(tester, find.text('Connecter un ordinateur'), 'connect');
    expectEndPage(tester, find.text('Chrome sur macOS'), 'the computer');
    expectEndPage(
      tester,
      find.text('Déconnecter tous les ordinateurs'),
      'disconnect all',
    );
  });

  testWidgets('/profile/settings/computers/scan: explanation beside camera', (
    tester,
  ) async {
    await book(tester, '/profile/settings/computers/scan');
    expectStartPage(
      tester,
      find.text('Scannez le QR code affiché sur app.mazl.app'),
      'the explanation',
    );
    expectStartPage(tester, find.byTooltip('Fermer'), 'the close button');
    expectEndPage(tester, find.byKey(const Key('camera')), 'the camera');
  });

  testWidgets('/profile/settings/computers/scan flat: text over the camera', (
    tester,
  ) async {
    await _inDemo(
      () => _open(
        tester,
        '/profile/settings/computers/scan',
        DuoPose.openPortrait,
      ),
    );
    final camera = tester.getRect(find.byKey(const Key('camera')));
    final text = tester.getRect(
      find.text('Scannez le QR code affiché sur app.mazl.app'),
    );
    expect(camera.contains(text.center), isTrue);
  });

  testWidgets('/profile/settings/religious-data: the text, then the choice', (
    tester,
  ) async {
    await book(tester, '/profile/settings/religious-data');
    expectStartPage(tester, find.text('Accord donné'), 'the state');
    expectEndPage(tester, find.text('Retirer mon accord'), 'the button');
  });

  testWidgets('/profile/settings/shabbat: the times, then how they are set', (
    tester,
  ) async {
    await book(tester, '/profile/settings/shabbat');
    expectStartPage(tester, find.text('ALLUMAGE'), 'candle lighting');
    expectStartPage(tester, find.text('HAVDALA'), 'havdalah');
    expectEndPage(
      tester,
      find.textContaining('havdala à la tombée de la nuit'),
      'the explanation',
    );
    expect(find.text("Lancer l'affichage"), findsNothing);
  });

  testWidgets('/profile/verification: level 1, then level 2', (tester) async {
    await book(tester, '/profile/verification');
    expectStartPage(tester, find.text('Vérification'), 'the title');
    expectStartPage(tester, find.text('NIVEAU 1'), 'level 1');
    expectEndPage(tester, find.text('NIVEAU 2'), 'level 2');
    expectEndPage(tester, find.text('Vérifier mon identité'), 'the button');
  });

  testWidgets('/profile/verification in Hebrew: level 1 on the right', (
    tester,
  ) async {
    await _inDemo(
      () => _open(
        tester,
        '/profile/verification',
        DuoPose.halfOpenBook,
        locale: const Locale('he'),
      ),
    );
    final level1 = tester.getRect(find.byType(PhotoLevel));
    final level2 = tester.getRect(find.byType(IdentityLevel));
    expect(level1.left, greaterThanOrEqualTo(fold.right));
    expect(level2.right, lessThanOrEqualTo(fold.left));
  });
}
