import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/privacy/analytics_consent.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/privacy/widgets/analytics_consent_sheet.dart';

import '../../core/analytics/analytics_fakes.dart';
import '../../features/duo/duo_geometry.dart';
import '../../helpers/duo_poses.dart';
import 'privacy_fakes.dart';

const _consent = AnalyticsConsent(
  granted: null,
  version: null,
  decidedAt: null,
  currentVersion: '2026-10-26',
  text: analyticsConsentText,
);

class _Rig {
  _Rig({this.pose = DuoPose.openPortrait}) {
    analytics =
        Analytics(
            transport: transport,
            clock: FakeClock().call,
            periodicTimer: FakeTimers().call,
          )
          ..signedIn()
          ..track(null);
  }

  final DuoPose pose;
  final api = FakePrivacyConsentApi(analyticsGranted: null);
  final transport = FakeAnalyticsTransport();
  late final Analytics analytics;
  final results = <bool?>[];

  Future<void> open(WidgetTester tester) async {
    setDuoPose(tester, pose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyConsentApiProvider.overrideWithValue(api),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: duoAppBuilder(DuoPoseController(pose)),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async => results.add(
                    await showAnalyticsConsentSheet(context, _consent),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await settleFold(tester);
  }
}

void main() {
  testWidgets('shows the server text and no pre-ticked box', (tester) async {
    await _Rig().open(tester);

    expect(find.text('Aider à améliorer MAZL'), findsOneWidget);
    expect(find.text(analyticsConsentText), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('Accept and Refuse weigh the same: same kind, same size', (
    tester,
  ) async {
    await _Rig().open(tester);

    final accept = find.widgetWithText(ElevatedButton, 'Accepter');
    final decline = find.widgetWithText(ElevatedButton, 'Refuser');
    expect(accept, findsOneWidget);
    expect(decline, findsOneWidget);
    expect(tester.getSize(accept), tester.getSize(decline));
    expect(tester.getSize(accept).height, greaterThanOrEqualTo(44));
    // Same colours too: refusing is as easy to see as accepting.
    final acceptStyle = tester.widget<ElevatedButton>(accept).style;
    final declineStyle = tester.widget<ElevatedButton>(decline).style;
    expect(acceptStyle, declineStyle);
  });

  testWidgets('Accept records granted true with the current version', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.open(tester);

    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();

    expect(rig.api.calls, ['put:analytics:true:2026-10-26']);
    expect(rig.results, [true]);
    expect(rig.analytics.consent, AnalyticsConsentState.granted);
    expect(find.text('Accepter'), findsNothing);
  });

  testWidgets('Refuse records granted false and nothing leaves', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.open(tester);

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    expect(rig.api.calls, ['put:analytics:false:2026-10-26']);
    expect(rig.results, [false]);
    expect(rig.analytics.consent, AnalyticsConsentState.denied);
    expect(rig.transport.batches, isEmpty);
  });

  testWidgets('a failed save keeps the sheet open and says so', (tester) async {
    final rig = _Rig();
    rig.api.failDecide = true;
    await rig.open(tester);

    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('pas pu être enregistré'), findsOneWidget);
    expect(rig.results, isEmpty);
    expect(rig.analytics.consent, AnalyticsConsentState.unknown);
  });

  for (final pose in DuoPose.values) {
    testWidgets('${pose.name}: fits, out of the fold, 44 pt targets', (
      tester,
    ) async {
      await _Rig(pose: pose).open(tester);

      expectFitsDuoPose(tester, pose, 'analytics consent sheet');
      expect(tappableProblems(tester, pose), isEmpty, reason: pose.name);
      expect(foldCrossingProblems(tester, pose), isEmpty, reason: pose.name);
      for (final label in ['Accepter', 'Refuser']) {
        final size = tester.getSize(find.widgetWithText(ElevatedButton, label));
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
      }
    });
  }

  for (final pose in DuoPose.values) {
    testWidgets('${pose.name}: both buttons are fully in view, off the fold', (
      tester,
    ) async {
      await _Rig(pose: pose).open(tester);
      final sheet = tester.getRect(find.byType(AnalyticsConsentSheet));
      for (final label in ['Accepter', 'Refuser']) {
        final button = tester.getRect(
          find.widgetWithText(ElevatedButton, label),
        );
        expect(
          sheet.inflate(0.5).contains(button.topLeft),
          isTrue,
          reason: label,
        );
        expect(
          sheet.inflate(0.5).contains(button.bottomRight),
          isTrue,
          reason: '$label is cut by the sheet',
        );
        expect(
          find.widgetWithText(ElevatedButton, label).hitTestable(),
          findsOneWidget,
        );
        final fold = pose.fold;
        if (fold != null) expect(button.overlaps(fold), isFalse, reason: label);
      }
    });
  }
}
