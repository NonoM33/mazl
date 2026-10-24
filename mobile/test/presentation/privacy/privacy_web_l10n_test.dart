import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:mazl/core/web_sessions/web_session_models.dart';
import 'package:mazl/presentation/features/privacy/screens/religious_data_settings_screen.dart';
import 'package:mazl/presentation/features/privacy/widgets/religious_data_gate.dart';
import 'package:mazl/presentation/features/web_sessions/screens/computers_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../web_sessions/web_sessions_fakes.dart';
import 'privacy_fakes.dart';

// The article 9 consent and the « ordinateurs connectés » screens in every
// language: translated, right to left in Hebrew, and they fit a 360 px phone
// (pumpLocalized fails a test on an overflow).

const _en = Locale('en');
const _he = Locale('he');
const _ru = Locale('ru');
const _es = Locale('es');

void main() {
  setUpAll(loadAppFonts);

  group('consentement (RGPD article 9)', () {
    Future<void> openSettings(WidgetTester tester, Locale locale, bool given) {
      final api = FakePrivacyConsentApi(
        granted: given,
        version: given ? '2026-10-24' : null,
      );
      return pumpLocalized(
        tester,
        const ReligiousDataSettingsScreen(),
        locale: locale,
        overrides: [privacyConsentApiProvider.overrideWithValue(api)],
      ).then((_) => tester.pumpAndSettle());
    }

    testWidgets('écran des réglages en anglais', (tester) async {
      await openSettings(tester, _en, true);
      expect(find.text('Religious practice data'), findsOneWidget);
      expect(find.text('Consent given'), findsOneWidget);
      expect(find.text('Withdraw my consent'), findsOneWidget);
    });

    testWidgets('écran des réglages en hébreu : de droite à gauche', (
      tester,
    ) async {
      await openSettings(tester, _he, false);
      expect(find.text('ההסכמה לא ניתנה'), findsOneWidget);
      expect(find.text('לתת הסכמה'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('לתת הסכמה')),
        TextDirection.rtl,
      );
    });

    testWidgets('écran des réglages en russe et en espagnol', (tester) async {
      await openSettings(tester, _ru, false);
      expect(find.text('Согласие не дано'), findsOneWidget);
      await openSettings(tester, _es, true);
      expect(find.text('Consentimiento dado'), findsOneWidget);
    });

    testWidgets('sans accord, la carte et le champ grisé parlent la langue', (
      tester,
    ) async {
      final api = FakePrivacyConsentApi();
      await pumpLocalized(
        tester,
        Scaffold(
          body: Column(
            children: [
              ReligiousDataGate(
                onValidityChanged: (_) {},
                child: const Text('fields'),
              ),
              const ReligiousDataLocked(locked: true, child: Text('intention')),
            ],
          ),
        ),
        locale: _en,
        overrides: [privacyConsentApiProvider.overrideWithValue(api)],
      );
      await tester.pumpAndSettle();
      expect(find.text('fields'), findsNothing);
      expect(
        find.text('To share your practice, give your consent'),
        findsOneWidget,
      );
      expect(find.text('Give my consent'), findsOneWidget);
      expect(
        find.text(
          "Available once you've given your consent for religious practice data.",
        ),
        findsOneWidget,
      );
    });
  });

  group('ordinateurs connectés', () {
    final now = DateTime(2026, 10, 24, 12);

    Future<void> open(WidgetTester tester, Locale locale) =>
        withClock(Clock.fixed(now), () async {
          final api = FakeWebSessionsApi(
            sessions: [
              fakeSession(
                'a',
                lastSeen: now.subtract(const Duration(minutes: 5)),
              ),
              fakeSession(
                'b',
                browser: 'Safari sur macOS',
                method: WebSessionMethod.apple,
                lastSeen: now.subtract(const Duration(days: 2)),
              ),
            ],
          );
          await pumpLocalized(
            tester,
            const ComputersScreen(),
            locale: locale,
            overrides: [webSessionsApiProvider.overrideWithValue(api)],
          );
          await tester.pumpAndSettle();
        });

    testWidgets('en anglais', (tester) async {
      await open(tester, _en);
      expect(find.text('Connected computers'), findsOneWidget);
      expect(find.text('Connect a computer'), findsOneWidget);
      expect(
        find.text('Connected by QR code · Active 5 min ago'),
        findsOneWidget,
      );
      expect(
        find.text('Connected with Apple · Active 2 d ago'),
        findsOneWidget,
      );
      expect(find.text('Disconnect all computers'), findsOneWidget);
    });

    testWidgets('en hébreu : de droite à gauche, pluriel du duel', (
      tester,
    ) async {
      await open(tester, _he);
      expect(find.text('מחשבים מחוברים'), findsOneWidget);
      expect(find.textContaining('פעילות לפני יומיים'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('מחשבים מחוברים')),
        TextDirection.rtl,
      );
    });

    testWidgets('en russe et en espagnol', (tester) async {
      await open(tester, _ru);
      expect(find.text('Подключённые компьютеры'), findsOneWidget);
      expect(find.textContaining('Активность: 5 мин назад'), findsOneWidget);
      await open(tester, _es);
      expect(find.text('Ordenadores conectados'), findsOneWidget);
      expect(find.textContaining('Actividad hace 5 min'), findsOneWidget);
    });
  });
}
