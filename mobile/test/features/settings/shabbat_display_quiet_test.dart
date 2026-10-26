import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/push_gateway.dart';
import 'package:mazl/core/services/quiet_display.dart';
import 'package:mazl/core/services/websocket_service.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/core/layout/side_safe_area.dart';
import 'package:mazl/core/widgets/quiet_backdrop.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_flow_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../couple/couple_flow_fakes.dart';

// Pendant l'affichage Shabbat, rien de l'app ne s'allume, ne sonne ni ne
// bouge : ni bannière de notification, ni fenêtre de demande de couple, ni
// message, ni redirection.

void main() {
  group('les notifications qui arrivent app ouverte', () {
    test('affichées en temps normal', () {
      final calls = <String>[];

      routeForegroundNotification(
        QuietDisplay(),
        display: () => calls.add('display'),
        discard: () => calls.add('discard'),
      );

      expect(calls, ['display']);
    });

    test('écartées pendant l\'affichage : ni bannière ni son', () {
      final quiet = QuietDisplay()..enter();
      final calls = <String>[];

      routeForegroundNotification(
        quiet,
        display: () => calls.add('display'),
        discard: () => calls.add('discard'),
      );

      expect(calls, ['discard']);
    });

    test('affichées de nouveau une fois l\'affichage fermé', () {
      final quiet = QuietDisplay()
        ..enter()
        ..leave();
      final calls = <String>[];

      routeForegroundNotification(
        quiet,
        display: () => calls.add('display'),
        discard: () => calls.add('discard'),
      );

      expect(calls, ['display']);
    });
  });

  group('le flux du couple attend la fin de l\'affichage', () {
    late FakeCoupleApi api;
    late CoupleService service;
    late StreamController<ChatEvent> realtime;
    late QuietDisplay quiet;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      api = FakeCoupleApi();
      service = CoupleService.forTesting(
        api: api,
        pollInterval: const Duration(hours: 1),
      );
      realtime = StreamController<ChatEvent>.broadcast();
      quiet = QuietDisplay();
    });

    tearDown(() async {
      service.dispose();
      await realtime.close();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: navigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('PAGE')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          routerConfig: router,
          builder: (context, child) => CoupleFlowHost(
            service: service,
            router: router,
            navigatorKey: navigatorKey,
            realtime: realtime.stream,
            auth: ValueNotifier<int>(0),
            isAuthenticated: () => true,
            quiet: quiet,
            child: child!,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    CoupleRealtimeEvent request() => CoupleRealtimeEvent(
      type: 'couple:request',
      payload: {'request': contractReceivedRequest()},
    );

    testWidgets('sans affichage, la demande ouvre sa fenêtre', (tester) async {
      await pumpApp(tester);

      realtime.add(request());
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Myriam souhaite activer le mode couple avec vous'),
        findsOneWidget,
      );
    });

    testWidgets('pendant l\'affichage, aucune fenêtre ; elle s\'ouvre à la '
        'sortie', (tester) async {
      await pumpApp(tester);
      quiet.enter();

      realtime.add(request());
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Myriam souhaite activer le mode couple avec vous'),
        findsNothing,
      );
      expect(find.byType(Dialog), findsNothing);

      quiet.leave();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Myriam souhaite activer le mode couple avec vous'),
        findsOneWidget,
      );
    });

    testWidgets('pendant l\'affichage, aucun message en bas d\'écran', (
      tester,
    ) async {
      await pumpApp(tester);
      await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');
      quiet.enter();

      realtime.add(
        CoupleRealtimeEvent(
          type: 'couple:rejected',
          payload: {'request_id': 77},
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsNothing);

      quiet.leave();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('le fond de l\'app suit la nuit de l\'affichage', () {
    Future<QuietDisplay> pumpShell(WidgetTester tester) async {
      final quiet = QuietDisplay();
      final controller = DuoPoseController(DuoPose.tent);
      setDuoPose(tester, DuoPose.tent);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          builder: (context, child) => QuietBackdrop(
            quiet: quiet,
            child: duoAppBuilder(controller)(context, child),
          ),
          home: const _Counter(),
        ),
      );
      await settleFold(tester);
      return quiet;
    }

    /// La couleur de la colonne de la barre d'état, que l'app remplit avec le
    /// fond de la page.
    Color column(WidgetTester tester) => tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(SideSafeArea),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;

    testWidgets('la colonne de la caméra devient noire, puis reprend le jour', (
      tester,
    ) async {
      final quiet = await pumpShell(tester);
      final day = AppTheme.lightTheme.scaffoldBackgroundColor;
      expect(column(tester), day);
      expect(day.computeLuminance(), greaterThan(0.5));

      quiet.enter();
      await tester.pump();
      expect(column(tester), AppColors.shabbatDisplayBackground);

      quiet.leave();
      await tester.pump();
      expect(column(tester), day);
    });

    testWidgets('l\'écran dessous ne perd rien : la navigation garde son '
        'état', (tester) async {
      final quiet = await pumpShell(tester);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('3'), findsNothing);
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      quiet.enter();
      await tester.pump();
      quiet.leave();
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });
  });
}

/// Un écran avec un état à lui : s'il se reconstruisait, le compte
/// repartirait de zéro.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('$_count')),
    floatingActionButton: ElevatedButton(
      onPressed: () => setState(() => _count++),
      child: const Text('+'),
    ),
  );
}
