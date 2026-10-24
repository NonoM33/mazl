import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/di/providers/verification_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/presentation/features/verification/providers/verification_providers.dart';
import 'package:mazl/presentation/features/verification/screens/verification_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import '../verification_l10n.dart';

const _locales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

class _Api implements VerificationApi {
  _Api(this.status, {this.outcome, this.statusResponse});

  VerificationStatus status;
  ApiResponse<VerificationOutcome>? outcome;
  ApiResponse<VerificationStatus>? statusResponse;

  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async =>
      statusResponse ?? ApiResponse.success(status);

  @override
  Future<ApiResponse<FaceSession>> startFaceSession(
    FacePurpose purpose,
  ) async => ApiResponse.success(
    FaceSession(
      sessionId: 's',
      challenges: const [FaceChallenge.front],
      expiresAt: DateTime(2100),
    ),
  );

  @override
  Future<ApiResponse<VerificationOutcome>> submitFace(
    String sessionId,
    List<Uint8List> frames,
  ) async =>
      outcome ?? ApiResponse.success(const VerificationOutcome(verified: true));

  @override
  Future<ApiResponse<VerificationOutcome>> submitIdentity(
    String s,
    List<Uint8List> f,
    ChipReadResult c,
  ) => throw UnimplementedError();

  @override
  Future<ApiResponse<void>> deleteFaceReference() async =>
      ApiResponse<void>.success(null);
}

class _Capture implements LivenessCapture {
  @override
  Future<List<Uint8List>?> capture(
    BuildContext context,
    List<FaceChallenge> challenges,
  ) async => [
    Uint8List.fromList([1]),
  ];
}

VerificationStatus _status({
  bool photo = false,
  bool identity = false,
  DateTime? next,
}) => VerificationStatus.fromJson({
  'photo': {
    'verified': photo,
    'verified_at': photo ? '2026-10-20T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'identity': {
    'verified': identity,
    'verified_at': identity ? '2026-10-21T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
  'is_verified': photo || identity,
  'next_attempt_time': next?.toUtc().toIso8601String(),
});

Future<void> _pump(
  WidgetTester tester,
  _Api api, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    const VerificationScreen(),
    locale: locale,
    brightness: brightness,
    overrides: [
      verificationApiProvider.overrideWithValue(api),
      livenessCaptureProvider.overrideWithValue(_Capture()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadDatePatterns);

  group('page de vérification en anglais', () {
    testWidgets('rien de vérifié : titres, niveaux, consentement et actions', (
      tester,
    ) async {
      await _pump(tester, _Api(_status()), locale: const Locale('en'));

      expect(find.text('YOUR PROFILE'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('Photo verified'), findsOneWidget);
      expect(find.text('LEVEL 2'), findsOneWidget);
      expect(find.text('Identity verified'), findsOneWidget);
      expect(find.text(l10nFor('en').verificationConsent), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Verify my photo'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Verify my identity'),
        findsOneWidget,
      );
      expect(find.text('Vérifier ma photo'), findsNothing);
    });

    testWidgets(
      'tout vérifié : la date suit la langue (mois avant jour en anglais)',
      (tester) async {
        await _pump(
          tester,
          _Api(_status(photo: true, identity: true)),
          locale: const Locale('en'),
        );

        expect(find.text('Verified'), findsNWidgets(2));
        expect(find.text('Verified on 10/20/2026.'), findsOneWidget);
        expect(find.text('Checked on 10/21/2026.'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Remove my verification'),
          findsOneWidget,
        );
      },
    );

    testWidgets('un refus du serveur est dit en anglais, jamais le code brut', (
      tester,
    ) async {
      final api = _Api(
        _status(),
        outcome: ApiResponse.success(
          const VerificationOutcome(verified: false, reason: 'no_face'),
        ),
      );
      await _pump(tester, api, locale: const Locale('en'));

      await tester.tap(find.text('Verify my photo'));
      await tester.pumpAndSettle();

      expect(
        find.text('No face detected. Face the camera in a well-lit place.'),
        findsOneWidget,
      );
      expect(find.textContaining('no_face'), findsNothing);
    });

    testWidgets('des photos écartées : la remarque accorde le pluriel', (
      tester,
    ) async {
      final api = _Api(
        _status(),
        outcome: ApiResponse.success(
          const VerificationOutcome(
            verified: true,
            photoMatches: [
              PhotoMatch(photoId: 1, match: false),
              PhotoMatch(photoId: 2, match: false),
            ],
          ),
        ),
      );
      await _pump(tester, api, locale: const Locale('en'));

      await tester.tap(find.text('Verify my photo'));
      await tester.pumpAndSettle();

      expect(
        find.text('2 of your photos do not look like you: they do not count.'),
        findsOneWidget,
      );
    });

    testWidgets('retirer la vérification : la confirmation est en anglais', (
      tester,
    ) async {
      await _pump(
        tester,
        _Api(_status(photo: true)),
        locale: const Locale('en'),
      );

      await tester.tap(find.text('Remove my verification'));
      await tester.pumpAndSettle();

      expect(find.text('Remove my verification?'), findsOneWidget);
      expect(
        find.text('Your badge and your face print will be deleted.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Remove'), findsOneWidget);
    });

    testWidgets('statut illisible : message traduit et bouton Réessayer', (
      tester,
    ) async {
      final api = _Api(
        _status(),
        statusResponse: ApiResponse.failure('network', ApiErrorKind.network),
      );
      await _pump(tester, api, locale: const Locale('en'));

      expect(
        find.text("Can't connect. Check your network and try again."),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
    });

    testWidgets(
      'quota atteint : le prochain essai donne le jour et l\'heure dans la langue',
      (tester) async {
        final next = DateTime.now().add(const Duration(days: 3));
        await _pump(
          tester,
          _Api(_status(next: next)),
          locale: const Locale('en'),
        );

        final strings = l10nFor('en');
        expect(
          find.text(
            strings.verificationBlockedLater(next.toLocal(), next.toLocal()),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Limit reached, you can try again on '),
          findsOneWidget,
        );
      },
    );

    testWidgets('quota atteint dans la journée : seule l\'heure est dite', (
      tester,
    ) async {
      final next = DateTime.now().add(const Duration(seconds: 30));
      await _pump(
        tester,
        _Api(_status(next: next)),
        locale: const Locale('en'),
      );

      final strings = l10nFor('en');
      final sameDay = next.day == DateTime.now().day;
      final expected = sameDay
          ? strings.verificationBlockedToday(next.toLocal())
          : strings.verificationBlockedLater(next.toLocal(), next.toLocal());
      expect(find.text(expected), findsOneWidget);
    });
  });

  group('page de vérification en hébreu : de droite à gauche', () {
    testWidgets('les textes sont hébreux et lus de droite à gauche', (
      tester,
    ) async {
      await _pump(tester, _Api(_status()), locale: const Locale('he'));

      final title = find.text('אימות');
      expect(title, findsOneWidget);
      expect(textDirectionAt(tester, title), TextDirection.rtl);
      expect(find.text('תמונה מאומתת'), findsOneWidget);
      expect(find.text('זהות מאומתת'), findsOneWidget);
      expect(find.text(l10nFor('he').verificationConsent), findsOneWidget);
    });

    testWidgets(
      '« retour » est un bouton rond au bord droit, flèche vers la droite',
      (tester) async {
        await _pump(tester, _Api(_status()), locale: const Locale('he'));

        expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
        expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
        final center = tester.getCenter(find.byIcon(LucideIcons.arrowRight));
        expect(
          center.dx,
          greaterThan(kSmallPhone.width / 2),
          reason: 'le bouton retour est au bord de départ, à droite',
        );
      },
    );

    testWidgets(
      'en français et en anglais, retour reste à gauche, flèche vers la gauche',
      (tester) async {
        for (final locale in const [Locale('fr'), Locale('en')]) {
          await _pump(tester, _Api(_status()), locale: locale);
          expect(
            find.byIcon(LucideIcons.arrowLeft),
            findsOneWidget,
            reason: locale.languageCode,
          );
          expect(
            tester.getCenter(find.byIcon(LucideIcons.arrowLeft)).dx,
            lessThan(kSmallPhone.width / 2),
          );
        }
      },
    );

    testWidgets('les pastilles « vérifiée » et les dates sont en hébreu', (
      tester,
    ) async {
      await _pump(
        tester,
        _Api(_status(photo: true, identity: true)),
        locale: const Locale('he'),
      );

      final strings = l10nFor('he');
      expect(find.text('מאומתת'), findsNWidgets(2));
      expect(
        find.text(strings.verificationPhotoVerifiedOn(DateTime(2026, 10, 20))),
        findsOneWidget,
      );
      expect(find.text('אומת בתאריך 20.10.2026.'), findsOneWidget);
    });
  });

  group(
    'page de vérification : tient à 360 px, clair et sombre, dans les cinq langues',
    () {
      for (final locale in _locales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            '${locale.languageCode} ${brightness.name} : rien de vérifié',
            (tester) async {
              await _pump(
                tester,
                _Api(_status()),
                locale: locale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            },
          );

          testWidgets(
            '${locale.languageCode} ${brightness.name} : tout vérifié',
            (tester) async {
              await _pump(
                tester,
                _Api(_status(photo: true, identity: true)),
                locale: locale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            },
          );

          testWidgets(
            '${locale.languageCode} ${brightness.name} : refus, remarque et quota',
            (tester) async {
              final api = _Api(
                _status(next: DateTime.now().add(const Duration(days: 3))),
                outcome: ApiResponse.success(
                  const VerificationOutcome(
                    verified: false,
                    reason: 'profile_mismatch',
                  ),
                ),
              );
              await _pump(tester, api, locale: locale, brightness: brightness);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }

      testWidgets('le texte de refus le plus long tient dans chaque langue', (
        tester,
      ) async {
        for (final locale in _locales) {
          final api = _Api(
            _status(),
            outcome: ApiResponse.success(
              const VerificationOutcome(
                verified: false,
                reason: 'profile_mismatch',
              ),
            ),
          );
          await _pump(tester, api, locale: locale);
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
          expect(
            find.text(
              l10nFor(locale.languageCode).verificationReasonProfileMismatch,
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: locale.languageCode);
        }
      });
    },
  );
}
