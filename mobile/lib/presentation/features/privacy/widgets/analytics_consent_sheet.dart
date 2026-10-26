import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/analytics_providers.dart';
import '../../../../core/privacy/analytics_consent.dart';
import '../../../../core/privacy/privacy_consent_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Asks once whether MAZL may measure how the app is used and records the
/// answer. Resolves true when accepted, false when refused, null when
/// dismissed or when the answer could not be recorded.
Future<bool?> showAnalyticsConsentSheet(
  BuildContext context,
  AnalyticsConsent consent,
) {
  return showMazlSheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => AnalyticsConsentSheet(consent: consent),
  );
}

class AnalyticsConsentSheet extends ConsumerStatefulWidget {
  const AnalyticsConsentSheet({super.key, required this.consent});

  final AnalyticsConsent consent;

  @override
  ConsumerState<AnalyticsConsentSheet> createState() =>
      _AnalyticsConsentSheetState();
}

class _AnalyticsConsentSheetState extends ConsumerState<AnalyticsConsentSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _decide(bool granted) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final response = await decideAnalyticsConsent(
      ref,
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
          ? context.l10n.analyticsSheetErrorOutdated
          : context.l10n.analyticsSheetErrorSave;
    });
  }

  List<Widget> _explanation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      SectionLabel(context.l10n.analyticsSheetLabel, color: AppColors.tekhelet),
      const SizedBox(height: 8),
      Semantics(
        header: true,
        child: Text(
          context.l10n.analyticsSheetTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.analyticsSheetBody,
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
      const SizedBox(height: 16),
    ];
  }

  /// Two buttons of the same kind and size: refusing is as easy as accepting.
  List<Widget> _choices(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            liveRegion: true,
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        ),
      _choice(context.l10n.analyticsSheetAccept, true),
      const SizedBox(height: 8),
      _choice(context.l10n.analyticsSheetDecline, false),
    ];
  }

  /// Full width: the whole row answers a tap, not only the label.
  Widget _choice(String label, bool granted) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _busy ? null : () => _decide(granted),
      child: Text(label),
    ),
  );

  /// A bottom sheet already keeps to one side of the fold (Flutter shows a
  /// modal route in one sub-screen of a display with a fold), where it can be
  /// short: the words scroll, the two buttons stay in view below them.
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _explanation(context),
          ),
        ),
      ),
      ..._choices(context),
    ],
  );
}
