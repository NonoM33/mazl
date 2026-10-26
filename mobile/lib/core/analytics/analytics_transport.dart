import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_guard.dart';
import 'analytics_event.dart';

/// An event with the moment it happened, kept until it can be sent.
class QueuedEvent {
  const QueuedEvent(this.event, this.at);

  final AnalyticsEvent event;
  final DateTime at;
}

/// What became of a batch.
enum AnalyticsSendResult {
  /// The server took it.
  sent,

  /// Network, timeout, server error, signed out: keep the batch, try later.
  retry,

  /// The server refused the batch itself (4xx): sending it again is useless.
  rejected,
}

abstract class AnalyticsTransport {
  Future<AnalyticsSendResult> send(List<QueuedEvent> batch);
}

/// `POST /api/analytics/events`: the server filters, pseudonymises and relays
/// (docs/analytics/plan-de-marquage.md §1). Nothing of the content is logged.
class HttpAnalyticsTransport implements AnalyticsTransport {
  HttpAnalyticsTransport({
    required this.platform,
    required Future<String> Function() appVersion,
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? requestTimeout,
  }) : _client = SessionGuardClient(client),
       _appVersion = appVersion,
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _token = tokenProvider ?? (() => AuthService().currentUser?.jwtToken),
       _timeout = requestTimeout ?? ApiConfig.requestTimeout;

  static const path = '/api/analytics/events';

  /// `ios` or `android`.
  final String platform;

  /// `1.0.0+1`, read once.
  final Future<String> Function() _appVersion;

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _token;
  final Duration _timeout;

  @override
  Future<AnalyticsSendResult> send(List<QueuedEvent> batch) async {
    final token = _token();
    if (token == null) return AnalyticsSendResult.retry;
    try {
      final appVersion = await _appVersion();
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'platform': platform,
              'app_version': appVersion,
              'events': [
                for (final queued in batch)
                  {
                    'name': queued.event.name,
                    'properties': queued.event.properties,
                    'at': queued.at.toUtc().toIso8601String(),
                  },
              ],
            }),
          )
          .timeout(_timeout);
      return _resultOf(response.statusCode);
    } on TimeoutException {
      return AnalyticsSendResult.retry;
    } on SocketException {
      return AnalyticsSendResult.retry;
    } on http.ClientException {
      return AnalyticsSendResult.retry;
    } catch (e) {
      debugPrint('Analytics transport error: ${e.runtimeType}');
      return AnalyticsSendResult.retry;
    }
  }

  AnalyticsSendResult _resultOf(int status) {
    if (status >= 200 && status < 300) return AnalyticsSendResult.sent;
    // The session ended, a quota or a slow server: the batch stays. Any other
    // 4xx means the batch itself is refused.
    const keep = {401, 403, 408, 429};
    if (status >= 400 && status < 500 && !keep.contains(status)) {
      return AnalyticsSendResult.rejected;
    }
    return AnalyticsSendResult.retry;
  }
}
