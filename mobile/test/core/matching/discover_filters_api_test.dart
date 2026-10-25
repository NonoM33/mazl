import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/matching/discover_filters.dart';
import 'package:mazl/core/matching/discover_filters_api.dart';
import 'package:mazl/core/services/api_service.dart';

// The contract: docs/launch/V1-CONTRAT.md §2.

HttpDiscoverFiltersApi _api(MockClient client) => HttpDiscoverFiltersApi(
  clientFactory: () => client,
  baseUrl: 'https://api.example.com',
  tokenProvider: () => '<jwt>',
  requestTimeout: const Duration(seconds: 2),
);

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _filtersJson = {
  'denominations': ['Massorti'],
  'kashrutLevels': null,
  'shabbatObservances': ['Observant', 'Tres observant'],
  'onlyVerified': true,
  'onlyWithPhoto': false,
};

void main() {
  group('load', () {
    test('reads the criteria and the mazl+ state', () async {
      late http.Request seen;
      final api = _api(
        MockClient((request) async {
          seen = request;
          return _json(200, {
            'success': true,
            'filters': _filtersJson,
            'plus': true,
          });
        }),
      );

      final response = await api.load();

      expect(seen.method, 'GET');
      expect(
        seen.url.toString(),
        'https://api.example.com/api/discover/filters',
      );
      expect(seen.headers['Authorization'], 'Bearer <jwt>');
      expect(response.success, isTrue);
      expect(response.data!.plus, isTrue);
      expect(response.data!.filters.denominations, ['Massorti']);
      expect(response.data!.filters.kashrutLevels, isNull);
      expect(response.data!.filters.shabbatObservances, [
        'Observant',
        'Tres observant',
      ]);
      expect(response.data!.filters.onlyVerified, isTrue);
      expect(response.data!.filters.onlyWithPhoto, isFalse);
    });

    test(
      'an answer without the contract shape is a failure, not a crash',
      () async {
        final api = _api(
          MockClient((_) async => _json(200, {'success': true})),
        );
        final response = await api.load();
        expect(response.success, isFalse);
        expect(response.errorKind, ApiErrorKind.server);
      },
    );

    test('a refused call carries its status and stable code', () async {
      final api = _api(
        MockClient(
          (_) async => _json(401, {'success': false, 'error': 'unauthorized'}),
        ),
      );
      final response = await api.load();
      expect(response.success, isFalse);
      expect(response.statusCode, 401);
      expect(response.errorKind, ApiErrorKind.unauthorized);
    });

    test('a network failure is typed as such', () async {
      final api = _api(
        MockClient((_) async => throw const SocketException('down')),
      );
      expect((await api.load()).errorKind, ApiErrorKind.network);
    });
  });

  group('save', () {
    test('writes every criterion, null clearing the ones left out', () async {
      late http.Request seen;
      final api = _api(
        MockClient((request) async {
          seen = request;
          return _json(200, {'success': true, 'filters': _filtersJson});
        }),
      );

      final response = await api.save(
        const DiscoverFilters(
          denominations: ['Massorti'],
          shabbatObservances: ['Observant', 'Tres observant'],
          onlyVerified: true,
        ),
      );

      expect(seen.method, 'PUT');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {
        'denominations': ['Massorti'],
        'kashrutLevels': null,
        'shabbatObservances': ['Observant', 'Tres observant'],
        'onlyVerified': true,
        'onlyWithPhoto': false,
      });
      expect(response.success, isTrue);
      expect(response.data!.onlyVerified, isTrue);
    });

    test('402 plus_required', () async {
      final api = _api(
        MockClient(
          (_) async => _json(402, {'success': false, 'error': 'plus_required'}),
        ),
      );
      final response = await api.save(
        const DiscoverFilters(onlyVerified: true),
      );
      expect(response.success, isFalse);
      expect(response.statusCode, 402);
      expect(response.errorCode, DiscoverFiltersError.plusRequired);
    });

    test('409 religious_consent_required', () async {
      final api = _api(
        MockClient(
          (_) async => _json(409, {
            'success': false,
            'error': 'religious_consent_required',
          }),
        ),
      );
      final response = await api.save(
        const DiscoverFilters(denominations: ['Massorti']),
      );
      expect(response.statusCode, 409);
      expect(response.errorCode, DiscoverFiltersError.religiousConsentRequired);
    });

    test(
      '400 keeps the status and drops the free-text reason from the code',
      () async {
        final api = _api(
          MockClient(
            (_) async => _json(400, {
              'success': false,
              'error': 'denominations: Expected array',
            }),
          ),
        );
        final response = await api.save(DiscoverFilters.none);
        expect(response.statusCode, 400);
        expect(response.errorKind, ApiErrorKind.invalid);
        expect(response.errorCode, isNull);
      },
    );
  });

  group('DiscoverFilters', () {
    test('hasReligiousCriterion only looks at the three practice criteria', () {
      expect(DiscoverFilters.none.hasReligiousCriterion, isFalse);
      expect(
        const DiscoverFilters(
          onlyVerified: true,
          onlyWithPhoto: true,
        ).hasReligiousCriterion,
        isFalse,
      );
      expect(
        const DiscoverFilters(kashrutLevels: ['Strict']).hasReligiousCriterion,
        isTrue,
      );
    });

    test('the JSON round trip keeps every criterion', () {
      final filters = DiscoverFilters.fromJson(_filtersJson);
      expect(DiscoverFilters.fromJson(filters.toJson()), filters);
    });

    test('a wrongly typed criterion is refused', () {
      expect(
        () => DiscoverFilters.fromJson({'denominations': 'Massorti'}),
        throwsFormatException,
      );
      expect(
        () => DiscoverFilters.fromJson({'onlyVerified': 'yes'}),
        throwsFormatException,
      );
    });
  });
}
