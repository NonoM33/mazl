import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/verification_providers.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/presentation/features/verification/providers/verification_providers.dart';
import 'package:mazl/presentation/features/verification/screens/verification_screen.dart';
import 'package:mazl/presentation/features/verification/verification_reasons.dart';

class FakeVerificationApi implements VerificationApi {
  FakeVerificationApi({List<VerificationStatus>? statuses}) : statuses = statuses ?? [_none()];

  final List<VerificationStatus> statuses;
  int statusCalls = 0;
  ApiResponse<FaceSession> session = ApiResponse.success(FaceSession(
    sessionId: 'sess-1',
    challenges: const [FaceChallenge.front, FaceChallenge.left, FaceChallenge.right],
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
  ));
  ApiResponse<VerificationOutcome> outcome = ApiResponse.success(const VerificationOutcome(verified: true));
  int deleteCalls = 0;
  int submitCalls = 0;
  String? submittedSession;
  List<Uint8List>? submittedFrames;

  @override
  Future<ApiResponse<FaceSession>> startFaceSession(FacePurpose purpose) async => session;

  @override
  Future<ApiResponse<VerificationOutcome>> submitFace(String sessionId, List<Uint8List> frames) async {
    submitCalls++;
    submittedSession = sessionId;
    submittedFrames = frames;
    return outcome;
  }

  @override
  Future<ApiResponse<VerificationOutcome>> submitIdentity(String s, List<Uint8List> f, ChipReadResult c) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async {
    final index = statusCalls < statuses.length ? statusCalls : statuses.length - 1;
    statusCalls++;
    return ApiResponse.success(statuses[index]);
  }

  @override
  Future<ApiResponse<void>> deleteFaceReference() async {
    deleteCalls++;
    return ApiResponse<void>.success(null);
  }
}

class FakeCapture implements LivenessCapture {
  FakeCapture(this.frames);

  final List<Uint8List>? frames;
  List<FaceChallenge>? asked;

  @override
  Future<List<Uint8List>?> capture(BuildContext context, List<FaceChallenge> challenges) async {
    asked = challenges;
    return frames;
  }
}

VerificationStatus _none({int attempts = 0, DateTime? next}) => VerificationStatus.fromJson({
      'success': true,
      'photo': {'verified': false, 'verified_at': null, 'attempts_today': attempts},
      'identity': {'verified': false, 'verified_at': null, 'attempts_today': 0},
      'level': 'none',
      'is_verified': false,
      'attempts_today': attempts,
      'next_attempt_time': next?.toUtc().toIso8601String(),
    });

VerificationStatus _photoVerified() => VerificationStatus.fromJson({
      'success': true,
      'photo': {'verified': true, 'verified_at': '2026-10-20T09:00:00Z', 'attempts_today': 1},
      'identity': {'verified': false, 'verified_at': null, 'attempts_today': 0},
      'level': 'photo',
      'is_verified': true,
      'attempts_today': 1,
      'next_attempt_time': null,
    });

final _frames = [
  Uint8List.fromList([1]),
  Uint8List.fromList([2]),
  Uint8List.fromList([3]),
];

Future<void> _pump(WidgetTester tester, FakeVerificationApi api, FakeCapture capture) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      verificationApiProvider.overrideWithValue(api),
      livenessCaptureProvider.overrideWithValue(capture),
    ],
    child: const MaterialApp(home: VerificationScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('verificationReasonText', () {
    const codes = [
      'no_face', 'multiple_faces', 'face_too_small', 'pose_mismatch', 'duplicate_frames',
      'inconsistent_identity', 'no_profile_photo', 'profile_mismatch', 'daily_limit_reached',
      'session_expired', 'session_not_found', 'session_used', 'wrong_frame_count', 'invalid_image',
      'app_update_required', 'chip_data_invalid', 'chip_signature_invalid', 'csca_unknown',
      'document_expired', 'underage', 'document_already_used', 'document_banned',
      'document_face_mismatch', 'timeout', 'network',
    ];
    final generic = verificationReasonText('something_new');

    test('every server code has its own French text', () {
      final seen = <String>{};
      for (final code in codes) {
        final text = verificationReasonText(code);
        expect(text, isNot(generic), reason: code);
        expect(text, isNot(contains('_')), reason: '$code must not leak a raw code');
        seen.add(text);
      }
      // a few codes deliberately share a message
      expect(seen.length, greaterThanOrEqualTo(codes.length - 6));
    });

    test('unknown and null codes fall back to a generic message', () {
      expect(verificationReasonText(null), generic);
      expect(generic, contains('erreur'));
    });
  });

  group('VerificationScreen', () {
    testWidgets('shows the consent line, the action and the identity entry', (tester) async {
      await _pump(tester, FakeVerificationApi(), FakeCapture(_frames));

      expect(find.text(consentText), findsOneWidget);
      expect(find.text(
          'Nous comparons ton visage à tes photos. Les images ne sont pas conservées ; '
          'seule une empreinte chiffrée l\'est, supprimable à tout moment.'), findsOneWidget);
      expect(find.text('Vérifier ma photo'), findsOneWidget);
      expect(find.text('Vérifier mon identité (passeport / CNI)'), findsOneWidget);
      final identityTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Vérifier mon identité (passeport / CNI)'));
      expect(identityTile.enabled, isTrue);
      expect(find.text('Bientôt'), findsNothing);
    });

    testWidgets('runs session, capture and submit, then shows the verified state', (tester) async {
      final api = FakeVerificationApi(statuses: [_none(), _photoVerified()])
        ..outcome = ApiResponse.success(const VerificationOutcome(
          verified: true,
          photoMatches: [PhotoMatch(photoId: 12, match: true), PhotoMatch(photoId: 13, match: false)],
        ));
      final capture = FakeCapture(_frames);
      await _pump(tester, api, capture);

      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();

      expect(capture.asked, [FaceChallenge.front, FaceChallenge.left, FaceChallenge.right]);
      expect(api.submittedSession, 'sess-1');
      expect(api.submittedFrames, _frames);
      expect(find.text('Vérifiée le 20/10/2026.'), findsOneWidget);
      expect(find.text('Retirer ma vérification'), findsOneWidget);
      expect(find.text('Une de tes photos ne te ressemble pas : elle ne compte pas.'), findsOneWidget);
      expect(find.text('Vérifier ma photo'), findsNothing);
    });

    for (final entry in {
      'no_face': 'Aucun visage détecté',
      'multiple_faces': 'Plusieurs visages détectés',
      'face_too_small': 'Ton visage est trop loin',
      'pose_mismatch': 'Les poses demandées n\'ont pas été reconnues',
      'duplicate_frames': 'Les images sont trop semblables',
      'inconsistent_identity': 'Les images ne montrent pas la même personne',
      'no_profile_photo': 'Ajoute d\'abord à ton profil une photo',
      'profile_mismatch': 'Ton visage ne correspond pas à ta photo principale',
      'session_expired': 'La session a expiré',
      'daily_limit_reached': 'limite d\'essais',
    }.entries) {
      testWidgets('server refusal ${entry.key} is shown in French', (tester) async {
        final api = FakeVerificationApi()
          ..outcome = ApiResponse.success(VerificationOutcome(verified: false, reason: entry.key));
        await _pump(tester, api, FakeCapture(_frames));

        await tester.tap(find.text('Vérifier ma photo'));
        await tester.pumpAndSettle();

        expect(find.textContaining(entry.value), findsOneWidget);
        expect(find.textContaining(entry.key), findsNothing);
        expect(find.text('Vérifier ma photo'), findsOneWidget, reason: 'the user can retry');
      });
    }

    testWidgets('a 429 on session start shows the daily limit and never opens the camera', (tester) async {
      final api = FakeVerificationApi()..session = ApiResponse.failure('daily_limit_reached');
      final capture = FakeCapture(_frames);
      await _pump(tester, api, capture);

      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('limite d\'essais'), findsOneWidget);
      expect(capture.asked, isNull);
      expect(api.submitCalls, 0);
    });

    testWidgets('a network failure on submit is explained, not shown raw', (tester) async {
      final api = FakeVerificationApi()..outcome = ApiResponse.failure('network', ApiErrorKind.network);
      await _pump(tester, api, FakeCapture(_frames));

      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Connexion impossible'), findsOneWidget);
    });

    testWidgets('cancelling the capture submits nothing and shows no error', (tester) async {
      final api = FakeVerificationApi();
      await _pump(tester, api, FakeCapture(null));

      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();

      expect(api.submitCalls, 0);
      expect(find.text('Vérifier ma photo'), findsOneWidget);
      expect(find.textContaining('expiré'), findsNothing);
    });

    testWidgets('a capture that returns after the session expired says so', (tester) async {
      final api = FakeVerificationApi()
        ..session = ApiResponse.success(FaceSession(
          sessionId: 's',
          challenges: const [FaceChallenge.front],
          expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
      await _pump(tester, api, FakeCapture(null));

      await tester.tap(find.text('Vérifier ma photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('La session a expiré'), findsOneWidget);
    });

    testWidgets('quota reached: the action is disabled', (tester) async {
      final api = FakeVerificationApi(
        statuses: [_none(attempts: 3, next: DateTime.now().add(const Duration(hours: 5)))],
      );
      await _pump(tester, api, FakeCapture(_frames));

      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Vérifier ma photo'));
      expect(button.onPressed, isNull);
      expect(find.textContaining('Limite atteinte'), findsOneWidget);
    });

    testWidgets('removing the verification asks for confirmation first', (tester) async {
      final api = FakeVerificationApi(statuses: [_photoVerified(), _none()]);
      await _pump(tester, api, FakeCapture(_frames));

      await tester.tap(find.text('Retirer ma vérification'));
      await tester.pumpAndSettle();
      expect(find.text('Retirer ma vérification ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(api.deleteCalls, 0);

      await tester.tap(find.text('Retirer ma vérification'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(find.text('Vérifier ma photo'), findsOneWidget);
    });
  });
}
