import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../session_guard.dart';

/// Réponse HTTP du backend : le code compte (409 et 422 n'ont pas le même
/// sens), le corps est du JSON ou absent.
class ApiReply {
  const ApiReply(this.statusCode, [this.body]);

  final int statusCode;
  final Map<String, Object?>? body;

  bool get isOk => statusCode == 200;
}

/// Les deux appels dont l'abonnement a besoin. Un port, pour que les tests
/// fournissent les formes JSON du backend sans réseau.
abstract interface class SubscriptionApi {
  Future<ApiReply> get(String path);

  Future<ApiReply> post(String path, Map<String, Object?> body);
}

/// Adaptateur de production : même base d'URL et même jeton Bearer que le reste
/// de l'application.
class HttpSubscriptionApi implements SubscriptionApi {
  HttpSubscriptionApi({
    required String? Function() tokenProvider,
    String baseUrl = Env.apiBaseUrl,
    Duration timeout = const Duration(seconds: 20),
  }) : _tokenProvider = tokenProvider,
       _baseUrl = baseUrl,
       _timeout = timeout;

  final String? Function() _tokenProvider;
  final String _baseUrl;
  final Duration _timeout;

  Map<String, String> get _headers {
    final token = _tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ApiReply> get(String path) async {
    final client = SessionGuardClient();
    try {
      final response = await client
          .get(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      return _reply(response);
    } finally {
      client.close();
    }
  }

  @override
  Future<ApiReply> post(String path, Map<String, Object?> body) async {
    final client = SessionGuardClient();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _reply(response);
    } finally {
      client.close();
    }
  }

  ApiReply _reply(http.Response response) {
    Map<String, Object?>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, Object?>) body = decoded;
    } on FormatException catch (error) {
      // Corps non JSON (page d'erreur d'un proxy, par exemple) : le code HTTP
      // suffit à décider, on garde la trace sans le contenu.
      debugPrint('Subscription API: corps illisible (${error.message})');
    }
    return ApiReply(response.statusCode, body);
  }
}
