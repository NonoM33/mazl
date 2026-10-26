import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'push_permission.dart';
import 'quiet_display.dart';

/// What the app needs from the push provider. OneSignal behind it in the app, a
/// fake in the tests.
abstract interface class PushGateway {
  /// Starts the SDK. [onClick] gets the `data` of every notification the member
  /// taps. Does NOT ask for the permission (see [askPermission]).
  void start({required void Function(Map<String, dynamic> data) onClick});

  Future<void> login(String externalId);
  Future<void> logout();

  /// Shows the system permission dialog if the member was never asked. Never
  /// sends to the Settings: a refusal is respected.
  Future<void> askPermission();

  Future<void> addTags(Map<String, String> tags);
  Future<void> removeTags(List<String> keys);
}

class OneSignalPushGateway implements PushGateway {
  static const String _appId = '0bad7c7f-4a93-4a6d-84e7-ed77a48532cf';

  @override
  void start({required void Function(Map<String, dynamic> data) onClick}) {
    if (kDebugMode) OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) onClick(data);
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      routeForegroundNotification(
        QuietDisplay.instance,
        display: event.notification.display,
        discard: event.preventDefault,
      );
    });
  }

  @override
  Future<void> login(String externalId) => OneSignal.login(externalId);

  @override
  Future<void> logout() => OneSignal.logout();

  @override
  Future<void> askPermission() => askPushPermissionIfNeeded(
    canRequest: OneSignal.Notifications.canRequest,
    request: OneSignal.Notifications.requestPermission,
  );

  @override
  Future<void> addTags(Map<String, String> tags) =>
      OneSignal.User.addTags(tags);

  @override
  Future<void> removeTags(List<String> keys) => OneSignal.User.removeTags(keys);
}

/// A notification that arrives while the app is open: shown, unless the
/// Shabbat display is on, which nothing may disturb (no banner, no sound).
void routeForegroundNotification(
  QuietDisplay quiet, {
  required VoidCallback display,
  required VoidCallback discard,
}) => quiet.isOn ? discard() : display();
