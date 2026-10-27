import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import 'storefront_models.dart';

/// The raw answer of the server, for the part of the app that keeps it.
abstract interface class StorefrontRemote {
  /// The body of `GET /api/storefront` in the language [languageCode];
  /// `null` when the server cannot be reached or does not answer 200.
  Future<String?> fetch({required String languageCode});
}

/// Production adapter: no authentication, the storefront is public.
class HttpStorefrontRemote implements StorefrontRemote {
  HttpStorefrontRemote({
    http.Client? client,
    String baseUrl = Env.apiBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout;

  final http.Client? _client;
  final String _baseUrl;
  final Duration _timeout;

  @override
  Future<String?> fetch({required String languageCode}) async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/storefront'),
            headers: {'Accept-Language': languageCode},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('Storefront: HTTP ${response.statusCode}');
        return null;
      }
      return response.body;
    } on TimeoutException {
      debugPrint('Storefront: no answer in time');
      return null;
    } on http.ClientException catch (error) {
      debugPrint('Storefront: ${error.message}');
      return null;
    } finally {
      if (_client == null) client.close();
    }
  }
}

/// Where the last answer is kept between two launches.
abstract interface class StorefrontCache {
  Future<String?> read();
  Future<void> write(String body);
}

class SharedPreferencesStorefrontCache implements StorefrontCache {
  static const _key = 'storefront_last_response';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String body) async =>
      (await SharedPreferences.getInstance()).setString(_key, body);
}

/// Reads the storefront from the server and falls back on the last answer.
/// Without either, [Storefront.empty]: the app behaves as it did before the
/// storefront existed.
class StorefrontRepository {
  StorefrontRepository({
    required StorefrontRemote remote,
    required StorefrontCache cache,
  }) : _remote = remote,
       _cache = cache;

  final StorefrontRemote _remote;
  final StorefrontCache _cache;

  /// The last answer kept on the phone, or null.
  Future<Storefront?> cached() async {
    try {
      final body = await _cache.read();
      return body == null ? null : Storefront.tryParseBody(body);
    } on Exception catch (error) {
      debugPrint('Storefront: cache unreadable ($error)');
      return null;
    }
  }

  /// Asks the server; null when it did not give a usable answer (the caller
  /// keeps what it has). Only an answer that decodes is kept.
  Future<Storefront?> fetch({required String languageCode}) async {
    final String? body;
    try {
      body = await _remote.fetch(languageCode: languageCode);
    } on Exception catch (error) {
      debugPrint('Storefront: request failed ($error)');
      return null;
    }
    if (body == null) return null;
    final parsed = Storefront.tryParseBody(body);
    if (parsed == null) {
      debugPrint('Storefront: answer is not the documented envelope');
      return null;
    }
    try {
      await _cache.write(body);
    } on Exception catch (error) {
      debugPrint('Storefront: cache not written ($error)');
    }
    return parsed;
  }
}
