import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/profile_completeness_service.dart';

void main() {
  group('ProfileCompletenessService', () {
    test('is unknown at first and lets the member through', () {
      final service = ProfileCompletenessService.create(() async => null);
      expect(service.isKnown, isFalse);
      expect(service.needsSetup, isFalse);
    });

    test('refresh stores what the backend says is missing', () async {
      final service = ProfileCompletenessService.create(
        () async => ['gender', 'looking_for'],
      );
      await service.refresh();
      expect(service.isKnown, isTrue);
      expect(service.needsSetup, isTrue);
      expect(service.missing, ['gender', 'looking_for']);
    });

    test('an empty list means the profile is complete', () async {
      final service = ProfileCompletenessService.create(() async => <String>[]);
      await service.refresh();
      expect(service.isKnown, isTrue);
      expect(service.needsSetup, isFalse);
    });

    test('a failed read keeps the previous answer', () async {
      var calls = 0;
      final service = ProfileCompletenessService.create(() async {
        calls++;
        if (calls == 1) return ['looking_for'];
        throw StateError('offline');
      });
      await service.refresh();
      await service.refresh();
      expect(service.needsSetup, isTrue);

      final unreadable = ProfileCompletenessService.create(() async => null);
      await unreadable.refresh();
      expect(unreadable.isKnown, isFalse);
    });

    test('notifies the router only when the answer changes', () async {
      final service = ProfileCompletenessService.create(() async => ['gender']);
      var notifications = 0;
      service.addListener(() => notifications++);
      await service.refresh();
      await service.refresh();
      expect(notifications, 1);
      service.markComplete();
      expect(notifications, 2);
    });

    test('markIncomplete without detail still needs the setup', () {
      final service = ProfileCompletenessService.create(() async => null);
      service.markIncomplete(const []);
      expect(service.needsSetup, isTrue);
    });

    test('reset forgets the previous account', () async {
      final service = ProfileCompletenessService.create(() async => ['gender']);
      await service.refresh();
      service.reset();
      expect(service.isKnown, isFalse);
      expect(service.needsSetup, isFalse);
    });
  });

  group('ApiService, discovery feeds answering 409 profile_incomplete', () {
    http.Response incomplete() => http.Response(
          jsonEncode({
            'success': false,
            'error': 'profile_incomplete',
            'missing': ['looking_for'],
          }),
          409,
          headers: {'content-type': 'application/json'},
        );

    tearDown(() => ProfileCompletenessService().reset());

    test('getDiscoverProfiles fails with the profile_incomplete code and tells the service', () async {
      final response = await http.runWithClient(
        () => ApiService().getDiscoverProfiles(),
        () => MockClient((request) async {
          expect(request.url.path, '/api/discover');
          return incomplete();
        }),
      );
      expect(response.success, isFalse);
      expect(response.errorCode, 'profile_incomplete');
      expect(response.statusCode, 409);
      expect(ProfileCompletenessService().needsSetup, isTrue);
    });

    test('getDailyPicks is handled the same way', () async {
      final response = await http.runWithClient(
        () => ApiService().getDailyPicks(),
        () => MockClient((request) async => incomplete()),
      );
      expect(response.errorCode, 'profile_incomplete');
      expect(ProfileCompletenessService().needsSetup, isTrue);
    });

    test('another 409 body leaves the completeness alone', () async {
      final response = await http.runWithClient(
        () => ApiService().getDiscoverProfiles(),
        () => MockClient((request) async => http.Response('{"error":"conflict"}', 409)),
      );
      expect(response.errorCode, 'conflict');
      expect(ProfileCompletenessService().isKnown, isFalse);
    });

    test('a normal feed does not touch the completeness', () async {
      final response = await http.runWithClient(
        () => ApiService().getDiscoverProfiles(),
        () => MockClient((request) async => http.Response('{"success":true,"profiles":[]}', 200)),
      );
      expect(response.success, isTrue);
      expect(ProfileCompletenessService().isKnown, isFalse);
    });
  });

  group('ApiService.getMissingProfileFields', () {
    test('reads the missing list of /api/auth/me', () async {
      final response = await http.runWithClient(
        () => ApiService().getMissingProfileFields(),
        () => MockClient((request) async {
          expect(request.url.path, '/api/auth/me');
          return http.Response(
            jsonEncode({'success': true, 'user': {}, 'profile': null, 'missing': ['gender', 'looking_for']}),
            200,
          );
        }),
      );
      expect(response.success, isTrue);
      expect(response.data, ['gender', 'looking_for']);
    });

    test('a server that does not send missing leaves it unknown', () async {
      final response = await http.runWithClient(
        () => ApiService().getMissingProfileFields(),
        () => MockClient((request) async => http.Response('{"success":true,"user":{},"profile":{}}', 200)),
      );
      expect(response.success, isFalse);
    });
  });
}
