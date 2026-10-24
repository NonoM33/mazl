import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/di/providers/identity_providers.dart';
import 'package:mazl/core/services/api_service.dart' hide ProfilePhoto;
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/presentation/features/verification/identity/identity_flow_screen.dart';
import 'package:mazl/presentation/features/verification/identity/identity_intro_view.dart';
import 'package:mazl/presentation/features/verification/identity/identity_layout.dart';
import 'package:mazl/presentation/features/verification/identity/identity_parts.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_manual_view.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_format.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_view.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_scanner_view.dart';
import '../../../helpers/l10n_helpers.dart';
import '../identity_fakes.dart';
import '../verification_l10n.dart';
import 'identity_l10n_pump.dart';

const _locales = kAllLocales;
const _en = Locale('en');
const _he = Locale('he');
const _mrz = icaoSpecimen;
final _pump = pumpIdentityView;
final _fitsEverywhere = expectFitsEverywhere;
final _centerX = centerX;

void main() {
  setUpAll(loadDatePatterns);

  group('accueil', () {
    testWidgets('en anglais : titre, trois étapes, promesse, bouton', (
      tester,
    ) async {
      var started = false;
      await _pump(
        tester,
        IdentityIntroView(onStart: () => started = true, onClose: () {}),
        locale: _en,
      );

      expect(find.text('Verify your identity.'), findsOneWidget);
      expect(find.text('Photograph the photo page'), findsOneWidget);
      expect(find.text('To read the two bottom lines.'), findsOneWidget);
      expect(find.text('Place the phone on the chip'), findsOneWidget);
      expect(find.text('A moving selfie'), findsOneWidget);
      expect(
        find.text('Nothing is kept: we only keep the result.'),
        findsOneWidget,
      );
      expect(find.text('Vérifiez votre identité.'), findsNothing);

      await tester.tap(find.text('Start'));
      expect(started, isTrue);
    });

    testWidgets(
      'en hébreu : lu de droite à gauche, numéros et fermer au bord droit',
      (tester) async {
        await _pump(
          tester,
          IdentityIntroView(onStart: () {}, onClose: () {}),
          locale: _he,
        );

        expect(
          textDirectionAt(tester, find.text('לאמת את הזהות שלך.')),
          TextDirection.rtl,
        );
        expect(find.text('לצלם את עמוד התמונה'), findsOneWidget);
        expect(
          find.text('כדי לקרוא את שתי שורות ה-MRZ התחתונות.'),
          findsOneWidget,
        );
        expect(
          _centerX(tester, find.text('01')),
          greaterThan(kSmallPhone.width / 2),
        );
        expect(
          _centerX(tester, find.byIcon(LucideIcons.x)),
          greaterThan(kSmallPhone.width / 2),
        );
      },
    );

    testWidgets('en français, la croix reste à gauche', (tester) async {
      await _pump(tester, IdentityIntroView(onStart: () {}, onClose: () {}));
      expect(
        _centerX(tester, find.byIcon(LucideIcons.x)),
        lessThan(kSmallPhone.width / 2),
      );
    });

    testWidgets('tient dans les cinq langues, clair et sombre', (tester) async {
      await _fitsEverywhere(
        tester,
        () => IdentityIntroView(onStart: () {}, onClose: () {}),
      );
    });
  });

  group('saisie à la main', () {
    testWidgets('en anglais : libellés, aide de date, erreurs', (tester) async {
      await _pump(
        tester,
        MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}),
        locale: _en,
      );

      expect(find.text('STEP 1 / 3'), findsOneWidget);
      expect(find.text('Enter the details.'), findsOneWidget);
      expect(
        find.text('Copy them from the photo page of your document.'),
        findsOneWidget,
      );
      expect(find.text('Document number'), findsOneWidget);
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('Expiry date'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Scan with the camera'),
        findsOneWidget,
      );

      await tester.tap(find.byType(TextField).at(1));
      await tester.pump();
      expect(
        find.text('DD/MM/YYYY'),
        findsWidgets,
        reason: 'l\'ordre à taper, dans la langue',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      expect(find.text('Invalid date.'), findsNWidgets(2));
      expect(find.text('Between 5 and 12 letters or digits.'), findsOneWidget);
    });

    testWidgets(
      'en hébreu : erreurs traduites, saisie de gauche à droite alignée au bord de départ',
      (tester) async {
        await _pump(
          tester,
          MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}),
          locale: _he,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'המשך'));
        await tester.pump();
        expect(find.text('תאריך לא תקין.'), findsNWidgets(2));
        expect(find.text('בין 5 ל-12 אותיות או ספרות.'), findsOneWidget);

        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          expect(
            field.textDirection,
            TextDirection.ltr,
            reason: 'lettres et chiffres se tapent de gauche à droite',
          );
          expect(
            field.textAlign,
            TextAlign.end,
            reason: 'dans une page de droite à gauche, la valeur est à droite',
          );
        }
      },
    );

    testWidgets('en anglais, la valeur est alignée à gauche', (tester) async {
      await _pump(
        tester,
        MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}),
        locale: _en,
      );
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.textAlign, TextAlign.start);
      }
    });

    testWidgets(
      'les chiffres tapés gardent leurs barres, quelle que soit la langue',
      (tester) async {
        await _pump(
          tester,
          MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}),
          locale: _he,
        );
        await tester.enterText(find.byType(TextField).at(1), '12081974');
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(1))
              .controller!
              .text,
          '12/08/1974',
        );
      },
    );

    testWidgets('tient dans les cinq langues, avec les erreurs affichées', (
      tester,
    ) async {
      for (final locale in _locales) {
        for (final brightness in Brightness.values) {
          await _pump(
            tester,
            MrzManualView(onSubmit: (_) {}, onUseCamera: () {}, onClose: () {}),
            locale: locale,
            brightness: brightness,
          );
          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode} ${brightness.name}',
          );
        }
      }
    });
  });

  group('scan de la page photo', () {
    testWidgets('en anglais : titre, conseil, lien', (tester) async {
      await _pump(
        tester,
        MrzScannerView(onScanned: (_) {}, onManual: () {}, onClose: () {}),
        locale: _en,
      );
      await tester.pump(const Duration(milliseconds: 100));

      // No camera in tests: either the live frame or the « typing is the way out » notice.
      final live = find.text('Frame the photo page.').evaluate().isNotEmpty;
      if (live) {
        expect(
          find.text(
            'The two lines of “<” at the bottom are enough. Avoid glare.',
          ),
          findsOneWidget,
        );
        expect(find.text('Enter by hand'), findsOneWidget);
      } else {
        expect(find.text('The camera is not available.'), findsOneWidget);
        expect(
          find.text('You can enter the details from the photo page by hand.'),
          findsOneWidget,
        );
        expect(find.text('Enter the details'), findsOneWidget);
      }
    });

    testWidgets('l\'aperçu de la caméra est décrit dans la langue', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        MrzScannerView(onScanned: (_) {}, onManual: () {}, onClose: () {}),
        locale: _en,
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Frame the photo page.').evaluate().isNotEmpty) {
        expect(
          find.bySemanticsLabel(
            'Camera preview: place the two bottom lines of the document inside the highlighted frame',
          ),
          findsOneWidget,
        );
      }
      semantics.dispose();
    });

    testWidgets('tient dans les cinq langues, clair et sombre', (tester) async {
      await _fitsEverywhere(
        tester,
        () =>
            MrzScannerView(onScanned: (_) {}, onManual: () {}, onClose: () {}),
      );
    });

    testWidgets(
      'sans caméra, l\'écran de secours tient aussi dans les cinq langues',
      (tester) async {
        // The same notice MrzScannerView shows once the camera fails to open.
        for (final locale in _locales) {
          for (final brightness in Brightness.values) {
            await _pump(
              tester,
              Builder(
                builder: (context) => IdentityNotice(
                  dark: true,
                  eyebrow: context.l10n.verificationStepLabel(1, 3),
                  icon: LucideIcons.cameraOff,
                  title: context.l10n.verificationCameraNotAvailable,
                  body: context.l10n.verificationScanUnavailableBody,
                  onClose: () {},
                  actions: [
                    IdentityPrimaryButton(
                      context.l10n.verificationScanEnterDetails,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              locale: locale,
              brightness: brightness,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${locale.languageCode} ${brightness.name}',
            );
          }
        }
      },
    );
  });

  group('relecture de la page photo', () {
    Widget view() => MrzReviewView(
      mrz: _mrz,
      onConfirm: () {},
      onReject: () {},
      onClose: () {},
    );

    testWidgets('en anglais : date au format américain, numéro masqué', (
      tester,
    ) async {
      await _pump(tester, view(), locale: _en);

      expect(find.text('Check these details.'), findsOneWidget);
      expect(find.text('Document number'), findsOneWidget);
      expect(find.text('8/12/1974'), findsOneWidget);
      expect(find.text('4/15/2045'), findsOneWidget);
      expect(find.text(reviewDocumentNumber('L898902C3')), findsOneWidget);
      expect(find.text('L898902C3'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'That\'s me'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Scan again'), findsOneWidget);
    });

    testWidgets(
      'en hébreu : étiquette à droite, valeur à gauche, numéro isolé de gauche à droite',
      (tester) async {
        await _pump(tester, view(), locale: _he);

        final label = find.text('מספר המסמך');
        final value = find.text(reviewDocumentNumber('L898902C3'));
        expect(label, findsOneWidget);
        expect(value, findsOneWidget);
        expect(_centerX(tester, label), greaterThan(_centerX(tester, value)));
        expect(find.text('12.8.1974'), findsOneWidget);
        expect(find.text('15.4.2045'), findsOneWidget);
      },
    );

    testWidgets('en français, les dates restent jour/mois/année', (
      tester,
    ) async {
      await _pump(tester, view());
      expect(find.text('12/08/1974'), findsOneWidget);
      expect(find.text('15/04/2045'), findsOneWidget);
    });

    testWidgets('tient dans les cinq langues, clair et sombre', (tester) async {
      await _fitsEverywhere(tester, view);
    });
  });

  group('parcours complet', () {
    Future<void> walkToNfc(
      WidgetTester tester,
      FakeChipReader chip,
      Locale locale,
      Map<String, String> words,
    ) async {
      await _pump(
        tester,
        const IdentityFlowScreen(),
        locale: locale,
        overrides: [
          chipReaderProvider.overrideWithValue(chip),
          identityVerificationApiProvider.overrideWithValue(
            FakeVerificationApi(),
          ),
          identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(words['start']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text(words['byHand']!));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'l898902c3');
      await tester.enterText(find.byType(TextField).at(1), '12081974');
      await tester.enterText(find.byType(TextField).at(2), '15042090');
      await tester.tap(find.text(words['continue']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text(words['itsMe']!));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'en anglais, la feuille NFC de l\'iPhone reçoit des phrases anglaises',
      (tester) async {
        final chip = FakeChipReader();
        await walkToNfc(tester, chip, _en, {
          'start': 'Start',
          'byHand': 'Enter by hand',
          'continue': 'Continue',
          'itsMe': 'That\'s me',
        });
        expect(find.text('Place your document on the phone.'), findsOneWidget);

        await tester.tap(find.text('Read the document'));
        await tester.pumpAndSettle();

        final alerts = chip.lastAlerts!;
        expect(
          alerts.approach,
          'Bring your document close to the top of the phone.',
        );
        expect(alerts.authenticating, 'Don\'t move. Secure connection…');
        expect(alerts.readingPhoto, 'Reading the photo… 40%');
        expect(alerts.readingSignature, 'Reading the signature… 85%');
        expect(alerts.done, 'Done.');
        expect(alerts.failure, 'The reading failed.');
        expect(find.text('Chip read.'), findsOneWidget);
      },
    );

    testWidgets(
      'en hébreu, la feuille NFC est en hébreu et la relecture repart en hébreu',
      (tester) async {
        final chip = FakeChipReader(failure: ChipFailureKind.tagLost);
        await walkToNfc(tester, chip, _he, {
          'start': 'להתחיל',
          'byHand': 'להזין ידנית',
          'continue': 'המשך',
          'itsMe': 'זה אני',
        });

        await tester.tap(find.text('לקרוא את המסמך'));
        await tester.pumpAndSettle();
        expect(
          chip.lastAlerts!.approach,
          'יש לקרב את המסמך לחלק העליון של הטלפון.',
        );
        expect(
          find.text('המסמך זז. יש להחזיק אותו ללא תנועה צמוד לטלפון.'),
          findsOneWidget,
        );

        chip.lastAlerts = null;
        chip.failure = null;
        await tester.tap(find.widgetWithText(ElevatedButton, 'לנסות שוב'));
        await tester.pumpAndSettle();
        expect(
          chip.lastAlerts!.done,
          'הסתיים.',
          reason: 'le nouvel essai garde la langue',
        );
      },
    );

    testWidgets('un refus du serveur est dit dans la langue du téléphone', (
      tester,
    ) async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(
          const VerificationOutcome(
            verified: false,
            reason: 'document_already_used',
          ),
        );
      await _pump(
        tester,
        const IdentityFlowScreen(),
        locale: const Locale('ru'),
        overrides: [
          chipReaderProvider.overrideWithValue(FakeChipReader()),
          identityVerificationApiProvider.overrideWithValue(api),
          identityLivenessCaptureProvider.overrideWithValue(FakeLiveness()),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ввести вручную'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'L898902C3');
      await tester.enterText(find.byType(TextField).at(1), '12081974');
      await tester.enterText(find.byType(TextField).at(2), '15042090');
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Это я'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Считать документ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сделать селфи'));
      await tester.pumpAndSettle();

      expect(
        find.text('Этот документ уже привязан к другому аккаунту.'),
        findsOneWidget,
      );
    });
  });
}
