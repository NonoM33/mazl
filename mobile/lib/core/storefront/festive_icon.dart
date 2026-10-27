import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_icon_gateway.dart';

/// Where the « Icône des fêtes » setting is kept between two launches.
abstract interface class FestiveIconSettingStore {
  /// On by default.
  Future<bool> read();
  Future<void> write(bool enabled);
}

class SharedPreferencesFestiveIconSettingStore
    implements FestiveIconSettingStore {
  static const _key = 'festive_icon_enabled';

  @override
  Future<bool> read() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? true;

  @override
  Future<void> write(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(_key, enabled);
}

/// Puts the icon the server asks for on the home screen, within the limits of
/// the contract (docs/storefront/CONTRACT.md §7): only in the foreground, only
/// when it differs from the icon in use, at most once per launch, and only when
/// the member keeps « Icône des fêtes » on. Never blocks, never throws.
class FestiveIconApplier {
  FestiveIconApplier(this._gateway);

  final AppIconGateway _gateway;

  bool _changedThisLaunch = false;

  /// Whether the icon was changed by the server's request since the launch.
  bool get changedThisLaunch => _changedThisLaunch;

  /// Aligns the icon with [requested] (null: the normal icon).
  ///
  /// [enabled] is the setting. A change the member asks for in the settings
  /// ([userInitiated]) is not held back by the once-per-launch limit.
  /// Returns whether the icon was changed.
  Future<bool> apply({
    required String? requested,
    required bool enabled,
    required bool foreground,
    bool userInitiated = false,
  }) async {
    if (!foreground) return false;
    if (_changedThisLaunch && !userInitiated) return false;
    final target = enabled ? requested : null;
    try {
      if (!await _gateway.supportsAlternateIcons()) return false;
      final current = await _gateway.currentIcon();
      if (current == target) return false;
      if (!userInitiated) _changedThisLaunch = true;
      await _gateway.setIcon(target);
      return true;
    } on PlatformException catch (error) {
      // iOS refuses (app not active, icon not in the bundle): say so in the
      // logs and leave the icon as it is. No retry before the next launch.
      debugPrint('App icon: ${error.code} ${error.message}');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint('App icon: ${error.message}');
      return false;
    }
  }
}

class FestiveIconSettingController extends StateNotifier<bool> {
  FestiveIconSettingController(this._store, {bool initial = true})
    : super(initial);

  final FestiveIconSettingStore _store;

  Future<void> set(bool enabled) async {
    state = enabled;
    try {
      await _store.write(enabled);
    } on Exception catch (error) {
      debugPrint('Festive icon setting not saved: $error');
    }
  }
}
