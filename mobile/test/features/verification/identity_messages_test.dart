import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';

// Every IdentityRejection of docs/verification/CONTRAT.md §4
// (src/features/verification/domain/types.ts), written out by hand.
const _contractCodes = [
  'session_not_found', 'session_expired', 'session_used', 'wrong_frame_count', 'invalid_image', 'no_face',
  'multiple_faces', 'face_too_small', 'pose_mismatch', 'duplicate_frames', 'inconsistent_identity',
  'no_profile_photo', 'profile_mismatch', 'daily_limit_reached',
  'chip_data_invalid', 'chip_signature_invalid', 'csca_unknown', 'document_expired', 'underage',
  'document_already_used', 'document_banned', 'document_face_mismatch',
];

void main() {
  final generic = describeIdentityRejection('something_new').message;

  test('every code of the contract has its own message', () {
    for (final code in _contractCodes) {
      final info = describeIdentityRejection(code);
      expect(info.message, isNot(generic), reason: code);
      expect(info.message, isNotEmpty);
      expect(info.actionLabel, isNotEmpty);
    }
  });

  test('messages are short single sentences', () {
    for (final code in [..._contractCodes, 'unknown']) {
      final message = describeIdentityRejection(code).message;
      expect(message.length, lessThan(90), reason: code);
      expect(message, endsWith('.'), reason: code);
      expect(message, isNot(contains('  ')), reason: code);
    }
  });

  test('fixed wording asked by the product', () {
    expect(describeIdentityRejection('csca_unknown').message, 'Document non reconnu.');
    expect(describeIdentityRejection('document_expired').message, 'Ce document est expiré.');
  });

  test('unknown or missing code falls back to a retryable generic failure', () {
    expect(describeIdentityRejection(null).recovery, IdentityRecovery.retryFace);
    expect(describeIdentityRejection('something_new').recovery, IdentityRecovery.retryFace);
  });

  test('final refusals offer no retry', () {
    for (final code in ['csca_unknown', 'underage', 'document_already_used', 'document_banned', 'daily_limit_reached']) {
      expect(describeIdentityRejection(code).recovery, IdentityRecovery.close, reason: code);
    }
  });

  test('only cases a human can settle offer the manual review link', () {
    expect(describeIdentityRejection('csca_unknown').offerManualReview, isTrue);
    expect(describeIdentityRejection('document_banned').offerManualReview, isFalse);
    expect(describeIdentityRejection('document_already_used').offerManualReview, isFalse);
  });

  test('every chip failure is described, except the user closing the sheet', () {
    for (final kind in ChipFailureKind.values) {
      final info = describeChipFailure(kind);
      if (kind == ChipFailureKind.cancelled) {
        expect(info, isNull);
      } else {
        expect(info, isNotNull, reason: kind.name);
        expect(info!.message, endsWith('.'));
      }
    }
  });

  test('wrong MRZ proposes a new scan', () {
    expect(describeChipFailure(ChipFailureKind.accessDenied)!.recovery, IdentityRecovery.rescanMrz);
  });

  test('server errors: only the daily limit is final', () {
    expect(describeApiFailure('daily_limit_reached').recovery, IdentityRecovery.close);
    expect(describeApiFailure('Pas de connexion').recovery, IdentityRecovery.retryFace);
  });

  test('manual review link points at the /verify page of the API host', () {
    expect(identityManualReviewUri.path, '/verify');
  });
}
