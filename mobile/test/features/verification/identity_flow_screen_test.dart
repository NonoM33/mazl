import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/identity_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/vision/text_line_recognizer.dart';
import 'package:mazl/presentation/features/verification/identity/identity_flow_screen.dart';
import 'package:mazl/presentation/features/verification/identity/identity_status_views.dart';
import 'package:mazl/presentation/features/verification/identity/identity_intro_view.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';

import 'identity_fakes.dart';

class _NoopRecognizer implements TextLineRecognizer {
  @override
  Future<List<String>> recognizeLines(CameraImage image, CameraDescription camera) async => const [];

  @override
  Future<void> close() async {}
}

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: [textLineRecognizerProvider.overrideWithValue(_NoopRecognizer()), ...overrides],
      child: MaterialApp(home: home),
    );

void main() {
  group('intro', () {
    testWidgets('one title, three short steps, the privacy promise, one button', (tester) async {
      var started = false;
      await tester.pumpWidget(MaterialApp(home: IdentityIntroView(onStart: () => started = true, onClose: () {})));

      expect(find.text('Vérifiez votre identité.'), findsOneWidget);
      for (final step in IdentityIntroView.steps) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('Rien n\'est conservé : nous ne gardons que le résultat.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      expect(started, isTrue);
    });

    testWidgets('steps are short', (tester) async {
      for (final step in IdentityIntroView.steps) {
        expect(step.length, lessThan(50));
      }
    });
  });

  group('rejection screen', () {
    testWidgets('csca_unknown reads "Document non reconnu." and offers the manual review', (tester) async {
      var closed = false;
      await tester.pumpWidget(MaterialApp(
        home: IdentityFailedView(info: describeIdentityRejection('csca_unknown'), onAction: () => closed = true, onClose: () {}),
      ));
      expect(find.text('Document non reconnu.'), findsOneWidget);
      expect(find.text('Envoyer mon document pour relecture'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      expect(closed, isTrue);
    });

    testWidgets('a retryable rejection offers its action and no manual review', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IdentityFailedView(info: describeIdentityRejection('no_face'), onAction: () {}, onClose: () {}),
      ));
      expect(find.text('Aucun visage détecté.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Envoyer mon document pour relecture'), findsNothing);
    });
  });

  group('flow screen', () {
    testWidgets('nothing bound yet: "Bientôt disponible", no crash', (tester) async {
      await tester.pumpWidget(_app(const IdentityFlowScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Bientôt disponible'), findsOneWidget);
    });

    testWidgets('phone without NFC says so and offers the web review', (tester) async {
      await tester.pumpWidget(_app(const IdentityFlowScreen(), overrides: [
        chipReaderProvider.overrideWithValue(FakeChipReader(nfc: NfcAvailability.unsupported)),
        identityVerificationApiProvider.overrideWithValue(FakeVerificationApi()),
        identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Ce téléphone n\'a pas de lecteur NFC.'), findsOneWidget);
      expect(find.text('Envoyer mon document pour relecture'), findsOneWidget);
    });

    testWidgets('whole journey with fakes: intro, manual MRZ, chip, selfie, verified', (tester) async {
      final chip = FakeChipReader();
      final api = FakeVerificationApi();
      final liveness = FakeLiveness();
      await tester.pumpWidget(_app(const IdentityFlowScreen(), overrides: [
        chipReaderProvider.overrideWithValue(chip),
        identityVerificationApiProvider.overrideWithValue(api),
        identityLivenessCaptureProvider.overrideWithValue(liveness),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Vérifiez votre identité.'), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      // The scanner always offers typing the data (no camera in tests).
      expect(find.text('Cadrez la page photo.'), findsOneWidget);
      await tester.tap(find.text('Saisir à la main'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Numéro du document'), 'l898902c3');
      await tester.enterText(find.widgetWithText(TextField, 'Date de naissance'), '12081974');
      await tester.enterText(find.widgetWithText(TextField, 'Date d\'expiration'), '15042090');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text('Posez votre document sur le téléphone.'), findsOneWidget);
      await tester.tap(find.text('Lire le document'));
      await tester.pumpAndSettle();
      expect(chip.lastMrz!.documentNumber, 'L898902C3');
      expect(chip.lastMrz!.birthYymmdd, '740812');

      expect(find.text('Puce lue.'), findsOneWidget);
      await tester.tap(find.text('Prendre le selfie'));
      await tester.pumpAndSettle();
      expect(liveness.captures, 1);
      expect(find.text('Identité vérifiée.'), findsOneWidget);
    });

    testWidgets('manual entry shows errors and does not advance', (tester) async {
      await tester.pumpWidget(_app(const IdentityFlowScreen(), overrides: [
        chipReaderProvider.overrideWithValue(FakeChipReader()),
        identityVerificationApiProvider.overrideWithValue(FakeVerificationApi()),
        identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saisir à la main'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Date invalide.'), findsNWidgets(2));
      expect(find.text('Entre 5 et 12 lettres ou chiffres.'), findsOneWidget);
      expect(find.text('Saisissez les informations.'), findsOneWidget);
    });

    testWidgets('server rejection is shown in French on screen', (tester) async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(const VerificationOutcome(verified: false, reason: 'document_already_used'));
      await tester.pumpWidget(_app(const IdentityFlowScreen(), overrides: [
        chipReaderProvider.overrideWithValue(FakeChipReader()),
        identityVerificationApiProvider.overrideWithValue(api),
        identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saisir à la main'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Numéro du document'), 'L898902C3');
      await tester.enterText(find.widgetWithText(TextField, 'Date de naissance'), '12081974');
      await tester.enterText(find.widgetWithText(TextField, 'Date d\'expiration'), '15042090');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lire le document'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre le selfie'));
      await tester.pumpAndSettle();

      expect(find.text('Ce document est déjà associé à un autre compte.'), findsOneWidget);
    });

    testWidgets('wrong MRZ on the chip proposes a new scan', (tester) async {
      await tester.pumpWidget(_app(const IdentityFlowScreen(), overrides: [
        chipReaderProvider.overrideWithValue(FakeChipReader(failure: ChipFailureKind.accessDenied)),
        identityVerificationApiProvider.overrideWithValue(FakeVerificationApi()),
        identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saisir à la main'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Numéro du document'), 'L898902C3');
      await tester.enterText(find.widgetWithText(TextField, 'Date de naissance'), '12081974');
      await tester.enterText(find.widgetWithText(TextField, 'Date d\'expiration'), '15042090');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lire le document'));
      await tester.pumpAndSettle();

      expect(find.text('Les informations saisies ne correspondent pas à la puce.'), findsOneWidget);
      expect(find.text('Scanner à nouveau'), findsOneWidget);
    });
  });
}
