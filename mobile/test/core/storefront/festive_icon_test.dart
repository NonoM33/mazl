import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/storefront/app_icon_gateway.dart';
import 'package:mazl/core/storefront/festive_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The holiday icon: when it is put on the home screen, when it is not, and
// that the native channel is spoken to with the names UIKit really has
// (UIApplication.supportsAlternateIcons, .alternateIconName,
// .setAlternateIconName(_:)). The fake channel answers ONLY those names: any
// other name is a MissingPluginException, as on a device.

class _FakeIconChannel {
  _FakeIconChannel();

  bool supported = true;
  String? current;
  PlatformException? refusal;
  final List<String> calls = [];
  final List<Object?> setArguments = [];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(MethodChannelAppIconGateway.channelName),
          (call) async {
            calls.add(call.method);
            switch (call.method) {
              case 'supportsAlternateIcons':
                return supported;
              case 'alternateIconName':
                return current;
              case 'setAlternateIconName':
                setArguments.add(call.arguments);
                if (refusal != null) throw refusal!;
                current = (call.arguments as Map)['name'] as String?;
                return null;
            }
            throw MissingPluginException('no ${call.method}');
          },
        );
  }

  List<String> get changes => [
    for (final call in setArguments) '${(call! as Map)['name']}',
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeIconChannel channel;
  late FestiveIconApplier applier;

  setUp(() {
    channel = _FakeIconChannel()..install();
    applier = FestiveIconApplier(const MethodChannelAppIconGateway());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(MethodChannelAppIconGateway.channelName),
          null,
        );
  });

  Future<bool> apply(
    String? requested, {
    bool enabled = true,
    bool foreground = true,
    bool userInitiated = false,
  }) => applier.apply(
    requested: requested,
    enabled: enabled,
    foreground: foreground,
    userInitiated: userInitiated,
  );

  test('puts the icon of the campaign on the home screen', () async {
    expect(await apply('AppIcon-valentine'), isTrue);
    expect(channel.changes, ['AppIcon-valentine']);
    expect(channel.current, 'AppIcon-valentine');
  });

  test('the channel is spoken to with the names UIKit has', () async {
    await apply('AppIcon-valentine');
    expect(channel.calls.toSet(), {
      'supportsAlternateIcons',
      'alternateIconName',
      'setAlternateIconName',
    });
    expect(channel.setArguments.single, {'name': 'AppIcon-valentine'});
  });

  test('null brings the normal icon back', () async {
    channel.current = 'AppIcon-valentine';
    expect(await apply(null), isTrue);
    expect(channel.setArguments.single, {'name': null});
    expect(channel.current, isNull);
  });

  test('the icon already in use is not set again', () async {
    channel.current = 'AppIcon-valentine';
    expect(await apply('AppIcon-valentine'), isFalse);
    expect(channel.setArguments, isEmpty);
  });

  test('no change when the normal icon is asked and in use', () async {
    expect(await apply(null), isFalse);
    expect(channel.setArguments, isEmpty);
  });

  test('never in the background', () async {
    expect(await apply('AppIcon-valentine', foreground: false), isFalse);
    expect(channel.calls, isEmpty);
    expect(await apply('AppIcon-valentine'), isTrue, reason: 'back in front');
  });

  test('at most one change per launch', () async {
    expect(await apply('AppIcon-valentine'), isTrue);
    expect(await apply('AppIcon-christmas'), isFalse);
    expect(await apply(null), isFalse);
    expect(channel.changes, ['AppIcon-valentine']);
  });

  test('with the setting off, the server is not obeyed', () async {
    expect(await apply('AppIcon-valentine', enabled: false), isFalse);
    expect(channel.setArguments, isEmpty);
  });

  test('turning the setting off puts the normal icon back at once', () async {
    expect(await apply('AppIcon-valentine'), isTrue);
    expect(
      await apply('AppIcon-valentine', enabled: false, userInitiated: true),
      isTrue,
    );
    expect(channel.current, isNull);
    expect(
      await apply('AppIcon-valentine', userInitiated: true),
      isTrue,
      reason: 'and turning it on again puts the holiday icon back',
    );
    expect(channel.current, 'AppIcon-valentine');
  });

  test('a device that cannot change its icon is left alone', () async {
    channel.supported = false;
    expect(await apply('AppIcon-valentine'), isFalse);
    expect(channel.setArguments, isEmpty);
  });

  test('without the native side (Android, tests) nothing happens', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(MethodChannelAppIconGateway.channelName),
          null,
        );
    expect(await apply('AppIcon-valentine'), isFalse);
  });

  test('a refusal of iOS is logged, never thrown, and not retried', () async {
    channel.refusal = PlatformException(
      code: 'icon_change_failed',
      message: 'The requested icon is not in the bundle',
    );
    expect(await apply('AppIcon-valentine'), isFalse);
    expect(channel.setArguments, hasLength(1));
    channel.refusal = null;
    expect(await apply('AppIcon-valentine'), isFalse);
    expect(
      channel.setArguments,
      hasLength(1),
      reason: 'not before the next launch',
    );
  });

  group('the setting', () {
    test('is on by default and survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesFestiveIconSettingStore();
      expect(await store.read(), isTrue);
      final controller = FestiveIconSettingController(store);
      await controller.set(false);
      expect(controller.state, isFalse);
      expect(await SharedPreferencesFestiveIconSettingStore().read(), isFalse);
      await controller.set(true);
      expect(await store.read(), isTrue);
    });
  });

  test('the native side answers the same three methods', () {
    // Dart spoke to the fake above with the UIKit names; the Swift file must
    // be listening to the same channel and the same names.
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('"mazl/app_icon"'));
    for (final method in [
      'supportsAlternateIcons',
      'alternateIconName',
      'setAlternateIconName',
    ]) {
      expect(swift, contains('case "$method"'));
    }
    expect(swift, contains('UIApplication.shared.setAlternateIconName(name)'));
    expect(swift, contains('AppIconPlugin.register(with: registrar)'));
  });
}
