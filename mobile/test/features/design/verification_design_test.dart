import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/identity_providers.dart';
import 'package:mazl/core/di/providers/verification_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';
import 'package:mazl/core/vision/text_line_recognizer.dart';
import 'package:mazl/presentation/features/verification/identity/identity_flow_state.dart';
import 'package:mazl/presentation/features/verification/identity/identity_intro_view.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';
import 'package:mazl/presentation/features/verification/identity/identity_status_views.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_manual_view.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_format.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_view.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_scanner_view.dart';
import 'package:mazl/presentation/features/verification/l10n/identity_failure_text.dart';
import 'package:mazl/presentation/features/verification/identity/nfc_read_view.dart';
import 'package:mazl/presentation/features/verification/screens/verification_screen.dart';
import '../../helpers/l10n_helpers.dart';
import '../verification/verification_l10n.dart';

const _mrz = MrzData(documentNumber: 'L898902C3', birthYymmdd: '740812', expiryYymmdd: '450415');

class _NoopRecognizer implements TextLineRecognizer {
  @override
  Future<List<String>> recognizeLines(CameraImage image, CameraDescription camera) async => const [];

  @override
  Future<void> close() async {}
}

class _StatusApi implements VerificationApi {
  _StatusApi(this.status);

  final VerificationStatus status;

  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async => ApiResponse.success(status);

  @override
  Future<ApiResponse<FaceSession>> startFaceSession(FacePurpose purpose) => throw UnimplementedError();

  @override
  Future<ApiResponse<VerificationOutcome>> submitFace(String sessionId, List<Uint8List> frames) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<VerificationOutcome>> submitIdentity(String s, List<Uint8List> f, ChipReadResult c) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<void>> deleteFaceReference() => throw UnimplementedError();
}

VerificationStatus _status({bool photo = false, bool identity = false}) => VerificationStatus.fromJson({
  'photo': {'verified': photo, 'verified_at': photo ? '2026-10-20T09:00:00Z' : null, 'attempts_today': 0},
  'identity': {'verified': identity, 'verified_at': identity ? '2026-10-21T09:00:00Z' : null, 'attempts_today': 0},
  'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
  'is_verified': photo || identity,
  'next_attempt_time': null,
});

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  List<Override> overrides = const [],
  double height = 844,
}) async {
  tester.view.physicalSize = Size(390 * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [textLineRecognizerProvider.overrideWithValue(_NoopRecognizer()), ...overrides],
      child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: kTestLocale, theme: theme ?? AppTheme.lightTheme, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le design Encre & Tekhelet interdit les dégradés : aucune décoration montée n'en porte.
void _expectNoGradient(WidgetTester tester) {
  bool gradient(Decoration? d) => d is BoxDecoration && d.gradient != null;
  final withGradient = [
    ...tester.widgetList<Container>(find.byType(Container)).where((c) => gradient(c.decoration)),
    ...tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((b) => gradient(b.decoration)),
  ];
  expect(withGradient, isEmpty, reason: 'aucun dégradé dans le design Encre & Tekhelet');
}

/// Chaque bouton à libellé est une cible d'au moins 44 pt.
void _expectTouchTargets(WidgetTester tester) {
  for (final type in <Type>[ElevatedButton, OutlinedButton, TextButton]) {
    for (final element in find.byType(type).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.height, greaterThanOrEqualTo(44), reason: '$type ${size.height}');
    }
  }
}

void main() {
  group('introduction', () {
    testWidgets('titre, trois étapes numérotées, promesse et pilule encre', (tester) async {
      final semantics = tester.ensureSemantics();
      var started = false;
      await _pump(tester, IdentityIntroView(onStart: () => started = true, onClose: () {}));

      expect(find.text('Vérifiez votre identité.'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      for (final step in IdentityIntroView.steps(frenchL10n)) {
        expect(find.text(step.title), findsOneWidget);
      }
      expect(find.text(frenchL10n.verificationIntroPrivacy), findsOneWidget);
      expect(find.bySemanticsLabel('Commencer'), findsOneWidget);
      expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
      expect(tester.getSize(find.byType(ElevatedButton)).height, 56);
      _expectNoGradient(tester);
      _expectTouchTargets(tester);

      await tester.tap(find.text('Commencer'));
      expect(started, isTrue);
      semantics.dispose();
    });

    testWidgets('le titre est grand et serré', (tester) async {
      await _pump(tester, IdentityIntroView(onStart: () {}, onClose: () {}));
      final title = tester.widget<Text>(find.text('Vérifiez votre identité.'));
      expect(title.style!.fontSize, 40);
      expect(title.style!.letterSpacing, closeTo(-40 * 0.04, 0.001));
    });

    testWidgets('se rend en mode sombre sans erreur', (tester) async {
      await _pump(
        tester,
        IdentityIntroView(onStart: () {}, onClose: () {}),
        theme: AppTheme.darkTheme,
      );
      expect(find.text('Vérifiez votre identité.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('saisie à la main', () {
    testWidgets('étape 1, trois champs, une pilule et un lien', (tester) async {
      await _pump(tester, MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}));

      expect(find.text('ÉTAPE 1 / 3'), findsOneWidget);
      expect(find.text('Saisissez les informations.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.widgetWithText(ElevatedButton, 'Continuer'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Scanner avec la caméra'), findsOneWidget);
      _expectNoGradient(tester);
      _expectTouchTargets(tester);
    });
  });

  group('scan de la page photo', () {
    testWidgets('écran sombre : étape 1, titre, cadre décrit, saisie à la main', (tester) async {
      final semantics = tester.ensureSemantics();
      var manual = false;
      await _pump(tester, MrzScannerView(onScanned: (_) {}, onManual: () => manual = true, onClose: () {}));

      expect(find.text('ÉTAPE 1 / 3'), findsOneWidget);
      expect(find.text('Cadrez la page photo.'), findsOneWidget);
      expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Aperçu de la caméra')), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.darkTheme.colorScheme.surface, reason: 'écran de caméra : fond encre');
      _expectNoGradient(tester);
      _expectTouchTargets(tester);

      await tester.tap(find.text('Saisir à la main'));
      expect(manual, isTrue);
      semantics.dispose();
    });
  });

  group('lecture de la puce', () {
    Future<void> pumpNfc(WidgetTester tester, IdentityNfc state, {VoidCallback? onReread}) => _pump(
      tester,
      NfcReadView(state: state, onRead: () {}, onRecover: () {}, onRereadPhotoPage: onReread ?? () {}, onClose: () {}),
    );

    testWidgets('avant la lecture : où poser le document', (tester) async {
      await pumpNfc(tester, const IdentityNfc(_mrz));

      expect(find.text('ÉTAPE 2 / 3'), findsOneWidget);
      expect(find.text('Posez votre document sur le téléphone.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Lire le document'), findsOneWidget);
      _expectNoGradient(tester);
    });

    testWidgets('pendant la lecture : « Ne bougez plus. », étapes fait / en cours / en attente, barre fine', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpNfc(
        tester,
        const IdentityNfc(_mrz, reading: true, progress: ChipReadProgress(ChipReadStep.readingPhoto, 40)),
      );

      expect(find.text('Ne bougez plus.'), findsOneWidget);
      expect(find.bySemanticsLabel('Détection du document, terminé'), findsOneWidget);
      expect(find.bySemanticsLabel('Connexion sécurisée, terminé'), findsOneWidget);
      expect(find.bySemanticsLabel('Lecture de la photo, en cours'), findsOneWidget);
      expect(find.bySemanticsLabel('Lecture de la signature, en attente'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.4, 0.001));
      expect(bar.minHeight, 4);
      expect(find.byType(ElevatedButton), findsNothing, reason: 'pas de bouton inerte pendant la lecture');
      _expectNoGradient(tester);
      semantics.dispose();
    });

    testWidgets('puce muette : « La puce n\'a pas répondu. », trois conseils, Réessayer', (tester) async {
      await pumpNfc(tester, IdentityNfc(_mrz, failure: describeChipFailure(ChipFailureKind.timeout)));

      expect(find.text('La puce n\'a pas répondu.'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Retirez la coque du téléphone.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);
      _expectNoGradient(tester);
      _expectTouchTargets(tester);
    });

    testWidgets('puce muette : « Relire la page photo » repart de la page photo', (tester) async {
      var reread = false;
      await pumpNfc(
        tester,
        IdentityNfc(_mrz, failure: describeChipFailure(ChipFailureKind.timeout)),
        onReread: () => reread = true,
      );
      await tester.tap(find.text('Relire la page photo'));
      expect(reread, isTrue);
    });

    testWidgets('NFC désactivé : pas de conseils sur la coque', (tester) async {
      await pumpNfc(tester, IdentityNfc(_mrz, failure: describeChipFailure(ChipFailureKind.nfcDisabled)));

      expect(find.text('Activez le NFC dans les réglages du téléphone.'), findsOneWidget);
      expect(find.text('Retirez la coque du téléphone.'), findsNothing);
      expect(find.text('Relire la page photo'), findsNothing, reason: 'un réglage du téléphone, pas une mauvaise lecture');
    });

    testWidgets('mauvaise saisie : propose de relire la page photo', (tester) async {
      await pumpNfc(tester, IdentityNfc(_mrz, failure: describeChipFailure(ChipFailureKind.accessDenied)));

      expect(find.text('Les informations saisies ne correspondent pas à la puce.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Scanner à nouveau'), findsOneWidget);
    });
  });

  group('confirmation de la page photo', () {
    testWidgets('numéro masqué, dates lisibles, « C\'est bien moi » et « Scanner à nouveau »', (tester) async {
      var confirmed = false;
      var rejected = false;
      await _pump(
        tester,
        MrzReviewView(mrz: _mrz, onConfirm: () => confirmed = true, onReject: () => rejected = true, onClose: () {}),
      );

      expect(find.text('Vérifiez ces informations.'), findsOneWidget);
      expect(find.text(_mrz.documentNumber), findsNothing, reason: 'le numéro complet ne s\'affiche jamais');
      expect(find.text(reviewDocumentNumber(_mrz.documentNumber)), findsOneWidget);
      expect(find.text(formatReviewDate(_mrz.birthDate(), 'fr')), findsOneWidget);
      expect(find.text(formatReviewDate(_mrz.expiryDate(), 'fr')), findsOneWidget);
      _expectTouchTargets(tester);

      await tester.tap(find.text('C\'est bien moi'));
      await tester.tap(find.text('Scanner à nouveau'));
      expect(confirmed, isTrue);
      expect(rejected, isTrue);
    });
  });

  group('états de fin', () {
    testWidgets('puce lue : le selfie vient ensuite', (tester) async {
      await _pump(tester, IdentityFaceView(onCapture: () {}, onClose: () {}));

      expect(find.text('Puce lue.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Prendre le selfie'), findsOneWidget);
    });

    testWidgets('réussite : titre 48, aperçu du badge, ce qui est effacé et conservé', (tester) async {
      final semantics = tester.ensureSemantics();
      var done = false;
      await _pump(tester, IdentityDoneView(onDone: () => done = true));

      expect(find.text('Identité vérifiée.'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Identité vérifiée.')).style!.fontSize, 48);
      expect(find.text('Identité vérifiée'), findsOneWidget, reason: 'le badge tel que les autres le voient');
      expect(find.text('Ce que les autres voient sur votre profil.'), findsOneWidget);
      expect(find.text('Photos et puce'), findsOneWidget);
      expect(find.text('Jamais enregistrées'), findsOneWidget);
      expect(find.text('Pays, expiration, empreinte anonyme'), findsOneWidget);
      expect(find.text('Date de naissance du document'), findsOneWidget);
      expect(find.bySemanticsLabel('Terminer'), findsOneWidget);
      _expectNoGradient(tester);

      await tester.tap(find.text('Terminer'));
      expect(done, isTrue);
      semantics.dispose();
    });

    testWidgets('refus définitif : message, pilule, relecture humaine', (tester) async {
      await _pump(
        tester,
        IdentityFailedView(info: describeIdentityRejection('csca_unknown'), onAction: () {}, onClose: () {}),
      );

      expect(find.text('Document non reconnu.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Fermer'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Envoyer mon document pour relecture'), findsOneWidget);
      _expectNoGradient(tester);
      _expectTouchTargets(tester);
    });

    testWidgets('mineur, document déjà utilisé, session expirée : même langage, en « vous »', (tester) async {
      for (final code in ['underage', 'document_already_used', 'daily_limit_reached', 'session_expired']) {
        final info = describeIdentityRejection(code);
        await _pump(tester, IdentityFailedView(info: info, onAction: () {}, onClose: () {}));
        final message = info.messageText(frenchL10n);
        expect(find.text(message), findsOneWidget, reason: code);
        expect(message, isNot(matches(RegExp(r'\b(ton|ta|tes|tu|toi)\b', caseSensitive: false))), reason: code);
        _expectNoGradient(tester);
      }
    });

    testWidgets('pas de lecteur NFC, bientôt disponible', (tester) async {
      await _pump(tester, IdentityUnavailableView(reason: IdentityUnavailableReason.noNfc, onClose: () {}));
      expect(find.text('Ce téléphone n\'a pas de lecteur NFC.'), findsOneWidget);
      await _pump(tester, IdentityUnavailableView(reason: IdentityUnavailableReason.comingSoon, onClose: () {}));
      expect(find.text('Bientôt disponible'), findsOneWidget);
    });
  });

  group('page de vérification', () {
    Future<void> pumpHub(WidgetTester tester, VerificationStatus status) => _pump(
      tester,
      const VerificationScreen(),
      height: 2400,
      overrides: [verificationApiProvider.overrideWithValue(_StatusApi(status))],
    );

    testWidgets('rien de vérifié : deux niveaux, deux actions', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHub(tester, _status());

      expect(find.text('VÉRIFICATION'), findsOneWidget);
      expect(find.text('Vérifiez votre profil'), findsOneWidget);
      expect(find.text('Vérification de la photo'), findsOneWidget);
      expect(find.text('Vérification de l\'identité'), findsOneWidget);
      expect(find.text('NIVEAU 1'), findsOneWidget);
      expect(find.text('NIVEAU 2'), findsOneWidget);
      expect(find.text(frenchL10n.verificationConsent), findsOneWidget);
      expect(find.bySemanticsLabel('Retour'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Vérifier ma photo'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Vérifier mon identité'), findsOneWidget);
      _expectNoGradient(tester);
      _expectTouchTargets(tester);
      semantics.dispose();
    });

    testWidgets('tout vérifié : deux pastilles « Vérifiée », plus d\'action de vérification', (tester) async {
      await pumpHub(tester, _status(photo: true, identity: true));

      expect(find.text('Vérifiée'), findsNWidgets(2));
      expect(find.text('Profil entièrement vérifié'), findsOneWidget);
      expect(find.text('Le 20 octobre 2026'), findsOneWidget);
      expect(find.text('Le 21 octobre 2026'), findsOneWidget);
      expect(find.text('Vérifier ma photo'), findsNothing);
      expect(find.text('Vérifier mon identité'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Retirer ma vérification'), findsOneWidget);
      _expectNoGradient(tester);
    });

    testWidgets('se rend en mode sombre sans erreur', (tester) async {
      await _pump(
        tester,
        const VerificationScreen(),
        theme: AppTheme.darkTheme,
        overrides: [verificationApiProvider.overrideWithValue(_StatusApi(_status()))],
      );
      expect(find.text('Vérifiez votre profil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
