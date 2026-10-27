import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'premium_transport.dart';

// Typed client of the scheduled Boost (docs/premium/MONETISATION.md §8):
// `GET /api/boost/best-time`, `POST /api/boost/schedule { at }`,
// `DELETE /api/boost/schedule`. The server measures the busy hours, spends the
// Boost at the scheduled time and sends the push; the app only asks and shows.

/// The busiest hour of the member's city, as the server measured it.
@immutable
class BoostBestTime {
  const BoostBestTime({
    required this.startsAt,
    required this.weekday,
    required this.hour,
  });

  /// The next occurrence, in UTC.
  final DateTime startsAt;

  /// 1 (Monday) to 7 (Sunday), in UTC as the server counts it. The screen
  /// shows [startsAt] in the member's LOCAL time, never these two.
  final int weekday;
  final int hour;

  @override
  bool operator ==(Object other) =>
      other is BoostBestTime &&
      other.startsAt == startsAt &&
      other.weekday == weekday &&
      other.hour == hour;

  @override
  int get hashCode => Object.hash(startsAt, weekday, hour);
}

/// The `data` of `GET /api/boost/best-time`.
@immutable
class BoostScheduleInfo {
  const BoostScheduleInfo({
    required this.city,
    required this.bestTime,
    required this.scheduledAt,
  });

  final String? city;

  /// Null until the city has enough measured traffic.
  final BoostBestTime? bestTime;

  /// The Boost the member already scheduled, in UTC.
  final DateTime? scheduledAt;

  /// Null when [json] is malformed.
  static BoostScheduleInfo? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final city = json['city'];
    if (city != null && city is! String) return null;
    final rawBest = json['best_time'];
    BoostBestTime? best;
    if (rawBest != null) {
      if (rawBest is! Map<String, dynamic>) return null;
      final startsAt = _instant(rawBest['starts_at']);
      final weekday = rawBest['weekday'];
      final hour = rawBest['hour'];
      if (startsAt == null || weekday is! int || hour is! int) return null;
      best = BoostBestTime(startsAt: startsAt, weekday: weekday, hour: hour);
    }
    final rawScheduled = json['scheduled_at'];
    final scheduled = _instant(rawScheduled);
    if (rawScheduled != null && scheduled == null) return null;
    return BoostScheduleInfo(
      city: city as String?,
      bestTime: best,
      scheduledAt: scheduled,
    );
  }
}

DateTime? _instant(Object? raw) {
  if (raw is! String) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toUtc();
}

enum BoostScheduleErrorKind {
  /// 402 `boosts_exhausted`: no Boost left to spend; the packs sheet opens.
  boostsExhausted,

  /// 409 `already_scheduled`.
  alreadyScheduled,

  /// 400 `invalid_time`: in the past, or more than 7 days away.
  invalidTime,
  sessionExpired,
  server,
  timeout,
  network,
  unknown,
}

class BoostScheduleException implements Exception {
  const BoostScheduleException(this.kind, {this.status});

  final BoostScheduleErrorKind kind;
  final int? status;

  @override
  String toString() => '$runtimeType:${kind.name}:${status ?? 0}';
}

abstract interface class BoostScheduleApi {
  Future<BoostScheduleInfo> bestTime();

  /// Schedules a Boost at [at]; returns the time the server holds (UTC).
  Future<DateTime> schedule(DateTime at);

  Future<void> cancel();
}

class HttpBoostScheduleApi implements BoostScheduleApi {
  HttpBoostScheduleApi({PremiumTransport? transport})
    : _transport = transport ?? PremiumTransport.app();

  /// For tests: the client the requests go through.
  HttpBoostScheduleApi.withClient({
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
  Future<BoostScheduleInfo> bestTime() async {
    final reply = await _send('GET', '/api/boost/best-time');
    final info = BoostScheduleInfo.tryParse(reply.data);
    if (info == null) throw _unknown(reply);
    return info;
  }

  @override
  Future<DateTime> schedule(DateTime at) async {
    final reply = await _send(
      'POST',
      '/api/boost/schedule',
      body: {'at': at.toUtc().toIso8601String()},
      sendBody: true,
    );
    final data = reply.data;
    final held = data is Map<String, dynamic>
        ? _instant(data['scheduled_at'])
        : null;
    if (held == null) throw _unknown(reply);
    return held;
  }

  @override
  Future<void> cancel() async {
    final reply = await _send('DELETE', '/api/boost/schedule');
    final data = reply.data;
    if (data is! Map<String, dynamic> || data['scheduled_at'] != null) {
      throw _unknown(reply);
    }
  }

  BoostScheduleException _unknown(TransportReply reply) =>
      BoostScheduleException(
        BoostScheduleErrorKind.unknown,
        status: reply.status,
      );

  Future<TransportReply> _send(
    String method,
    String path, {
    Object? body,
    bool sendBody = false,
  }) async {
    final TransportReply reply;
    try {
      reply = await _transport.send(
        method,
        path,
        body: body,
        sendBody: sendBody,
      );
    } on TransportFailure catch (failure) {
      throw BoostScheduleException(switch (failure.kind) {
        TransportFailureKind.timeout => BoostScheduleErrorKind.timeout,
        TransportFailureKind.network => BoostScheduleErrorKind.network,
      });
    }
    final status = reply.status;
    final code = reply.errorCode;
    final kind = switch (status) {
      401 => BoostScheduleErrorKind.sessionExpired,
      400 when code == 'invalid_time' => BoostScheduleErrorKind.invalidTime,
      402 when code == 'boosts_exhausted' =>
        BoostScheduleErrorKind.boostsExhausted,
      409 when code == 'already_scheduled' =>
        BoostScheduleErrorKind.alreadyScheduled,
      >= 500 => BoostScheduleErrorKind.server,
      _ when !_succeeded(reply) => BoostScheduleErrorKind.unknown,
      _ => null,
    };
    if (kind != null) throw BoostScheduleException(kind, status: status);
    return reply;
  }

  /// The contract answers 201 to a schedule and 200 to the other calls.
  bool _succeeded(TransportReply reply) =>
      (reply.status == 200 || reply.status == 201) &&
      reply.body?['success'] == true;
}
