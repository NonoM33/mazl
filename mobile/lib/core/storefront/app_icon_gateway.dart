import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The app icon of the device, behind the native channel `mazl/app_icon`
/// (`ios/Runner/AppDelegate.swift`, `UIApplication.setAlternateIconName`).
abstract interface class AppIconGateway {
  /// Whether this device lets the app change its icon.
  Future<bool> supportsAlternateIcons();

  /// The alternate icon in use (`AppIcon-valentine`), null for the normal one.
  Future<String?> currentIcon();

  /// Puts [name] on the home screen; null brings the normal icon back. iOS
  /// shows its own alert and refuses unless the app is in the foreground.
  Future<void> setIcon(String? name);
}

class MethodChannelAppIconGateway implements AppIconGateway {
  const MethodChannelAppIconGateway({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  static const channelName = 'mazl/app_icon';
  static const supportsMethod = 'supportsAlternateIcons';
  static const currentMethod = 'alternateIconName';
  static const setMethod = 'setAlternateIconName';

  final MethodChannel _channel;

  @override
  Future<bool> supportsAlternateIcons() async {
    try {
      return await _channel.invokeMethod<bool>(supportsMethod) ?? false;
    } on MissingPluginException {
      // Android, an older build, the tests: nothing to change.
      return false;
    }
  }

  @override
  Future<String?> currentIcon() async {
    try {
      return await _channel.invokeMethod<String>(currentMethod);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> setIcon(String? name) async {
    await _channel.invokeMethod<void>(setMethod, {'name': name});
  }
}

/// The platform's gateway: the channel on iOS, an inert one elsewhere.
AppIconGateway platformAppIconGateway() =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? const MethodChannelAppIconGateway()
    : const _NoAppIcon();

class _NoAppIcon implements AppIconGateway {
  const _NoAppIcon();

  @override
  Future<bool> supportsAlternateIcons() async => false;

  @override
  Future<String?> currentIcon() async => null;

  @override
  Future<void> setIcon(String? name) async {}
}
