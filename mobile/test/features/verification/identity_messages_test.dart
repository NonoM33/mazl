import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';
import 'package:mazl/presentation/features/verification/l10n/identity_failure_text.dart';

import 'verification_l10n.dart';

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
  final l10n = frenchL10n;
  final generic = describeIdentityRejection('something_new').messageText(l10n);

  test('every code of the contract has its own message', () {
    for (final code in _contractCodes) {
      final info = describeIdentityRejection(code);
      expect(info.messageText(l10n), isNot(generic), reason: code);
      expect(info.messageText(l10n), isNotEmpty);
      expect(info.actionLabel(l10n), isNotEmpty);
    }
  });

  test('messages are short single sentences', () {
    for (final code in [..._contractCodes, 'unknown']) {
      final message = describeIdentityRejection(code).messageText(l10n);
      expect(message.length, lessThan(90), reason: code);
      expect(message, endsWith('.'), reason: code);
      expect(message, isNot(contains('  ')), reason: code);
    }
  });

  test('fixed wording asked by the product', () {
    expect(describeIdentityRejection('csca_unknown').messageText(l10n), 'Document non reconnu.');
    expect(describeIdentityRejection('document_expired').messageText(l10n), 'Ce document est expiré.');
  });

  test('the buttons keep their French labels', () {
    expect(describeIdentityRejection('no_face').actionLabel(l10n), 'Réessayer');
    expect(describeIdentityRejection('csca_unknown').actionLabel(l10n), 'Fermer');
    expect(describeIdentityRejection('chip_data_invalid').actionLabel(l10n), 'Relire le document');
    expect(describeIdentityRejection('document_expired').actionLabel(l10n), 'Autre document');
    expect(describeChipFailure(ChipFailureKind.accessDenied)!.actionLabel(l10n), 'Scanner à nouveau');
  });

  test('every message and every button has a sentence in each of the five languages', () {
    for (final code in ['fr', 'en', 'he', 'es', 'ru']) {
      final strings = l10nFor(code);
      for (final message in IdentityMessage.values) {
        expect(message.text(strings).trim(), isNotEmpty, reason: '$code ${message.name}');
      }
      for (final action in IdentityAction.values) {
        expect(action.label(strings).trim(), isNotEmpty, reason: '$code ${action.name}');
      }
    }
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
        expect(info!.messageText(l10n), endsWith('.'));
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
