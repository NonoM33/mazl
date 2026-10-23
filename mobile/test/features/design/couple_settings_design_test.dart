import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../couple/couple_flow_fakes.dart';

// Rendering of the settings (couple card + hidden sections) in the
// « Encre & Tekhelet » look: no overflow at 390x844 and 360x740, light and dark.

final _sharedContainer = ProviderContainer();

enum _State { inCouple, pending, single }

const _sizes = [Size(390, 844), Size(360, 740)];

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

void main() {
  for (final state in _State.values) {
    for (final size in _sizes) {
      for (final brightness in Brightness.values) {
        final name =
            '${state.name} ${size.width.toInt()}x${size.height.toInt()} ${brightness.name}';
        testWidgets('réglages, $name : aucun débordement', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final api = FakeCoupleApi();
          if (state == _State.inCouple) api.couple = contractCouple();
          if (state == _State.pending) api.sent = [contractSentRequest()];
          final service = CoupleService.forTesting(
            api: api,
            pollInterval: const Duration(hours: 1),
          );
          await service.initialize();
          CoupleService.instanceForTesting = service;

          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: _sharedContainer,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const SettingsScreen(),
              ),
            ),
          );
          await _pumpFor(tester, const Duration(milliseconds: 500));

          final label = switch (state) {
            _State.inCouple => 'Quitter le mode couple',
            _State.pending => 'Annuler la demande',
            _State.single => 'Activer',
          };
          await tester.scrollUntilVisible(
            find.text(label),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(label), findsOneWidget);
          expect(tester.takeException(), isNull);

          // A pending request makes the service poll: stop it before the end.
          await tester.pumpWidget(const SizedBox());
          service.dispose();
        });
      }
    }
  }
}
