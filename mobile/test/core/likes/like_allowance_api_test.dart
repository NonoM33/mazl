import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/likes/like_allowance.dart';
import 'package:mazl/core/likes/like_allowance_api.dart';
import 'package:mazl/core/services/api_service.dart';

// Les réponses ci-dessous viennent de
// src/features/like-allowance/presentation/like-allowance.routes.ts et de
// domain/allowance.ts (daily_allowance / remaining nuls = illimité), pas du
// parseur Dart.

HttpLikeAllowanceApi _api(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'jwt-exemple',
}) => HttpLikeAllowanceApi(
  baseUrl: 'https://api.example.com',
  token: () => token,
  clientFactory: () => MockClient(handler),
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Future<LikeAllowanceErrorKind> _failureOf(LikeAllowanceApi api) async {
  try {
    await api.getAllowance();
  } on LikeAllowanceException catch (error) {
    return error.kind;
  }
  fail('the call should have failed');
}

void main() {
  group('GET /api/likes/allowance', () {
    test('appelle la bonne route avec le jeton du membre', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json({
          'success': true,
          'allowance': {
            'daily_allowance': 10,
            'remaining': 7,
            'resets_at': '2026-10-26T00:00:00.000Z',
          },
        });
      });

      await api.getAllowance();

      expect(seen.method, 'GET');
      expect(seen.url.toString(), 'https://api.example.com/api/likes/allowance');
      expect(seen.headers['Authorization'], 'Bearer jwt-exemple');
    });

    test('un membre gratuit : 10 par jour, 7 restants, remise à zéro', () async {
      final allowance = await _api(
        (request) async => _json({
          'success': true,
          'allowance': {
            'daily_allowance': 10,
            'remaining': 7,
            'resets_at': '2026-10-26T00:00:00.000Z',
          },
        }),
      ).getAllowance();

      expect(allowance.dailyAllowance, 10);
      expect(allowance.remaining, 7);
      expect(allowance.resetsAt, DateTime.utc(2026, 10, 26));
      expect(allowance.isUnlimited, isFalse);
      expect(allowance.isExhaustedAt(DateTime.utc(2026, 10, 25, 12)), isFalse);
    });

    test('un abonné mazl+ : null / null veut dire illimité', () async {
      final allowance = await _api(
        (request) async => _json({
          'success': true,
          'allowance': {
            'daily_allowance': null,
            'remaining': null,
            'resets_at': '2026-10-26T00:00:00.000Z',
          },
        }),
      ).getAllowance();

      expect(allowance.isUnlimited, isTrue);
      expect(allowance.dailyAllowance, isNull);
      expect(allowance.isExhaustedAt(DateTime.utc(2026, 10, 25, 12)), isFalse);
    });

    test('plus aucun like : épuisé jusqu\'à la remise à zéro seulement', () async {
      final allowance = await _api(
        (request) async => _json({
          'success': true,
          'allowance': {
            'daily_allowance': 10,
            'remaining': 0,
            'resets_at': '2026-10-26T00:00:00.000Z',
          },
        }),
      ).getAllowance();

      expect(allowance.isExhaustedAt(DateTime.utc(2026, 10, 25, 23, 59)), isTrue);
      // Le jour a tourné : ce que l'app sait est périmé, le serveur dira.
      expect(allowance.isExhaustedAt(DateTime.utc(2026, 10, 26, 0, 1)), isFalse);
    });
  });

  group('une erreur est typée, jamais un texte du serveur', () {
    test('401 : session expirée', () async {
      final api = _api((r) async => _json({'success': false, 'error': 'Unauthorized'}, 401));
      expect(await _failureOf(api), LikeAllowanceErrorKind.sessionExpired);
    });

    test('500 : serveur', () async {
      final api = _api((r) async => _json({'success': false, 'error': 'internal_error'}, 500));
      expect(await _failureOf(api), LikeAllowanceErrorKind.server);
    });

    test('corps qui n\'est pas celui du contrat : inconnu', () async {
      expect(
        await _failureOf(_api((r) async => _json({'success': true}))),
        LikeAllowanceErrorKind.unknown,
      );
      expect(
        await _failureOf(_api((r) async => http.Response('<html>', 200))),
        LikeAllowanceErrorKind.unknown,
      );
      expect(
        await _failureOf(
          _api(
            (r) async => _json({
              'success': true,
              'allowance': {'daily_allowance': 10, 'remaining': 3, 'resets_at': 'pas une date'},
            }),
          ),
        ),
        LikeAllowanceErrorKind.unknown,
      );
    });

    test('pas de réseau et délai dépassé', () async {
      expect(
        await _failureOf(_api((r) async => throw http.ClientException('down'))),
        LikeAllowanceErrorKind.network,
      );
      expect(
        await _failureOf(_api((r) async => throw TimeoutException('slow'))),
        LikeAllowanceErrorKind.timeout,
      );
    });
  });

  group('le 402 « likes_exhausted » d\'un like refusé par le serveur', () {
    // Corps de createLikeAllowanceGuard : { success:false, error:"likes_exhausted", allowance }.
    ApiResponse<Map<String, dynamic>> refused(Object body, {int status = 402}) =>
        ApiResponse.httpFailure(
          http.Response(jsonEncode(body), status),
          'Failed to send swipe',
        );

    test('est reconnu, avec le reste du jour que le serveur donne', () {
      final response = refused({
        'success': false,
        'error': 'likes_exhausted',
        'allowance': {
          'daily_allowance': 10,
          'remaining': 0,
          'resets_at': '2026-10-26T00:00:00.000Z',
        },
      });

      expect(response.isLikesExhausted, isTrue);
      expect(response.exhaustedAllowance?.dailyAllowance, 10);
      expect(response.exhaustedAllowance?.remaining, 0);
      expect(response.exhaustedAllowance?.resetsAt, DateTime.utc(2026, 10, 26));
    });

    test('sans allowance dans le corps, le refus reste un refus', () {
      final response = refused({'success': false, 'error': 'likes_exhausted'});

      expect(response.isLikesExhausted, isTrue);
      expect(response.exhaustedAllowance, isNull);
    });

    test('n\'est pas confondu avec un Super Like ou un Boost épuisé', () {
      expect(
        refused({'success': false, 'error': 'super_likes_exhausted'}).isLikesExhausted,
        isFalse,
      );
      expect(
        refused({'success': false, 'error': 'boosts_exhausted'}).isLikesExhausted,
        isFalse,
      );
      // Ni un autre statut portant le même code.
      expect(
        refused({'success': false, 'error': 'likes_exhausted'}, status: 500).isLikesExhausted,
        isFalse,
      );
      expect(
        refused({'success': false, 'error': 'likes_exhausted'}).isCreditsExhausted,
        isFalse,
      );
    });
  });
}
