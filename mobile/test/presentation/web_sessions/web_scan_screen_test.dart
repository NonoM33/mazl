import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/web_sessions/web_sessions_api.dart';
import 'package:mazl/presentation/features/web_sessions/screens/web_scan_screen.dart';
import 'package:mazl/presentation/features/web_sessions/widgets/qr_scanner_view.dart';
import 'package:mazl/l10n/l10n.dart';

import 'web_sessions_fakes.dart';

const _qr = 'mazl-web:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO-_';

late bool? _popped;

Future<void> _open(
  WidgetTester tester,
  FakeWebSessionsApi api,
  FakeCamera camera,
) async {
  _popped = null;
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async => _popped = await context.push<bool>('/scan'),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(path: '/scan', builder: (_, _) => const WebScanScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        webSessionsApiProvider.overrideWithValue(api),
        qrScannerBuilderProvider.overrideWithValue(camera.build),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the instruction', (tester) async {
    await _open(tester, FakeWebSessionsApi(), FakeCamera());

    expect(
      find.text('Scannez le QR code affiché sur app.mazl.app'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a non-MAZL code shows a discreet message and never calls the server',
    (tester) async {
      final api = FakeWebSessionsApi();
      final camera = FakeCamera();
      await _open(tester, api, camera);

      camera.emit('https://example.com/promo');
      await tester.pumpAndSettle();

      expect(find.text('Ce QR code n\'est pas un code MAZL.'), findsOneWidget);
      expect(api.calls, isEmpty);
      expect(find.text('Connecter cet ordinateur ?'), findsNothing);
    },
  );

  testWidgets(
    'a valid code opens the confirmation, Connecter approves and closes',
    (tester) async {
      final api = FakeWebSessionsApi();
      final camera = FakeCamera();
      await _open(tester, api, camera);

      camera.emit(_qr);
      await tester.pumpAndSettle();

      expect(api.calls, ['scan:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO-_']);
      expect(find.text('Connecter cet ordinateur ?'), findsOneWidget);
      expect(find.text('Chrome sur macOS'), findsOneWidget);
      // Security review B6: where the request comes from, masked.
      expect(find.text('198.51.100.x'), findsOneWidget);
      expect(find.text('14 h 05'), findsOneWidget);
      expect(
        find.textContaining(
          'Si quelqu\'un vous demande de scanner un code, refusez.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Connecter'));
      await tester.pumpAndSettle();

      expect(api.calls.last, 'approve:p1');
      expect(_popped, isTrue);
    },
  );

  testWidgets('Refuser denies and keeps reading', (tester) async {
    final api = FakeWebSessionsApi();
    final camera = FakeCamera();
    await _open(tester, api, camera);

    camera.emit(_qr);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    expect(api.calls.last, 'deny:p1');
    expect(find.byType(WebScanScreen), findsOneWidget);
    expect(_popped, isNull);
  });

  testWidgets('an expired code says so', (tester) async {
    final api = FakeWebSessionsApi()
      ..scanResult = ApiResponse.failure(
        WebSessionsError.pairingNotFound,
        ApiErrorKind.server,
      );
    final camera = FakeCamera();
    await _open(tester, api, camera);

    camera.emit(_qr);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ce code a expiré. Affichez un nouveau code sur l\'ordinateur.',
      ),
      findsOneWidget,
    );
    expect(find.text('Connecter cet ordinateur ?'), findsNothing);
  });

  testWidgets('only one reading is handled at a time and a repeat is ignored', (
    tester,
  ) async {
    final api = FakeWebSessionsApi()
      ..scanResult = ApiResponse.failure(
        WebSessionsError.pairingNotFound,
        ApiErrorKind.server,
      );
    final camera = FakeCamera();
    await withClock(Clock.fixed(DateTime(2026, 10, 24, 12)), () async {
      await _open(tester, api, camera);
      camera
        ..emit(_qr)
        ..emit(_qr);
      await tester.pumpAndSettle();
      camera.emit(_qr);
      await tester.pumpAndSettle();
    });

    expect(api.calls.where((c) => c.startsWith('scan:')), hasLength(1));
  });

  testWidgets('a stale approval (409) is explained', (tester) async {
    final api = FakeWebSessionsApi()
      ..approveResult = ApiResponse.failure(
        WebSessionsError.pairingNotPending,
        ApiErrorKind.server,
      );
    final camera = FakeCamera();
    await _open(tester, api, camera);

    camera.emit(_qr);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connecter'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cette demande n\'est plus valide'),
      findsOneWidget,
    );
    expect(_popped, isNull);
  });
}
