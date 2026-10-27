import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/di/providers/storefront_providers.dart';
import 'package:mazl/core/storefront/app_icon_gateway.dart';
import 'package:mazl/core/storefront/festive_icon.dart';
import 'package:mazl/core/storefront/storefront_repository.dart';
import 'package:mazl/presentation/features/storefront/widgets/storefront_host.dart';

// The storefront and the dev sign-in. The app reads the storefront at launch,
// before anyone signs in: the server answers without a campaign. Signing in
// with « Connexion fictive (dev) » must read it again, from the demo routes,
// so mazl+ shows the demo Valentine's campaign; signing out goes back to the
// server's answer.

const _serverBody =
    '{"success":true,"data":{"serverTime":"2026-10-27T09:00:00Z",'
    '"products":[],"campaign":null,"appIcon":null,"nextChangeAt":null}}';

/// The server, or the demo routes while a demo session runs: what the real
/// `HttpStorefrontRemote` gets once `DemoHttpClient` sits in front of it.
class _Remote implements StorefrontRemote {
  int calls = 0;

  @override
  Future<String?> fetch({required String languageCode}) async {
    calls++;
    if (!DevSession.isActive) return _serverBody;
    return DemoRoutes.respond(
      const DemoRequest('GET', '/api/storefront', {}, {}),
    ).json;
  }
}

class _Cache implements StorefrontCache {
  String? stored;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> write(String body) async => stored = body;
}

class _NoIcon implements AppIconGateway {
  @override
  Future<bool> supportsAlternateIcons() async => false;

  @override
  Future<String?> currentIcon() async => null;

  @override
  Future<void> setIcon(String? name) async {}
}

class _Setting implements FestiveIconSettingStore {
  @override
  Future<bool> read() async => true;

  @override
  Future<void> write(bool enabled) async {}
}

void main() {
  late _Remote remote;
  late _Cache cache;

  setUp(() {
    remote = _Remote();
    cache = _Cache();
  });

  tearDown(DevSession.stop);

  Future<ProviderContainer> pumpHost(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        storefrontRepositoryProvider.overrideWithValue(
          StorefrontRepository(remote: remote, cache: cache),
        ),
        appIconGatewayProvider.overrideWithValue(_NoIcon()),
        festiveIconSettingStoreProvider.overrideWithValue(_Setting()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StorefrontHost(child: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Ends the demo session: the server's answer comes back and the timer of
  /// the demo campaign's end goes with it.
  Future<void> signOut(WidgetTester tester) async {
    DevSession.stop();
    await tester.pumpAndSettle();
  }

  testWidgets('a demo session shows the demo Valentine\'s campaign', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    expect(container.read(storefrontProvider).campaign, isNull);

    DevSession.start();
    await tester.pumpAndSettle();

    final campaign = container.read(storefrontProvider).campaign;
    expect(campaign, isNotNull, reason: 'read again when the session starts');
    expect(campaign!.theme.id, 'valentine');
    expect(container.read(storefrontProvider).appIcon, 'AppIcon-valentine');

    await signOut(tester);
  });

  testWidgets('signing out of the demo goes back to the server\'s answer', (
    tester,
  ) async {
    final container = await pumpHost(tester);
    DevSession.start();
    await tester.pumpAndSettle();
    expect(container.read(storefrontProvider).campaign, isNotNull);

    DevSession.stop();
    await tester.pumpAndSettle();
    expect(container.read(storefrontProvider).campaign, isNull);
  });

  testWidgets('the demo answer is never kept on the phone', (tester) async {
    await pumpHost(tester);
    expect(cache.stored, _serverBody);

    DevSession.start();
    await tester.pumpAndSettle();
    expect(remote.calls, 2);
    expect(
      cache.stored,
      _serverBody,
      reason: 'a real session must not start on the fictitious campaign',
    );
    expect(jsonDecode(cache.stored!), isA<Map<String, dynamic>>());

    await signOut(tester);
  });

  test('stopping a session that was not running notifies no one', () {
    var notified = 0;
    void listener() => notified++;
    DevSession.changes.addListener(listener);
    addTearDown(() => DevSession.changes.removeListener(listener));
    DevSession.stop();
    expect(notified, 0);
    DevSession.start();
    DevSession.stop();
    expect(notified, 2);
  });

  test('an earlier, slower answer does not replace a newer one', () async {
    final slow = Completer<String?>();
    final answers = <Future<String?> Function()>[
      () => slow.future,
      () async => DemoRoutes.respond(
        const DemoRequest('GET', '/api/storefront', {}, {}),
      ).json,
    ];
    final container = ProviderContainer(
      overrides: [
        storefrontRepositoryProvider.overrideWithValue(
          StorefrontRepository(remote: _Scripted(answers), cache: cache),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(storefrontControllerProvider.notifier);
    final launch = controller.start('fr');
    await Future<void>.delayed(Duration.zero);
    await controller.refresh(force: true);
    expect(container.read(storefrontProvider).campaign, isNotNull);

    slow.complete(_serverBody);
    await launch;
    expect(
      container.read(storefrontProvider).campaign,
      isNotNull,
      reason: 'the launch answer arrived last but was asked first',
    );
  });
}

class _Scripted implements StorefrontRemote {
  _Scripted(this.answers);

  final List<Future<String?> Function()> answers;

  @override
  Future<String?> fetch({required String languageCode}) =>
      answers.removeAt(0)();
}
