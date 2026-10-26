import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../couple/couple_flow_fakes.dart';

final _sharedContainer = ProviderContainer();

// Seen on 2026-10-26: an account that picked « Un homme » by mistake at sign-up
// could not change who it looks for, and Discover stayed empty. The choice now
// lives in Settings › Discovery too.
void main() {
  late CoupleService couple;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MAZL',
      packageName: 'app.mazl',
      version: '2.3.4',
      buildNumber: '567',
      buildSignature: '',
    );
    couple = CoupleService.forTesting(
      api: FakeCoupleApi(),
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() {
    couple.dispose();
    DemoStore.reset();
  });

  testWidgets('Settings › Discovery changes who the member looks for', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await AuthService().signInAsDemo();
        DemoStore.patchProfile({'lookingFor': 'male'});
        await couple.initialize();
        CoupleService.instanceForTesting = couple;
        tester.view.physicalSize = const Size(390, 3200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _sharedContainer,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: kTestLocale,
              theme: AppTheme.lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final row = find.text('Je recherche');
        expect(row, findsOneWidget);
        expect(find.text('Un homme'), findsOneWidget);

        await tester.tap(row);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('looking-for-female')));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(DemoStore.myProfile()['looking_for'], 'female');
        expect(find.text('Une femme'), findsOneWidget);
      },
      () => DemoHttpClient(
        MockClient((r) async => fail('real network reached: ${r.url}')),
        latency: Duration.zero,
      ),
    );
  });
}
