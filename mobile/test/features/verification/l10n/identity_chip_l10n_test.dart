import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart'
    show ProfilePhoto;
import 'package:mazl/presentation/features/verification/identity/identity_flow_state.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';
import 'package:mazl/presentation/features/verification/identity/identity_status_views.dart';
import 'package:mazl/presentation/features/verification/identity/nfc_read_view.dart';
import '../../../helpers/l10n_helpers.dart';
import '../verification_l10n.dart';
import 'identity_l10n_pump.dart';

const _en = Locale('en');
const _he = Locale('he');
const _mrz = icaoSpecimen;
final _pump = pumpIdentityView;
final _fitsEverywhere = expectFitsEverywhere;
final _centerX = centerX;

void main() {
  setUpAll(loadDatePatterns);

  group('lecture de la puce', () {
    NfcReadView nfc(IdentityNfc state, {VoidCallback? onRead}) => NfcReadView(
      state: state,
      onRead: onRead ?? () {},
      onRecover: () {},
      onRereadPhotoPage: () {},
      onClose: () {},
    );

    testWidgets('avant la lecture, en anglais', (tester) async {
      await _pump(tester, nfc(const IdentityNfc(_mrz)), locale: _en);

      expect(find.text('STEP 2 / 3'), findsOneWidget);
      expect(find.text('Place your document on the phone.'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Read the document'),
        findsOneWidget,
      );
      expect(find.textContaining('Remove the case if needed.'), findsOneWidget);
    });

    testWidgets(
      'pendant la lecture : étapes et progression lues à voix haute dans la langue',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          nfc(
            const IdentityNfc(
              _mrz,
              reading: true,
              progress: ChipReadProgress(ChipReadStep.readingPhoto, 40),
            ),
          ),
          locale: _en,
        );

        expect(find.text('Don\'t move.'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Detecting the document, done'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Secure connection, done'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Reading the photo, in progress'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Reading the signature, waiting'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Reading the chip'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('pendant la lecture, en hébreu', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        nfc(
          const IdentityNfc(
            _mrz,
            reading: true,
            progress: ChipReadProgress(ChipReadStep.authenticating, 10),
          ),
        ),
        locale: _he,
      );

      expect(find.text('אין לזוז.'), findsOneWidget);
      expect(find.bySemanticsLabel('זיהוי המסמך, הושלם'), findsOneWidget);
      expect(find.bySemanticsLabel('חיבור מאובטח, בתהליך'), findsOneWidget);
      expect(find.bySemanticsLabel('קריאת התמונה, ממתין'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'puce muette en anglais : phrase, réassurance, trois conseils, deux actions',
      (tester) async {
        await _pump(
          tester,
          nfc(
            IdentityNfc(
              _mrz,
              failure: describeChipFailure(ChipFailureKind.timeout),
            ),
          ),
          locale: _en,
        );

        expect(find.text('The chip did not respond.'), findsOneWidget);
        expect(
          find.text('This often happens on the first try. Nothing was sent.'),
          findsOneWidget,
        );
        expect(find.text('Take the case off your phone.'), findsOneWidget);
        expect(find.text('Stay still for about ten seconds.'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Try again'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextButton, 'Read the photo page again'),
          findsOneWidget,
        );
      },
    );

    testWidgets('mauvaise saisie en anglais : explication et nouveau scan', (
      tester,
    ) async {
      await _pump(
        tester,
        nfc(
          IdentityNfc(
            _mrz,
            failure: describeChipFailure(ChipFailureKind.accessDenied),
          ),
        ),
        locale: _en,
      );

      expect(
        find.text('The details entered do not match the chip.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Nothing was sent. Read the photo page again to start over with correct data.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Scan again'), findsOneWidget);
    });

    testWidgets(
      'la langue change, la même panne se redit dans la nouvelle langue',
      (tester) async {
        final state = IdentityNfc(
          _mrz,
          failure: describeChipFailure(ChipFailureKind.timeout),
        );
        await _pump(tester, nfc(state), locale: _en);
        expect(find.text('The chip did not respond.'), findsOneWidget);
        await _pump(tester, nfc(state), locale: const Locale('es'));
        expect(find.text('El chip no ha respondido.'), findsOneWidget);
      },
    );

    testWidgets(
      'tient dans les cinq langues, clair et sombre : attente, lecture et chaque panne',
      (tester) async {
        final states = <IdentityNfc>[
          const IdentityNfc(_mrz),
          const IdentityNfc(
            _mrz,
            reading: true,
            progress: ChipReadProgress(ChipReadStep.readingSignature, 85),
          ),
          for (final kind in ChipFailureKind.values)
            if (describeChipFailure(kind) != null)
              IdentityNfc(_mrz, failure: describeChipFailure(kind)),
        ];
        for (final state in states) {
          await _fitsEverywhere(tester, () => nfc(state));
        }
      },
    );
  });

  group('fin du parcours', () {
    testWidgets('puce lue, en anglais', (tester) async {
      await _pump(
        tester,
        IdentityFaceView(onCapture: () {}, onClose: () {}),
        locale: _en,
      );
      expect(find.text('STEP 2 / 3'), findsOneWidget);
      expect(find.text('Chip read.'), findsOneWidget);
      expect(
        find.text(
          'One moving selfie left, compared with the photo on the chip.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Take the selfie'),
        findsOneWidget,
      );
    });

    testWidgets(
      'réussite en anglais : le badge, ce qui n\'est jamais gardé et ce qui l\'est',
      (tester) async {
        await _pump(tester, IdentityDoneView(onDone: () {}), locale: _en);

        expect(find.text('Identity verified.'), findsOneWidget);
        expect(
          find.text('Identity verified'),
          findsOneWidget,
          reason: 'le badge tel que les autres le voient',
        );
        expect(find.text('What others see on your profile.'), findsOneWidget);
        expect(find.text('Photos and chip'), findsOneWidget);
        expect(find.text('Never stored'), findsOneWidget);
        expect(find.text('Kept'), findsOneWidget);
        expect(
          find.text('Country, expiry, anonymous fingerprint'),
          findsOneWidget,
        );
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Date of birth from the document'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Done'), findsOneWidget);
      },
    );

    testWidgets(
      'réussite en hébreu : l\'aperçu du badge s\'aligne au bord droit',
      (tester) async {
        await _pump(tester, IdentityDoneView(onDone: () {}), locale: _he);

        expect(find.text('הזהות אומתה.'), findsOneWidget);
        final badge = find.text('זהות מאומתת');
        expect(badge, findsOneWidget);
        expect(textDirectionAt(tester, badge), TextDirection.rtl);
        expect(
          _centerX(tester, find.byType(ProfilePhoto)),
          greaterThan(_centerX(tester, badge)),
          reason: 'la photo ouvre la carte à droite, le badge vient après elle',
        );
      },
    );

    testWidgets('attente : les deux textes de l\'indicateur', (tester) async {
      await _pump(
        tester,
        const IdentitySubmittingView(stage: IdentitySubmitStage.sending),
        locale: _en,
      );
      expect(find.text('Verification in progress…'), findsOneWidget);
      await _pump(
        tester,
        const IdentitySubmittingView(stage: IdentitySubmitStage.starting),
        locale: _en,
      );
      expect(find.text('Getting ready…'), findsOneWidget);
    });

    testWidgets('indisponible : bientôt et pas de lecteur NFC', (tester) async {
      await _pump(
        tester,
        IdentityUnavailableView(
          reason: IdentityUnavailableReason.comingSoon,
          onClose: () {},
        ),
        locale: _en,
      );
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Close'), findsOneWidget);
      await _pump(
        tester,
        IdentityUnavailableView(
          reason: IdentityUnavailableReason.noNfc,
          onClose: () {},
        ),
        locale: _en,
      );
      expect(find.text('This phone has no NFC reader.'), findsOneWidget);
      expect(find.text('Send my document for manual review'), findsOneWidget);
    });

    testWidgets(
      'refus définitif en anglais : phrase, bouton, relecture humaine',
      (tester) async {
        await _pump(
          tester,
          IdentityFailedView(
            info: describeIdentityRejection('csca_unknown'),
            onAction: () {},
            onClose: () {},
          ),
          locale: _en,
        );
        expect(find.text('Document not recognized.'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Close'), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, 'Send my document for manual review'),
          findsOneWidget,
        );
      },
    );

    testWidgets('chaque refus tient dans les cinq langues, clair et sombre', (
      tester,
    ) async {
      final infos = <IdentityFailureInfo>[
        for (final message in IdentityMessage.values)
          IdentityFailureInfo(
            message,
            IdentityRecovery.close,
            IdentityAction.close,
            offerManualReview: true,
          ),
        for (final action in IdentityAction.values)
          IdentityFailureInfo(
            IdentityMessage.verificationFailed,
            IdentityRecovery.retryFace,
            action,
          ),
      ];
      for (final info in infos) {
        await _fitsEverywhere(
          tester,
          () => IdentityFailedView(info: info, onAction: () {}, onClose: () {}),
        );
      }
    });

    testWidgets(
      'puce lue, réussite, attente et indisponible tiennent dans les cinq langues',
      (tester) async {
        await _fitsEverywhere(
          tester,
          () => IdentityFaceView(onCapture: () {}, onClose: () {}),
        );
        await _fitsEverywhere(tester, () => IdentityDoneView(onDone: () {}));
        await _fitsEverywhere(
          tester,
          () =>
              const IdentitySubmittingView(stage: IdentitySubmitStage.sending),
        );
        await _fitsEverywhere(
          tester,
          () => IdentityUnavailableView(
            reason: IdentityUnavailableReason.noNfc,
            onClose: () {},
          ),
        );
        await _fitsEverywhere(
          tester,
          () => IdentityUnavailableView(
            reason: IdentityUnavailableReason.comingSoon,
            onClose: () {},
          ),
        );
      },
    );
  });
}
