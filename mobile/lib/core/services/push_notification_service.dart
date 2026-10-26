import 'dart:async';

import 'package:flutter/foundation.dart';

import '../router/root_navigator.dart';
import 'auth_service.dart';
import 'push_device_server.dart';
import 'push_gateway.dart';
import 'push_navigator.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  PushNotificationService._internal()
    : this.withGateway(
        ApnsPushGateway(server: ApiPushDeviceServer()),
        PushNavigator(
          isReady: () => _router.isReady,
          open: (path) => _router.open(path),
        ),
      );

  @visibleForTesting
  PushNotificationService.withGateway(this._gateway, this._navigator);

  static final RouterPushTarget _router = RouterPushTarget(
    navigatorKey: rootNavigatorKey,
    isAuthenticated: () => AuthService().isAuthenticated,
  );

  final PushGateway _gateway;
  final PushNavigator _navigator;

  bool _initialized = false;
  bool _permissionAsked = false;

  /// Starts the push SDK. The permission is NOT asked here, before the member
  /// is even signed in: [loginUser] asks it.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _gateway.start(onClick: _navigator.handle);
  }

  /// Declares this phone to the server (call after user authentication), then
  /// asks for the notifications permission once. The system dialog is not
  /// waited for: signing in must not hang on the member's answer.
  Future<void> loginUser(int userId) async {
    await _gateway.login(userId);
    if (_permissionAsked) return;
    _permissionAsked = true;
    unawaited(_askPermission());
  }

  Future<void> _askPermission() async {
    try {
      await _gateway.askPermission();
    } catch (error, stackTrace) {
      debugPrint('Push permission request failed: $error\n$stackTrace');
    }
  }

  /// Removes this phone from the server (call on user logout, while the
  /// session token is still valid).
  Future<void> logoutUser() => _gateway.logout();
}
