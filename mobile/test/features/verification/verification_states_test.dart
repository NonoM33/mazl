import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/verification_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/fold_pages.dart';
import 'package:mazl/presentation/features/verification/providers/verification_providers.dart';
import 'package:mazl/presentation/features/verification/screens/verification_header.dart';
import 'package:mazl/presentation/features/verification/screens/verification_level_card.dart';
import 'package:mazl/presentation/features/verification/screens/verification_screen.dart';

import '../../helpers/l10n_helpers.dart';
import 'verification_l10n.dart';
import 'verification_screen_test.dart' show FakeCapture, FakeVerificationApi;

class _Failing extends FakeVerificationApi {
  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async =>
      ApiResponse.failure('network', ApiErrorKind.network);
}

class _NeverLoads extends FakeVerificationApi {
  @override
  Future<ApiResponse<VerificationStatus>> getStatus() =>
      Completer<ApiResponse<VerificationStatus>>().future;
}

class _Hanging implements LivenessCapture {
  @override
  Future<List<Uint8List>?> capture(
    BuildContext context,
    List<FaceChallenge> challenges,
  ) => Completer<List<Uint8List>?>().future;
}

VerificationStatus _status({
  bool photo = false,
  bool identity = false,
  DateTime? next,
}) => VerificationStatus.fromJson({
  'photo': {
    'verified': photo,
    'verified_at': photo ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'identity': {
    'verified': identity,
    'verified_at': identity ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
  'is_verified': photo || identity,
  'next_attempt_time': next?.toUtc().toIso8601String(),
});

final _frames = [
  Uint8List.fromList([1]),
];

Future<void> _pump(
  WidgetTester tester,
  FakeVerificationApi api, {
  LivenessCapture? capture,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  await pumpLocalized(
    tester,
    const VerificationScreen(),
    brightness: brightness,
    size: const Size(390, 2400),
    overrides: [
      verificationApiProvider.overrideWithValue(api),
      livenessCaptureProvider.overrideWithValue(
        capture ?? FakeCapture(_frames),
      ),
    ],
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Finder _pill(String label) => find.descendant(
  of: find.byType(LevelStatePill),
  matching: find.text(label),
);

/// WCAG contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(loadAppFonts);

  group('en-tête', () {
    testWidgets(
      'rien de vérifié : « Vérifiez votre profil », progression 0 sur 2',
      (tester) async {
        await _pump(tester, FakeVerificationApi(statuses: [_status()]));

        expect(find.text('Vérifiez votre profil'), findsOneWidget);
        expect(find.text(frenchL10n.verificationStateNoneBody), findsOneWidget);
        expect(find.text('0 sur 2 niveaux vérifiés'), findsOneWidget);
      },
    );

    testWidgets(
      'un niveau sur deux : « Vérification en cours », progression 1 sur 2',
      (tester) async {
        await _pump(
          tester,
          FakeVerificationApi(statuses: [_status(photo: true)]),
        );

        expect(find.text('Vérification en cours'), findsOneWidget);
        expect(
          find.text(frenchL10n.verificationStatePartialBody),
          findsOneWidget,
        );
        expect(find.text('1 sur 2 niveaux vérifiés'), findsOneWidget);
      },
    );

    testWidgets(
      'les deux niveaux : « Profil entièrement vérifié », progression 2 sur 2',
      (tester) async {
        await _pump(
          tester,
          FakeVerificationApi(statuses: [_status(photo: true, identity: true)]),
        );

        expect(find.text('Profil entièrement vérifié'), findsOneWidget);
        expect(find.text(frenchL10n.verificationStateDoneBody), findsOneWidget);
        expect(find.text('2 sur 2 niveaux vérifiés'), findsOneWidget);
      },
    );

    testWidgets('la progression est annoncée en un seul libellé', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        FakeVerificationApi(statuses: [_status(photo: true)]),
      );

      expect(find.bySemanticsLabel('1 sur 2 niveaux vérifiés'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('deux segments, remplis selon les niveaux vérifiés', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeVerificationApi(statuses: [_status(photo: true)]),
      );

      final primary = AppTheme.lightTheme.colorScheme.primary;
      final segments = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(VerificationProgress),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(segments, [primary, AppTheme.lightTheme.colorScheme.outline]);
    });
  });

  group('cartes des niveaux', () {
    testWidgets(
      'rien de vérifié : deux pastilles « À faire », deux actions, pas de retrait',
      (tester) async {
        await _pump(tester, FakeVerificationApi(statuses: [_status()]));

        expect(_pill('À faire'), findsNWidgets(2));
        expect(
          find.widgetWithText(ElevatedButton, 'Vérifier ma photo'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Vérifier mon identité'),
          findsOneWidget,
        );
        expect(find.text('Retirer ma vérification'), findsNothing);
      },
    );

    testWidgets(
      'niveau 1 seul : pastille « Vérifiée » avec sa date, l\'identité devient l\'action principale',
      (tester) async {
        await _pump(
          tester,
          FakeVerificationApi(statuses: [_status(photo: true)]),
        );

        expect(_pill('Vérifiée'), findsOneWidget);
        expect(_pill('À faire'), findsOneWidget);
        expect(find.text('Le 26 octobre 2026'), findsOneWidget);
        expect(find.text('Vérifier ma photo'), findsNothing);
        expect(
          find.widgetWithText(ElevatedButton, 'Vérifier mon identité'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextButton, 'Retirer ma vérification'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'les deux vérifiés : plus aucune action de vérification, le retrait reste',
      (tester) async {
        await _pump(
          tester,
          FakeVerificationApi(statuses: [_status(photo: true, identity: true)]),
        );

        expect(_pill('Vérifiée'), findsNWidgets(2));
        expect(find.text('Le 26 octobre 2026'), findsNWidgets(2));
        expect(find.text('Vérifier ma photo'), findsNothing);
        expect(find.text('Vérifier mon identité'), findsNothing);
        expect(
          find.widgetWithText(TextButton, 'Retirer ma vérification'),
          findsOneWidget,
        );
      },
    );

    testWidgets('chaque niveau dit ce qu\'il apporte en trois puces', (
      tester,
    ) async {
      await _pump(tester, FakeVerificationApi(statuses: [_status()]));

      for (final text in [
        frenchL10n.verificationPhotoBenefitBadge,
        frenchL10n.verificationPhotoBenefitProof,
        frenchL10n.verificationPhotoBenefitQuick,
        frenchL10n.verificationIdentityBenefitBadge,
        frenchL10n.verificationIdentityBenefitChip,
        frenchL10n.verificationIdentityBenefitNeeds,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets(
      'refusé : pastille « Refusée », la remarque et de quoi réessayer',
      (tester) async {
        final api = FakeVerificationApi(statuses: [_status()])
          ..outcome = ApiResponse.success(
            const VerificationOutcome(verified: false, reason: 'no_face'),
          );
        await _pump(tester, api);

        await tester.tap(find.text('Vérifier ma photo'));
        await tester.pumpAndSettle();

        expect(_pill('Refusée'), findsOneWidget);
        expect(_pill('À faire'), findsOneWidget);
        expect(find.textContaining('Aucun visage détecté'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Vérifier ma photo'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'en cours : pastille « En cours », titre « Vérification en cours », actions bloquées',
      (tester) async {
        final api = FakeVerificationApi(statuses: [_status()]);
        await _pump(tester, api, capture: _Hanging());

        await tester.tap(find.text('Vérifier ma photo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(_pill('En cours'), findsOneWidget);
        expect(find.text('Vérification en cours'), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Vérifier mon identité'),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('limite atteinte : pastille, action bloquée, prochain essai', (
      tester,
    ) async {
      final next = DateTime.now().add(const Duration(hours: 5));
      await _pump(tester, FakeVerificationApi(statuses: [_status(next: next)]));

      expect(_pill('Limite atteinte'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Vérifier ma photo'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('Limite atteinte, nouvel essai'),
        findsOneWidget,
      );
    });

    testWidgets('chargement : un indicateur, ni carte ni titre', (
      tester,
    ) async {
      await _pump(tester, _NeverLoads(), settle: false);

      expect(find.byType(FoldSpinner), findsOneWidget);
      expect(find.byType(LevelCard), findsNothing);
      expect(find.byType(VerificationHeader), findsNothing);
    });

    testWidgets('erreur : le message et « Réessayer », ni carte ni retrait', (
      tester,
    ) async {
      await _pump(tester, _Failing());

      expect(find.textContaining('Connexion impossible'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Réessayer'), findsOneWidget);
      expect(find.byType(LevelCard), findsNothing);
      expect(find.text('Retirer ma vérification'), findsNothing);
    });
  });

  group('retirer ma vérification', () {
    testWidgets(
      'une action discrète en couleur d\'erreur, pas un gros bouton plein',
      (tester) async {
        await _pump(
          tester,
          FakeVerificationApi(statuses: [_status(photo: true)]),
        );

        final button = find.widgetWithText(
          TextButton,
          'Retirer ma vérification',
        );
        expect(button, findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Retirer ma vérification'),
          findsNothing,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Retirer ma vérification'),
          findsNothing,
        );
        final color = tester
            .widget<TextButton>(button)
            .style!
            .foregroundColor!
            .resolve(const {});
        expect(color, AppTheme.lightTheme.colorScheme.error);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      },
    );

    testWidgets(
      'la confirmation existante passe toujours avant la suppression',
      (tester) async {
        final api = FakeVerificationApi(
          statuses: [_status(photo: true), _status()],
        );
        await _pump(tester, api);

        await tester.tap(find.text('Retirer ma vérification'));
        await tester.pumpAndSettle();
        expect(find.text('Retirer ma vérification ?'), findsOneWidget);
        expect(api.deleteCalls, 0);

        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();
        expect(api.deleteCalls, 1);
        expect(find.text('Retirer ma vérification'), findsNothing);
      },
    );
  });

  group('confidentialité et zones tactiles', () {
    testWidgets(
      'la note de confidentialité est toujours là, avec son cadenas',
      (tester) async {
        for (final status in [
          _status(),
          _status(photo: true, identity: true),
        ]) {
          await _pump(tester, FakeVerificationApi(statuses: [status]));
          expect(find.text(frenchL10n.verificationConsent), findsOneWidget);
        }
      },
    );

    testWidgets('chaque bouton fait au moins 44 x 44 pt', (tester) async {
      await _pump(
        tester,
        FakeVerificationApi(statuses: [_status(photo: true)]),
      );

      for (final button in [
        find.widgetWithText(ElevatedButton, 'Vérifier mon identité'),
        find.widgetWithText(TextButton, 'Retirer ma vérification'),
      ]) {
        final size = tester.getSize(button);
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      }
    });
  });

  group('contraste AA, clair et sombre', () {
    for (final theme in {
      'clair': AppTheme.lightTheme,
      'sombre': AppTheme.darkTheme,
    }.entries) {
      test('les textes de la page sont lisibles en mode ${theme.key}', () {
        final scheme = theme.value.colorScheme;
        final pairs = <String, (Color, Color)>{
          'texte sur la carte': (scheme.onSurface, scheme.surfaceContainer),
          'texte secondaire sur la carte': (
            scheme.onSurfaceVariant,
            scheme.surfaceContainer,
          ),
          'texte secondaire sur la page': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'retirer, en couleur d\'erreur, sur la page': (
            scheme.error,
            scheme.surface,
          ),
          'icône du niveau vérifié': (scheme.onPrimary, scheme.primary),
          'icône de l\'en-tête': (
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ),
        };
        for (final state in LevelState.values) {
          final (background, foreground) = LevelStatePill.colors(scheme, state);
          pairs['pastille ${state.name}'] = (foreground, background);
        }
        for (final pair in pairs.entries) {
          expect(
            _contrast(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${pair.key} en mode ${theme.key}',
          );
        }
      });

      test(
        'les segments remplis et les icônes de puce se distinguent du fond en mode ${theme.key}',
        () {
          final scheme = theme.value.colorScheme;
          expect(
            _contrast(scheme.primary, scheme.surfaceContainer),
            greaterThanOrEqualTo(3),
          );
          expect(
            _contrast(scheme.primary, scheme.surface),
            greaterThanOrEqualTo(3),
          );
          expect(
            _contrast(scheme.outline, scheme.surface),
            greaterThanOrEqualTo(1.2),
          );
        },
      );
    }
  });
}
