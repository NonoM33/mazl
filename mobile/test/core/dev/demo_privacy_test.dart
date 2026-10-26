import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/privacy/analytics_consent.dart';
import 'package:mazl/core/privacy/religious_data_consent.dart';

/// The demo answers the privacy consents and the analytics relay like the
/// server (docs/analytics/plan-de-marquage.md), read back by the REAL
/// decoders of the app. Nothing leaves the device.

({int status, Map<String, dynamic> json}) _call(
  String method,
  String path, {
  Map<String, dynamic> body = const {},
}) {
  final reply = DemoRoutes.respond(DemoRequest(method, path, const {}, body));
  return (
    status: reply.status,
    json: jsonDecode(reply.json) as Map<String, dynamic>,
  );
}

Map<String, dynamic> _consents() =>
    _call('GET', '/api/privacy/consents').json['consents']
        as Map<String, dynamic>;

void main() {
  setUp(DemoStore.reset);

  test('a fresh session was never asked, for either purpose', () {
    final consents = _consents();
    final analytics = AnalyticsConsent.fromJson(
      consents['analytics'] as Map<String, dynamic>,
    );
    final religious = ReligiousDataConsent.fromJson(
      consents['religious_data'] as Map<String, dynamic>,
    );
    expect(analytics.granted, isNull);
    expect(religious.granted, isNull);
  });

  test('a decision is read back, under its own purpose only', () {
    final current = AnalyticsConsent.fromJson(
      _consents()['analytics'] as Map<String, dynamic>,
    ).currentVersion;
    final reply = _call(
      'PUT',
      '/api/privacy/consents/analytics',
      body: {'granted': true, 'version': current, 'source': 'app'},
    );
    expect(reply.status, 200);
    final consents = _consents();
    expect(
      AnalyticsConsent.fromJson(
        consents['analytics'] as Map<String, dynamic>,
      ).isValid,
      isTrue,
    );
    expect(
      ReligiousDataConsent.fromJson(
        consents['religious_data'] as Map<String, dynamic>,
      ).granted,
      isNull,
    );
  });

  test('an outdated version answers 409 like the server', () {
    final reply = _call(
      'PUT',
      '/api/privacy/consents/analytics',
      body: {'granted': true, 'version': '2000-01-01', 'source': 'app'},
    );
    expect(reply.status, 409);
    expect(reply.json['error'], 'consent_version_outdated');
  });

  test('the relay accepts the batch and keeps it on the device', () {
    final reply = _call(
      'POST',
      '/api/analytics/events',
      body: {
        'platform': 'ios',
        'app_version': '1.0.0',
        'events': [
          {'name': 'app_opened'},
        ],
      },
    );
    expect(reply.status, 202);
    expect(reply.json, {'success': true, 'accepted': 1});
  });
}
