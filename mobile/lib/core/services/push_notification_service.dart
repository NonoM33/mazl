import 'dart:async';

import 'package:flutter/foundation.dart';

import '../router/root_navigator.dart';
import 'auth_service.dart';
import 'push_gateway.dart';
import 'push_navigator.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  PushNotificationService._internal()
    : this.withGateway(
        OneSignalPushGateway(),
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
    _gateway.start(onClick: _navigator.handle);
    _initialized = true;
  }

  /// Login user to OneSignal (call after user authentication), then ask for
  /// the notifications permission once. The system dialog is not waited for:
  /// signing in must not hang on the member's answer.
  Future<void> loginUser(int userId) async {
    await _gateway.login('user_$userId');
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

  /// Logout user from OneSignal (call on user logout)
  Future<void> logoutUser() => _gateway.logout();

  /// Set user tags for segmentation
  Future<void> setUserTags(Map<String, String> tags) => _gateway.addTags(tags);

  /// Remove user tags
  Future<void> removeUserTags(List<String> keys) => _gateway.removeTags(keys);
}
