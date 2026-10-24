import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/presentation/features/verification/capture/liveness_controller.dart';
import 'package:mazl/presentation/features/verification/capture/liveness_stage.dart';
import 'package:mazl/presentation/features/verification/capture/liveness_texts.dart';
import 'package:mazl/presentation/features/verification/identity/identity_layout.dart';
import 'package:mazl/presentation/features/verification/identity/identity_parts.dart';

import '../../../helpers/l10n_helpers.dart';
import '../verification_l10n.dart';

const _locales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

Widget _stage(
  AppLocalizations l10n, {
  FaceChallenge challenge = FaceChallenge.left,
  PoseFeedback? feedback,
}) => LivenessStage(
  camera: const SizedBox.expand(),
  instruction: challengeInstruction(l10n, challenge),
  hint: feedback == null ? null : poseFeedbackText(l10n, feedback),
  holdProgress: 0.4,
  total: 3,
  done: 1,
  onCancel: () {},
);

Future<void> _pump(
  WidgetTester tester,
  Widget Function(AppLocalizations l10n) build,
  Locale locale, {
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    Builder(builder: (context) => build(context.l10n)),
    locale: locale,
    brightness: brightness,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('consignes et aides', () {
    test(
      'chaque consigne et chaque aide existe dans les cinq langues, sans doublon dans une langue',
      () {
        for (final locale in _locales) {
          final l10n = l10nFor(locale.languageCode);
          final instructions = [
            for (final c in FaceChallenge.values) challengeInstruction(l10n, c),
          ];
          final hints = [
            for (final f in PoseFeedback.values)
              if (poseFeedbackText(l10n, f) != null) poseFeedbackText(l10n, f)!,
          ];
          expect(
            instructions.toSet(),
            hasLength(instructions.length),
            reason: locale.languageCode,
          );
          expect(
            hints.toSet(),
            hasLength(hints.length),
            reason: locale.languageCode,
          );
          for (final text in [...instructions, ...hints]) {
            expect(text.trim(), isNotEmpty);
          }
        }
      },
    );

    test('rien à corriger : pas d\'aide', () {
      expect(poseFeedbackText(frenchL10n, PoseFeedback.holding), isNull);
    });

    test('le français est celui de la référence', () {
      expect(
        challengeInstruction(frenchL10n, FaceChallenge.front),
        'Regardez l\'objectif',
      );
      expect(
        challengeInstruction(frenchL10n, FaceChallenge.left),
        'Tournez doucement la tête vers la gauche',
      );
      expect(
        poseFeedbackText(frenchL10n, PoseFeedback.turnLess),
        'Pas autant, revenez un peu',
      );
      expect(
        poseFeedbackText(frenchL10n, PoseFeedback.turnOtherWay),
        'Tournez de l\'autre côté',
      );
    });

    test(
      'gauche et droite restent la gauche et la droite du membre, dans chaque langue',
      () {
        final left = {
          'fr': 'gauche',
          'en': 'left',
          'he': 'שמאלה',
          'es': 'izquierda',
          'ru': 'влево',
        };
        final right = {
          'fr': 'droite',
          'en': 'right',
          'he': 'ימינה',
          'es': 'derecha',
          'ru': 'вправо',
        };
        for (final code in left.keys) {
          final l10n = l10nFor(code);
          expect(
            challengeInstruction(l10n, FaceChallenge.left),
            contains(left[code]!),
            reason: code,
          );
          expect(
            challengeInstruction(l10n, FaceChallenge.right),
            contains(right[code]!),
            reason: code,
          );
        }
      },
    );
  });

  group('écran du selfie', () {
    testWidgets(
      'en anglais : pose en cours, consigne, aide, rappel de confidentialité',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          (l10n) => _stage(l10n, feedback: PoseFeedback.tooSmall),
          const Locale('en'),
        );

        expect(find.text('POSE 2 / 3'), findsOneWidget);
        expect(find.text('Slowly turn your head to the left'), findsOneWidget);
        expect(find.text('Move a little closer'), findsOneWidget);
        expect(
          find.text('Alone in the frame, well lit. The images are not kept.'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Poses captured: 1 of 3'), findsOneWidget);
        expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('en hébreu : de droite à gauche, annuler au bord droit', (
      tester,
    ) async {
      await _pump(
        tester,
        (l10n) => _stage(l10n, feedback: PoseFeedback.noFace),
        const Locale('he'),
      );

      final instruction = find.text('להסב לאט את הראש שמאלה');
      expect(instruction, findsOneWidget);
      expect(textDirectionAt(tester, instruction), TextDirection.rtl);
      expect(find.text('תנוחה 2 מתוך 3'), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(LucideIcons.x)).dx,
        greaterThan(kSmallPhone.width / 2),
      );
    });

    testWidgets('en français, annuler reste à gauche', (tester) async {
      await _pump(tester, (l10n) => _stage(l10n), const Locale('fr'));
      expect(find.text('POSE 2 / 3'), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(LucideIcons.x)).dx,
        lessThan(kSmallPhone.width / 2),
      );
    });

    testWidgets(
      'toute consigne avec toute aide tient à 360 px dans les cinq langues',
      (tester) async {
        for (final locale in _locales) {
          for (final challenge in FaceChallenge.values) {
            for (final feedback in PoseFeedback.values) {
              await _pump(
                tester,
                (l10n) =>
                    _stage(l10n, challenge: challenge, feedback: feedback),
                locale,
              );
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${locale.languageCode} ${challenge.name} ${feedback.name}',
              );
            }
          }
        }
      },
    );
  });

  group('écrans de message de la capture', () {
    Widget expired(AppLocalizations l10n) => IdentityNotice(
      dark: true,
      icon: LucideIcons.clock,
      title: l10n.verificationLivenessExpiredTitle,
      body: l10n.verificationLivenessExpiredBody,
      onClose: () {},
      actions: [IdentityPrimaryButton(l10n.commonClose, onPressed: () {})],
    );

    Widget permission(AppLocalizations l10n, {required bool settings}) =>
        IdentityNotice(
          dark: true,
          icon: LucideIcons.camera,
          title: l10n.verificationCameraNeededTitle,
          body: l10n.verificationCameraNeededBody,
          onClose: () {},
          actions: [
            IdentityPrimaryButton(
              settings
                  ? l10n.verificationCameraOpenSettings
                  : l10n.verificationCameraAllow,
              onPressed: () {},
            ),
            IdentityLinkButton(l10n.commonCancel, onPressed: () {}),
          ],
        );

    Widget unavailable(AppLocalizations l10n) => IdentityNotice(
      dark: true,
      icon: LucideIcons.cameraOff,
      title: l10n.verificationCameraUnavailableTitle,
      body: l10n.verificationCameraUnavailableBody,
      onClose: () {},
      actions: [IdentityPrimaryButton(l10n.commonClose, onPressed: () {})],
    );

    testWidgets('en anglais', (tester) async {
      await _pump(tester, expired, const Locale('en'));
      expect(find.text('Session expired'), findsOneWidget);
      expect(
        find.text('The allotted time has run out. You can start again.'),
        findsOneWidget,
      );

      await _pump(
        tester,
        (l10n) => permission(l10n, settings: true),
        const Locale('en'),
      );
      expect(find.text('Camera needed'), findsOneWidget);
      expect(
        find.text(
          'MAZL uses the front camera to check that you are the person in your photos.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Open settings'),
        findsOneWidget,
      );

      await _pump(
        tester,
        (l10n) => permission(l10n, settings: false),
        const Locale('en'),
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Allow camera access'),
        findsOneWidget,
      );

      await _pump(tester, unavailable, const Locale('en'));
      expect(find.text('Camera unavailable'), findsOneWidget);
      expect(
        find.text('The front camera could not be started.'),
        findsOneWidget,
      );
    });

    testWidgets('tiennent à 360 px dans les cinq langues', (tester) async {
      for (final locale in _locales) {
        for (final build in <Widget Function(AppLocalizations)>[
          expired,
          (l10n) => permission(l10n, settings: true),
          (l10n) => permission(l10n, settings: false),
          unavailable,
        ]) {
          await _pump(tester, build, locale);
          expect(tester.takeException(), isNull, reason: locale.languageCode);
        }
      }
    });
  });
}
