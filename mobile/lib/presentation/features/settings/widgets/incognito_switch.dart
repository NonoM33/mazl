import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/premium/premium_settings.dart';
import '../../../../core/premium/premium_settings_api.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// « Mode discret » (mazl+, docs/premium/MONETISATION.md §3): only the people
/// the member has liked see them in Discover.
///
/// The server holds the value: the switch shows what `GET
/// /api/premium/settings` answered and moves only when `PUT
/// /api/profile/incognito` answers, so it never shows a state the server does
/// not hold. A member without mazl+ gets the mazl+ page instead of a change.
class IncognitoSwitch extends StatefulWidget {
  const IncognitoSwitch({super.key, this.api, this.openPlus});

  /// Injected by tests; the app uses the real client.
  final PremiumSettingsApi? api;

  /// Opens the mazl+ page; resolves when the member is back from it. Injected
  /// by tests; the app pushes [RoutePaths.premium].
  final Future<void> Function(BuildContext context)? openPlus;

  @override
  State<IncognitoSwitch> createState() => _IncognitoSwitchState();
}

class _IncognitoSwitchState extends State<IncognitoSwitch> {
  late final PremiumSettingsApi _api = widget.api ?? HttpPremiumSettingsApi();

  /// Null until the server has answered.
  PremiumSettings? _settings;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final settings = await _api.getSettings();
      if (!mounted) return;
      setState(() => _settings = settings);
    } on PremiumSettingsException catch (error) {
      debugPrint('Incognito setting unavailable: ${error.kind.name}');
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _openPlus() async {
    final open =
        widget.openPlus ?? (context) => context.push<void>(RoutePaths.premium);
    await open(context);
    // The member may have subscribed: the server says.
    if (mounted) await _load();
  }

  Future<void> _toggle(bool wanted) async {
    final settings = _settings;
    if (_saving || settings == null) return;
    if (!settings.isPlus && wanted) {
      await _openPlus();
      return;
    }
    setState(() => _saving = true);
    try {
      final held = await _api.setIncognito(wanted);
      if (!mounted) return;
      setState(() {
        _settings = settings.copyWith(incognito: held);
        _saving = false;
      });
    } on PremiumSettingsException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error.kind == PremiumSettingsErrorKind.plusRequired) {
        // The plan changed since the settings were read.
        await _openPlus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.plusPrivacySaveFailed)),
        );
      }
    }
  }

  String _subtitle(AppLocalizations l10n, PremiumSettings? settings) {
    if (_loadFailed) return l10n.plusPrivacyLoadFailed;
    if (settings == null) return l10n.plusPrivacyLoading;
    if (!settings.isPlus) return l10n.plusPrivacyLocked;
    return l10n.plusPrivacyIncognitoSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = _settings;
    final locked = settings != null && !settings.isPlus;
    final canToggle = settings != null && !_saving;
    return ListTile(
      key: const ValueKey('incognito-row'),
      leading: const Icon(LucideIcons.eyeOff, color: AppColors.primary),
      title: Text(l10n.plusPrivacyIncognitoTitle),
      subtitle: Text(_subtitle(l10n, settings)),
      trailing: locked
          ? const Icon(LucideIcons.lock, size: 18)
          : Switch(
              key: const ValueKey('incognito-switch'),
              value: settings?.incognito ?? false,
              onChanged: canToggle ? _toggle : null,
            ),
      onTap: _loadFailed
          ? _load
          : locked
          ? _openPlus
          : canToggle
          ? () => _toggle(!settings.incognito)
          : null,
    );
  }
}
