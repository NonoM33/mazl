import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/premium/premium_settings_api.dart';

// The client of GET /api/premium/settings, PUT /api/discover/passport and
// PUT /api/profile/incognito, against the answers written in
// docs/premium/MONETISATION.md and the brief's HTTP contract.

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _ok(Object? data) => {'success': true, 'data': data};

Map<String, Object?> _refused(String code) => {'success': false, 'error': code};

HttpPremiumSettingsApi _api(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'jwt-1',
}) => HttpPremiumSettingsApi.withClient(
  baseUrl: 'https://api.test',
  token: () => token,
  clientFactory: () => MockClient(handler),
);

const _passport = {
  'city': 'Tel Aviv',
  'latitude': 32.0853,
  'longitude': 34.7818,
};

Future<PremiumSettingsErrorKind> _kindOf(Future<Object?> call) async {
  try {
    await call;
  } on PremiumSettingsException catch (error) {
    return error.kind;
  }
  fail('the call did not fail');
}

void main() {
  group('GET /api/premium/settings', () {
    test('reads a member with a passport', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(
          _ok({
            'is_plus': true,
            'passport': _passport,
            'incognito': true,
            'send_read_receipts': false,
          }),
        );
      });

      final settings = await api.getSettings();

      expect(seen.method, 'GET');
      expect(seen.url.toString(), 'https://api.test/api/premium/settings');
      expect(seen.headers['Authorization'], 'Bearer jwt-1');
      expect(settings.isPlus, isTrue);
      expect(settings.passport?.city, 'Tel Aviv');
      expect(settings.passport?.latitude, 32.0853);
      expect(settings.passport?.longitude, 34.7818);
      expect(settings.incognito, isTrue);
      expect(settings.sendReadReceipts, isFalse);
    });

    test('reads a free member with no passport', () async {
      final api = _api(
        (request) async => _json(
          _ok({
            'is_plus': false,
            'passport': null,
            'incognito': false,
            'send_read_receipts': true,
          }),
        ),
      );

      final settings = await api.getSettings();

      expect(settings.isPlus, isFalse);
      expect(settings.passport, isNull);
      expect(settings.incognito, isFalse);
      expect(settings.sendReadReceipts, isTrue);
    });

    test('an integer coordinate is read as a double', () async {
      final api = _api(
        (request) async => _json(
          _ok({
            'is_plus': true,
            'passport': {'city': 'Paris', 'latitude': 48, 'longitude': 2},
            'incognito': false,
            'send_read_receipts': true,
          }),
        ),
      );
      final settings = await api.getSettings();
      expect(settings.passport?.latitude, 48.0);
    });

    test(
      'a field missing from the answer is an error, never « off »',
      () async {
        final api = _api(
          (request) async => _json(_ok({'is_plus': true, 'passport': null})),
        );
        expect(
          await _kindOf(api.getSettings()),
          PremiumSettingsErrorKind.unknown,
        );
      },
    );

    test('a passport that is present but unreadable is an error', () async {
      final api = _api(
        (request) async => _json(
          _ok({
            'is_plus': true,
            'passport': {'city': 'Paris'},
            'incognito': false,
            'send_read_receipts': true,
          }),
        ),
      );
      expect(
        await _kindOf(api.getSettings()),
        PremiumSettingsErrorKind.unknown,
      );
    });

    test('401 is an expired session', () async {
      final api = _api((request) async => _json(_refused('unauthorized'), 401));
      expect(
        await _kindOf(api.getSettings()),
        PremiumSettingsErrorKind.sessionExpired,
      );
    });

    test('a 500 is a server error', () async {
      final api = _api((request) async => _json(_refused('boom'), 500));
      expect(await _kindOf(api.getSettings()), PremiumSettingsErrorKind.server);
    });

    test('a body that is not JSON is unknown', () async {
      final api = _api((request) async => http.Response('<html>', 200));
      expect(
        await _kindOf(api.getSettings()),
        PremiumSettingsErrorKind.unknown,
      );
    });

    test('no connection is a network error', () async {
      final api = _api((request) async => throw const SocketException('down'));
      expect(
        await _kindOf(api.getSettings()),
        PremiumSettingsErrorKind.network,
      );
    });

    test('a client exception is a network error', () async {
      final api = _api((request) async => throw http.ClientException('down'));
      expect(
        await _kindOf(api.getSettings()),
        PremiumSettingsErrorKind.network,
      );
    });
  });

  group('PUT /api/discover/passport', () {
    test('turns the passport on with the three fields', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(_ok({'passport': _passport}));
      });

      final held = await api.setPassport(
        const Passport(city: 'Tel Aviv', latitude: 32.0853, longitude: 34.7818),
      );

      expect(seen.method, 'PUT');
      expect(seen.url.path, '/api/discover/passport');
      expect(jsonDecode(seen.body), _passport);
      expect(held?.city, 'Tel Aviv');
    });

    test('turns it off with a JSON null body', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(_ok({'passport': null}));
      });

      final held = await api.setPassport(null);

      expect(seen.body, 'null');
      expect(seen.headers['Content-Type'], contains('application/json'));
      expect(held, isNull);
    });

    test('402 mazl_plus_required is the plus-required error', () async {
      final api = _api(
        (request) async => _json(_refused('mazl_plus_required'), 402),
      );
      expect(
        await _kindOf(
          api.setPassport(
            const Passport(city: 'Paris', latitude: 48.85, longitude: 2.35),
          ),
        ),
        PremiumSettingsErrorKind.plusRequired,
      );
    });

    test('a 402 with another code is not read as plus-required', () async {
      final api = _api((request) async => _json(_refused('other'), 402));
      expect(
        await _kindOf(api.setPassport(null)),
        PremiumSettingsErrorKind.unknown,
      );
    });

    test('400 invalid_body is an invalid request', () async {
      final api = _api((request) async => _json(_refused('invalid_body'), 400));
      expect(
        await _kindOf(api.setPassport(null)),
        PremiumSettingsErrorKind.invalidRequest,
      );
    });

    test('an answer without the passport key is an error', () async {
      final api = _api((request) async => _json(_ok(<String, Object?>{})));
      expect(
        await _kindOf(api.setPassport(null)),
        PremiumSettingsErrorKind.unknown,
      );
    });

    test('no answer within 15 seconds is a timeout', () {
      fakeAsync((async) {
        final api = _api((request) => Completer<http.Response>().future);
        PremiumSettingsErrorKind? kind;
        _kindOf(api.setPassport(null)).then((value) => kind = value);
        async.elapse(const Duration(seconds: 16));
        expect(kind, PremiumSettingsErrorKind.timeout);
      });
    });
  });

  group('PUT /api/profile/incognito', () {
    test('sends enabled and returns what the server holds', () async {
      late http.Request seen;
      final api = _api((request) async {
        seen = request;
        return _json(_ok({'incognito': true}));
      });

      expect(await api.setIncognito(true), isTrue);
      expect(seen.method, 'PUT');
      expect(seen.url.path, '/api/profile/incognito');
      expect(jsonDecode(seen.body), {'enabled': true});
    });

    test('402 mazl_plus_required when turning it on without mazl+', () async {
      final api = _api(
        (request) async => _json(_refused('mazl_plus_required'), 402),
      );
      expect(
        await _kindOf(api.setIncognito(true)),
        PremiumSettingsErrorKind.plusRequired,
      );
    });

    test('the server answer wins over the request', () async {
      final api = _api((request) async => _json(_ok({'incognito': false})));
      expect(await api.setIncognito(true), isFalse);
    });

    test('an answer without a boolean is an error', () async {
      final api = _api((request) async => _json(_ok({'incognito': 'yes'})));
      expect(
        await _kindOf(api.setIncognito(true)),
        PremiumSettingsErrorKind.unknown,
      );
    });
  });

  test('the server error text is never carried by the exception', () async {
    final api = _api(
      (request) async => _json(_refused('SECRET internal detail'), 500),
    );
    try {
      await api.getSettings();
      fail('should throw');
    } on PremiumSettingsException catch (error) {
      expect(error.toString(), isNot(contains('SECRET')));
    }
  });
}
