import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mazl/core/services/api_service.dart';

http.Response _response(int status, [Object? body]) =>
    http.Response(body == null ? '' : jsonEncode(body), status);

/// Une erreur HTTP dit à l'écran QUOI s'est passé (un type, un code stable),
/// jamais une phrase : c'est l'écran qui l'écrit dans la langue du membre.
void main() {
  group('ApiResponse.httpFailure classe le statut', () {
    final cases = {
      400: ApiErrorKind.invalid,
      401: ApiErrorKind.unauthorized,
      403: ApiErrorKind.forbidden,
      404: ApiErrorKind.notFound,
      409: ApiErrorKind.conflict,
      413: ApiErrorKind.tooLarge,
      422: ApiErrorKind.invalid,
      429: ApiErrorKind.rateLimited,
      500: ApiErrorKind.server,
      503: ApiErrorKind.server,
      418: ApiErrorKind.unknown,
    };
    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value.name}', () {
        final failure = ApiResponse<void>.httpFailure(
          _response(entry.key),
          'Failed to get matches',
        );
        expect(failure.success, isFalse);
        expect(failure.errorKind, entry.value);
        expect(failure.statusCode, entry.key);
      });
    }
  });

  group('le code stable du serveur est gardé', () {
    test('un code snake_case dans « error »', () {
      final failure = ApiResponse<void>.httpFailure(
        _response(403, {'success': false, 'error': 'not_matched'}),
        'Failed to send couple request',
      );
      expect(failure.errorCode, 'not_matched');
    });

    test('un code dans « reason » passe avant une phrase dans « error »', () {
      final failure = ApiResponse<void>.httpFailure(
        _response(400, {
          'success': false,
          'error': 'Invalid image',
          'reason': 'too_large',
        }),
        'Failed to upload photo',
      );
      expect(failure.errorCode, 'too_large');
    });

    test('un champ « code » explicite passe avant tout', () {
      final failure = ApiResponse<void>.httpFailure(
        _response(409, {
          'success': false,
          'error': 'too_late',
          'code': 'unsend_window_closed',
        }),
        'Failed to unsend',
      );
      expect(failure.errorCode, 'unsend_window_closed');
    });

    test('une phrase n\'est pas un code', () {
      final failure = ApiResponse<void>.httpFailure(
        _response(400, {'success': false, 'error': 'Event is full'}),
        'Failed to RSVP',
      );
      expect(failure.errorCode, isNull);
    });

    test('un corps illisible ne fait pas planter', () {
      final failure = ApiResponse<void>.httpFailure(
        http.Response('<html>502</html>', 502),
        'Failed to get profiles',
      );
      expect(failure.errorKind, ApiErrorKind.server);
      expect(failure.errorCode, isNull);
    });
  });

  test(
    'le texte gardé est un diagnostic pour le journal, pas pour l\'écran',
    () {
      final failure = ApiResponse<void>.httpFailure(
        _response(500),
        'Failed to get matches',
      );
      expect(failure.error, 'Failed to get matches (HTTP 500)');
    },
  );
}
