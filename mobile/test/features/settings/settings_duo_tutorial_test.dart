import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/di/providers/link_providers.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../couple/couple_flow_fakes.dart';

final _container = ProviderContainer(
  overrides: [
    externalLinkOpenerProvider.overrideWithValue((uri) async => true),
  ],
);

/// L'entrée « MAZL sur iPhone Duo » des Réglages : sur le Duo seulement, et
/// elle rouvre le tutoriel.
void main() {
  late CoupleService couple;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    couple = CoupleService.forTesting(
      api: FakeCoupleApi(),
      pollInterval: const Duration(hours: 1),
    );
  });
  tearDown(() => couple.dispose());

  Future<GoRouter> pumpSettings(WidgetTester tester, FoldState fold) async {
    await couple.initialize();
    CoupleService.instanceForTesting = couple;
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/duo-tutorial',
          builder: (_, _) => const Scaffold(body: Text('route du tutoriel')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: FoldScope(
          state: fold,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: kTestLocale,
            theme: AppTheme.lightTheme,
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return router;
  }

  testWidgets('absente sur un iPhone qui ne se plie pas', (tester) async {
    await pumpSettings(tester, FoldState.unknown);
    expect(find.text('MAZL sur iPhone Duo'), findsNothing);
  });

  testWidgets('présente sur le Duo, dans chaque pose', (tester) async {
    for (final pose in DuoPose.values) {
      await pumpSettings(tester, pose.foldState);
      expect(
        find.text('MAZL sur iPhone Duo'),
        findsOneWidget,
        reason: pose.name,
      );
      expect(find.text('Revoir le tutoriel'), findsOneWidget);
    }
  });

  testWidgets('un appui rouvre le tutoriel, sans suite', (tester) async {
    final router = await pumpSettings(tester, DuoPose.openPortrait.foldState);
    await tester.ensureVisible(find.text('MAZL sur iPhone Duo'));
    await tester.tap(find.text('MAZL sur iPhone Duo'));
    await tester.pumpAndSettle();
    expect(find.text('route du tutoriel'), findsOneWidget);
    expect(router.state.uri.toString(), '/duo-tutorial');
    expect(
      router.canPop(),
      isTrue,
      reason: 'on revient aux Réglages en sortant',
    );
  });
}
