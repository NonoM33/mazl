import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_daily.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'couple_flow_fakes.dart';

/// The relationship status goes to the server first
/// (`PATCH /api/couple/:id/status`), and the subscription of the couple rides
/// along `GET /api/couple` (docs/couple/ESPACE-COUPLE.md §1).
void main() {
  late FakeCoupleApi api;
  late CoupleService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi()..couple = contractCouple();
    service = CoupleService.forTesting(api: api);
  });

  tearDown(() => service.dispose());

  group('updateStatus', () {
    test('PATCHes the server, then changes the status here', () async {
      await service.refresh();
      expect(service.coupleData?.status, RelationshipStatus.inRelationship);

      final result = await service.updateStatus(RelationshipStatus.engaged);

      expect(result.ok, isTrue);
      expect(api.calls, contains('status:12:engaged'));
      expect(service.coupleData?.status, RelationshipStatus.engaged);
      // The change survives a restart of the app.
      final restarted = CoupleService.forTesting(api: api);
      await restarted.initialize();
      expect(restarted.coupleData?.status, RelationshipStatus.engaged);
      restarted.dispose();
    });

    test('the server names the values with underscores', () async {
      await service.refresh();
      await service.updateStatus(RelationshipStatus.inRelationship);
      expect(api.statuses, ['in_relationship']);
    });

    test('a refusal changes nothing', () async {
      await service.refresh();
      api.statusError = 'Forbidden';

      final result = await service.updateStatus(RelationshipStatus.married);

      expect(result.ok, isFalse);
      expect(result.failure, CoupleActionFailure.server);
      expect(service.coupleData?.status, RelationshipStatus.inRelationship);
    });

    test('single is not a status of a couple: no call at all', () async {
      await service.refresh();

      final result = await service.updateStatus(RelationshipStatus.single);

      expect(result.ok, isFalse);
      expect(api.calls.where((c) => c.startsWith('status:')), isEmpty);
    });

    test('without a couple there is nothing to update', () async {
      api.couple = null;
      await service.refresh();

      final result = await service.updateStatus(RelationshipStatus.engaged);

      expect(result.failure, CoupleActionFailure.notInCouple);
      expect(api.calls.where((c) => c.startsWith('status:')), isEmpty);
    });
  });

  group('premium', () {
    test('is inactive until the server says otherwise', () async {
      await service.refresh();
      expect(service.premium.active, isFalse);
    });

    test('is read from GET /api/couple', () async {
      api.premium = {
        'active': true,
        'paidBy': 'me',
        'renewsAt': '2026-11-20T10:00:00.000Z',
      };
      var notified = 0;
      service.addListener(() => notified++);

      await service.refresh();

      expect(service.premium.active, isTrue);
      expect(service.premium.paidBy, CouplePayer.me);
      expect(service.premium.renewsAt, DateTime.utc(2026, 11, 20, 10));
      expect(notified, greaterThan(0));
    });

    test('follows the server when the subscription ends', () async {
      api.premium = {'active': true, 'paidBy': 'partner', 'renewsAt': null};
      await service.refresh();
      api.premium = {'active': false, 'paidBy': null, 'renewsAt': null};

      await service.refresh();

      expect(service.premium.active, isFalse);
    });

    test('a server without the field means not subscribed', () async {
      api.premium = {'active': true, 'paidBy': 'me', 'renewsAt': null};
      await service.refresh();
      api.premium = null;

      await service.refresh();

      expect(service.premium.active, isFalse);
    });

    test(
      'is kept for the next start, so a subscriber never sees the offer',
      () async {
        api.premium = {'active': true, 'paidBy': 'partner', 'renewsAt': null};
        await service.refresh();

        api.unreachable = true;
        final restarted = CoupleService.forTesting(api: api);
        await restarted.initialize();

        expect(restarted.premium.active, isTrue);
        restarted.dispose();
      },
    );

    test('is forgotten on sign-out', () async {
      api.premium = {'active': true, 'paidBy': 'me', 'renewsAt': null};
      await service.refresh();

      await service.reset();

      expect(service.premium.active, isFalse);
      final restarted = CoupleService.forTesting(api: api..unreachable = true);
      await restarted.initialize();
      expect(restarted.premium.active, isFalse);
      restarted.dispose();
    });

    test('is forgotten when the couple ends', () async {
      api.premium = {'active': true, 'paidBy': 'me', 'renewsAt': null};
      await service.refresh();

      await service.leaveCouple();

      expect(service.premium.active, isFalse);
    });
  });
}
