import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'push_device_server.dart';
import 'push_permission.dart';
import 'quiet_display.dart';

/// What the app needs from the push provider: Apple's push service (APNs)
/// behind it in the app, a fake in the tests.
abstract interface class PushGateway {
  /// Starts listening. [onClick] gets the data of every notification the
  /// member taps, including the one that launched the app. Does NOT ask for
  /// the permission (see [askPermission]).
  Future<void> start({
    required void Function(Map<String, dynamic> data) onClick,
  });

  /// The member is signed in: this phone's token is declared to the server.
  Future<void> login(int userId);

  /// The member signs out: this phone's token is removed from the server.
  Future<void> logout();

  /// Shows the system permission dialog if the member was never asked. Never
  /// sends to the Settings: a refusal is respected.
  Future<void> askPermission();
}

/// APNs through the `mazl/push` channel (`ios/Runner/ApnsPushPlugin.swift`) and
/// the MAZL server (`PUT` / `DELETE /api/push/devices`).
class ApnsPushGateway implements PushGateway {
  ApnsPushGateway({
    required PushDeviceServer server,
    QuietDisplay? quiet,
    String? environment,
    this.logoutTimeout = const Duration(seconds: 5),
    MethodChannel channel = const MethodChannel('mazl/push'),
  }) : _server = server,
       _quiet = quiet ?? QuietDisplay.instance,
       _environment = environment ?? (kDebugMode ? 'sandbox' : 'production'),
       _channel = channel;

  /// Longest wait for the server when signing out.
  final Duration logoutTimeout;

  final PushDeviceServer _server;
  final QuietDisplay _quiet;
  final String _environment;
  final MethodChannel _channel;

  void Function(Map<String, dynamic> data)? _onClick;
  bool _started = false;
  String? _token;
  int? _userId;

  /// The (member, token) pair the server was last told about.
  String? _declared;

  @override
  Future<void> start({
    required void Function(Map<String, dynamic> data) onClick,
  }) async {
    if (_started) return;
    _started = true;
    _onClick = onClick;
    _channel.setMethodCallHandler(_fromNative);

    _quiet.listenable.addListener(_sendQuiet);
    await _sendQuiet();

    final launchTap = await _invoke<Object?>('takeLaunchTap');
    if (launchTap is Map) _tapped(launchTap);

    await _invoke<void>('registerForRemoteNotifications');
  }

  @override
  Future<void> login(int userId) async {
    _userId = userId;
    await _declare();
  }

  @override
  Future<void> logout() async {
    final token = _token;
    if (token != null) {
      try {
        await _server.unregister(token: token).timeout(logoutTimeout);
      } catch (error) {
        debugPrint('Push: removing the token failed: $error');
      }
    }
    _userId = null;
    _declared = null;
  }

  @override
  Future<void> askPermission() => askPushPermissionIfNeeded(
    canRequest: () async =>
        await _invoke<String>('authorizationStatus') == 'notDetermined',
    request: (_) async => await _invoke<bool>('requestAuthorization') ?? false,
  );

  Future<Object?> _fromNative(MethodCall call) async {
    switch (call.method) {
      case 'onToken':
        final token = call.arguments;
        if (token is String && token.isNotEmpty) {
          _token = token;
          await _declare();
        }
      case 'onTokenError':
        debugPrint('Push: APNs registration failed: ${call.arguments}');
      case 'onTap':
        final data = call.arguments;
        if (data is Map) _tapped(data);
    }
    return null;
  }

  void _tapped(Map<Object?, Object?> userInfo) {
    final data = _plain(userInfo)..remove('aps');
    _onClick?.call(data);
  }

  Future<void> _declare() async {
    final token = _token;
    final userId = _userId;
    if (token == null || userId == null) return;
    final pair = '$userId:$token';
    if (_declared == pair) return;
    _declared = pair;
    try {
      await _server.register(token: token, environment: _environment);
    } catch (error) {
      debugPrint('Push: declaring the token failed: $error');
      if (_declared == pair) _declared = null;
    }
  }

  Future<void> _sendQuiet() => _invoke<void>('setQuiet', _quiet.isOn);

  /// Calls the native side; without it (tests, Android) or on error, logs and
  /// answers null.
  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Push: $method failed: $error');
      return null;
    }
  }
}

/// A map from the native side (keys typed `Object?`) as a `Map<String,
/// dynamic>`, nested maps and lists included.
Map<String, dynamic> _plain(Map<Object?, Object?> source) => {
  for (final entry in source.entries) '${entry.key}': _plainValue(entry.value),
};

Object? _plainValue(Object? value) => switch (value) {
  final Map<Object?, Object?> map => _plain(map),
  final List<Object?> list => list.map(_plainValue).toList(),
  _ => value,
};
