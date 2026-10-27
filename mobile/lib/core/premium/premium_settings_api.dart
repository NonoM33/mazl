import 'package:http/http.dart' as http;

import 'premium_settings.dart';
import 'premium_transport.dart';

// Typed HTTP client for the mazl+ settings: `GET /api/premium/settings`,
// `PUT /api/discover/passport`, `PUT /api/profile/incognito`. Failures are
// typed here and the screen words them; the server's own error text is never
// shown, nor logged.

/// Why a settings call failed.
enum PremiumSettingsErrorKind {
  sessionExpired,

  /// HTTP 402 `mazl_plus_required`: the feature is for mazl+ members.
  plusRequired,

  /// HTTP 400: the server refused the body.
  invalidRequest,
  server,
  timeout,
  network,
  unknown,
}

class PremiumSettingsException implements Exception {
  const PremiumSettingsException(this.kind, {this.status});

  final PremiumSettingsErrorKind kind;

  /// HTTP status, null for network failures.
  final int? status;

  @override
  String toString() => '$runtimeType:${kind.name}:${status ?? 0}';
}

abstract interface class PremiumSettingsApi {
  /// The member's mazl+ settings, as the server holds them.
  Future<PremiumSettings> getSettings();

  /// Turns the passport on for [passport], or off with null (always allowed).
  /// Returns the passport the server now holds.
  Future<Passport?> setPassport(Passport? passport);

  /// Turns the discreet mode on or off. Returns what the server now holds.
  Future<bool> setIncognito(bool enabled);
}

class HttpPremiumSettingsApi implements PremiumSettingsApi {
  HttpPremiumSettingsApi({PremiumTransport? transport})
    : _transport = transport ?? PremiumTransport.app();

  /// For tests: the client the requests go through.
  HttpPremiumSettingsApi.withClient({
    required String baseUrl,
    required String? Function() token,
    required http.Client Function() clientFactory,
  }) : _transport = PremiumTransport(
         baseUrl: baseUrl,
         token: token,
         clientFactory: clientFactory,
       );

  final PremiumTransport _transport;

  @override
  Future<PremiumSettings> getSettings() async {
    final reply = await _send('GET', '/api/premium/settings');
    final settings = PremiumSettings.tryParse(reply.data);
    if (settings == null) throw _unknown(reply);
    return settings;
  }

  @override
  Future<Passport?> setPassport(Passport? passport) async {
    final reply = await _send(
      'PUT',
      '/api/discover/passport',
      // JSON `null` turns the passport off.
      body: passport?.toJson(),
    );
    final data = reply.data;
    if (data is! Map<String, dynamic> || !data.containsKey('passport')) {
      throw _unknown(reply);
    }
    final held = data['passport'];
    final parsed = Passport.tryParse(held);
    if (held != null && parsed == null) throw _unknown(reply);
    return parsed;
  }

  @override
  Future<bool> setIncognito(bool enabled) async {
    final reply = await _send(
      'PUT',
      '/api/profile/incognito',
      body: {'enabled': enabled},
    );
    final data = reply.data;
    final held = data is Map<String, dynamic> ? data['incognito'] : null;
    if (held is! bool) throw _unknown(reply);
    return held;
  }

  PremiumSettingsException _unknown(TransportReply reply) =>
      PremiumSettingsException(
        PremiumSettingsErrorKind.unknown,
        status: reply.status,
      );

  /// Sends the request and returns the answer when it is a success; every
  /// other outcome is a typed [PremiumSettingsException].
  Future<TransportReply> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final TransportReply reply;
    try {
      reply = await _transport.send(
        method,
        path,
        body: body,
        sendBody: method != 'GET',
      );
    } on TransportFailure catch (failure) {
      throw PremiumSettingsException(switch (failure.kind) {
        TransportFailureKind.timeout => PremiumSettingsErrorKind.timeout,
        TransportFailureKind.network => PremiumSettingsErrorKind.network,
      });
    }
    final status = reply.status;
    final kind = switch (status) {
      401 => PremiumSettingsErrorKind.sessionExpired,
      402 when reply.errorCode == 'mazl_plus_required' =>
        PremiumSettingsErrorKind.plusRequired,
      400 => PremiumSettingsErrorKind.invalidRequest,
      >= 500 => PremiumSettingsErrorKind.server,
      _ when !reply.isSuccess => PremiumSettingsErrorKind.unknown,
      _ => null,
    };
    if (kind != null) throw PremiumSettingsException(kind, status: status);
    return reply;
  }
}
