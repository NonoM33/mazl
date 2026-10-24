import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/privacy/religious_data_consent.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/religious_consent_sheet.dart';

/// Shows the state of the religious-data consent and lets the member give or
/// withdraw it. Withdrawing erases the four practice fields on the server.
class ReligiousDataSettingsScreen extends ConsumerStatefulWidget {
  const ReligiousDataSettingsScreen({super.key});

  @override
  ConsumerState<ReligiousDataSettingsScreen> createState() =>
      _ReligiousDataSettingsScreenState();
}

class _ReligiousDataSettingsScreenState
    extends ConsumerState<ReligiousDataSettingsScreen> {
  bool _busy = false;

  void _refresh() => ref.invalidate(religiousDataConsentProvider);

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _grant(ReligiousDataConsent consent) async {
    await showReligiousConsentSheet(context, consent);
    if (mounted) _refresh();
  }

  Future<void> _withdraw(ReligiousDataConsent consent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer votre accord ?'),
        content: const Text(
          'Votre courant, votre cashrout, votre pratique du Shabbat et '
          'votre intention seront effacés de votre profil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer mon accord'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final response = await ref
        .read(privacyConsentApiProvider)
        .decideReligiousData(granted: false, version: consent.currentVersion);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!response.success) {
      _toast('Impossible de retirer votre accord. Réessayez.');
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religiousDataConsentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Données de pratique religieuse')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: _content(state),
      ),
    );
  }

  List<Widget> _content(AsyncValue<ApiResponse<ReligiousDataConsent>> state) {
    final consent = state.valueOrNull?.data;
    if (state.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (consent == null) {
      return [
        Semantics(
          liveRegion: true,
          child: const Text(
            'Impossible de charger votre accord. Vérifiez votre connexion.',
          ),
        ),
        TextButton(onPressed: _refresh, child: const Text('Réessayer')),
      ];
    }
    final valid = consent.isValid;
    return [
      const SectionLabel(
        'Données sensibles · RGPD article 9',
        color: AppColors.tekhelet,
      ),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(
          valid ? 'Accord donné' : 'Accord non donné',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 12),
      Text(consent.text, style: const TextStyle(fontSize: 14, height: 1.5)),
      const SizedBox(height: 24),
      if (valid)
        OutlinedButton(
          onPressed: _busy ? null : () => _withdraw(consent),
          child: const Text('Retirer mon accord'),
        )
      else
        ElevatedButton(
          onPressed: _busy ? null : () => _grant(consent),
          child: const Text('Donner mon accord'),
        ),
    ];
  }
}
