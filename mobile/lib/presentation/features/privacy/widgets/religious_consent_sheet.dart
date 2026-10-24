import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/privacy/privacy_consent_api.dart';
import '../../../../core/privacy/religious_data_consent.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Asks for the explicit consent of article 9 and records the answer.
/// Resolves true when granted, false when refused, null when dismissed or when
/// the answer could not be recorded.
Future<bool?> showReligiousConsentSheet(
  BuildContext context,
  ReligiousDataConsent consent,
) {
  return showMazlSheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => ReligiousConsentSheet(consent: consent),
  );
}

class ReligiousConsentSheet extends ConsumerStatefulWidget {
  const ReligiousConsentSheet({super.key, required this.consent});

  final ReligiousDataConsent consent;

  @override
  ConsumerState<ReligiousConsentSheet> createState() =>
      _ReligiousConsentSheetState();
}

class _ReligiousConsentSheetState extends ConsumerState<ReligiousConsentSheet> {
  bool _checked = false;
  bool _busy = false;
  String? _error;

  Future<void> _decide(bool granted) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final response = await ref
        .read(privacyConsentApiProvider)
        .decideReligiousData(
          granted: granted,
          version: widget.consent.currentVersion,
        );
    if (!mounted) return;
    if (response.success) {
      Navigator.of(context).pop(granted);
      return;
    }
    setState(() {
      _busy = false;
      _error = response.error == PrivacyConsentError.versionOutdated
          ? 'Le texte a été mis à jour. Fermez cette fenêtre et rouvrez-la.'
          : 'Votre choix n\'a pas pu être enregistré. Réessayez.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            'Données sensibles · RGPD article 9',
            color: AppColors.tekhelet,
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              'Votre pratique religieuse, avec votre accord',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ces informations aident à proposer des profils compatibles. '
            'Ce sont des données sensibles, traitées seulement avec votre '
            'accord explicite, distinct des conditions d\'utilisation. '
            'Vous pouvez refuser et utiliser MAZL quand même.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? scheme.surfaceContainerHighest
                  : AppColors.mist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.consent.text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _checked,
            onChanged: _busy
                ? null
                : (value) => setState(() => _checked = value ?? false),
            title: const Text(
              'J\'ai lu ce texte et je donne mon accord explicite.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _checked && !_busy ? () => _decide(true) : null,
            child: const Text('J\'accepte'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _decide(false),
            child: const Text('Continuer sans'),
          ),
        ],
      ),
    );
  }
}
