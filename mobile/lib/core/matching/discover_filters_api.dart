import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'discover_filters.dart';

/// Codes d'erreur stables du serveur, portés par [ApiResponse.errorCode].
abstract class DiscoverFiltersError {
  /// 402 : un critère avancé demande mazl+.
  static const plusRequired = 'plus_required';

  /// 409 : un critère religieux demande le consentement de l'article 9.
  static const religiousConsentRequired = 'religious_consent_required';
}

/// Les filtres avancés de Découvrir. [HttpDiscoverFiltersApi] est la vraie
/// implémentation ; les tests en donnent une fausse.
abstract class DiscoverFiltersApi {
  /// `GET /api/discover/filters`.
  Future<ApiResponse<DiscoverFiltersState>> load();

  /// `PUT /api/discover/filters` : écrit [filters] en entier (un critère à
  /// `null` est effacé) et rend ce que le serveur a gardé.
  Future<ApiResponse<DiscoverFilters>> save(DiscoverFilters filters);
}

class HttpDiscoverFiltersApi implements DiscoverFiltersApi {
  HttpDiscoverFiltersApi({
    http.Client Function()? clientFactory,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? requestTimeout,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _token = tokenProvider ?? (() => AuthService().currentUser?.jwtToken),
       _timeout = requestTimeout ?? ApiConfig.requestTimeout;

  static const _path = '/api/discover/filters';

  /// Un client par appel, comme `http.get` : en démonstration, celui que
  /// `runWithClient` installe est celui qui répond.
  final http.Client Function() _clientFactory;
  final String _baseUrl;
  final String? Function() _token;
  final Duration _timeout;

  Uri get _uri => Uri.parse('$_baseUrl$_path');

  Map<String, String> get _headers {
    final token = _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ApiResponse<DiscoverFiltersState>> load() => _guard(() async {
    final response = await _withClient(
      (client) => client.get(_uri, headers: _headers),
    );
    final failure = _failureOf<DiscoverFiltersState>(response);
    if (failure != null) return failure;
    return ApiResponse.success(DiscoverFiltersState.fromJson(_json(response)));
  });

  @override
  Future<ApiResponse<DiscoverFilters>> save(DiscoverFilters filters) =>
      _guard(() async {
        final response = await _withClient(
          (client) =>
              client.put(_uri, headers: _headers, body: jsonEncode(filters)),
        );
        final failure = _failureOf<DiscoverFilters>(response);
        if (failure != null) return failure;
        final saved = _json(response)['filters'];
        if (saved is! Map<String, dynamic>) {
          throw const FormatException('filters');
        }
        return ApiResponse.success(DiscoverFilters.fromJson(saved));
      });

  Future<http.Response> _withClient(
    Future<http.Response> Function(http.Client client) send,
  ) async {
    final client = _clientFactory();
    try {
      return await send(client).timeout(_timeout);
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _json(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('unexpected response body');
    }
    return decoded;
  }

  ApiResponse<T>? _failureOf<T>(http.Response response) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) return ApiResponse.httpFailure(response, 'Discover filters');
    final body = _json(response);
    if (body['success'] == false) {
      return ApiResponse.failure('Discover filters', ApiErrorKind.server);
    }
    return null;
  }

  Future<ApiResponse<T>> _guard<T>(
    Future<ApiResponse<T>> Function() action,
  ) async {
    try {
      return await action();
    } on TimeoutException {
      return ApiResponse.failure('timeout', ApiErrorKind.timeout);
    } on SocketException {
      return ApiResponse.failure('network', ApiErrorKind.network);
    } on http.ClientException {
      return ApiResponse.failure('network', ApiErrorKind.network);
    } on FormatException {
      return ApiResponse.failure('invalid_response', ApiErrorKind.server);
    } catch (e) {
      debugPrint('Discover filters API error: ${e.runtimeType}');
      return ApiResponse.failure('unknown_error', ApiErrorKind.unknown);
    }
  }
}
