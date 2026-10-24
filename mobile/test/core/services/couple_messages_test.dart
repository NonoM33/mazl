import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_messages.dart';

ApiResponse<Object?> _failed({
  String? error,
  String? code,
  ApiErrorKind? kind,
}) => ApiResponse<Object?>(
  success: false,
  error: error,
  errorCode: code,
  errorKind: kind,
);

void main() {
  group('coupleFailureOf : la cause d\'un échec du mode couple', () {
    test('un code stable du serveur suffit (contrat §2)', () {
      expect(
        coupleFailureOf(
          _failed(code: 'not_matched', kind: ApiErrorKind.forbidden),
        ),
        CoupleActionFailure.notMatched,
      );
      expect(
        coupleFailureOf(
          _failed(code: 'already_in_couple', kind: ApiErrorKind.conflict),
        ),
        CoupleActionFailure.alreadyInCouple,
      );
    });

    test('le code passe avant la phrase anglaise', () {
      expect(
        coupleFailureOf(
          _failed(code: 'not_matched', error: 'already in a couple'),
        ),
        CoupleActionFailure.notMatched,
      );
    });

    test('faute de code, la phrase anglaise des anciennes routes est lue', () {
      expect(
        coupleFailureOf(
          _failed(error: 'One of the users is already in a couple'),
        ),
        CoupleActionFailure.alreadyInCouple,
      );
      expect(
        coupleFailureOf(
          _failed(error: 'A pending couple request already exists'),
        ),
        CoupleActionFailure.requestPending,
      );
      expect(
        coupleFailureOf(_failed(error: 'Couple request is no longer pending')),
        CoupleActionFailure.requestNoLongerPending,
      );
      expect(
        coupleFailureOf(_failed(error: 'Target user is unavailable')),
        CoupleActionFailure.unavailable,
      );
      expect(
        coupleFailureOf(
          _failed(error: 'You cannot send a request to yourself'),
        ),
        CoupleActionFailure.self,
      );
      expect(
        coupleFailureOf(_failed(error: 'Not in a couple')),
        CoupleActionFailure.notInCouple,
      );
    });

    test('le réseau et le délai passent avant tout texte', () {
      expect(
        coupleFailureOf(
          _failed(error: 'not_matched', kind: ApiErrorKind.timeout),
        ),
        CoupleActionFailure.timeout,
      );
      expect(
        coupleFailureOf(_failed(error: 'offline', kind: ApiErrorKind.network)),
        CoupleActionFailure.network,
      );
    });

    test(
      'sans rien de connu : 5xx = serveur, 404 = introuvable, le reste = inconnu',
      () {
        expect(
          coupleFailureOf(_failed(error: 'boom', kind: ApiErrorKind.server)),
          CoupleActionFailure.server,
        );
        expect(
          coupleFailureOf(
            _failed(
              error: 'Couple request not found',
              kind: ApiErrorKind.notFound,
            ),
          ),
          CoupleActionFailure.notFound,
        );
        expect(
          coupleFailureOf(_failed(error: 'boom')),
          CoupleActionFailure.unknown,
        );
        expect(coupleFailureOf(_failed()), CoupleActionFailure.unknown);
      },
    );
  });
}
