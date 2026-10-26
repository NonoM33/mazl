import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/analytics_providers.dart';
import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/privacy/analytics_consent.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'package:mazl/core/layout/column_app_bar.dart';

/// Shows whether MAZL may measure how the app is used and lets the member
/// accept or withdraw at any time. Withdrawing stops the measurement at once.
class AnalyticsSettingsScreen extends ConsumerStatefulWidget {
  const AnalyticsSettingsScreen({super.key});

  @override
  ConsumerState<AnalyticsSettingsScreen> createState() =>
      _AnalyticsSettingsScreenState();
}

const _pagePadding = EdgeInsets.fromLTRB(24, 8, 24, 48);

class _AnalyticsSettingsScreenState
    extends ConsumerState<AnalyticsSettingsScreen> {
  bool _busy = false;

  Future<void> _decide(AnalyticsConsent consent, bool granted) async {
    setState(() => _busy = true);
    final response = await decideAnalyticsConsent(
      ref,
      granted: granted,
      version: consent.currentVersion,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.analyticsSettingsSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsConsentProvider);
    return Scaffold(
      appBar: ColumnAppBar(
        appBar: AppBar(title: Text(context.l10n.analyticsSettingsTitle)),
      ),
      body: _content(state),
    );
  }

  Widget _content(AsyncValue<ApiResponse<AnalyticsConsent>> state) {
    final consent = state.valueOrNull?.data;
    if (state.isLoading && consent == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (consent == null) {
      return ListView(
        padding: _pagePadding,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(context.l10n.analyticsSettingsLoadFailed),
          ),
          TextButton(
            onPressed: () => ref.invalidate(analyticsConsentProvider),
            child: Text(context.l10n.commonRetry),
          ),
        ],
      );
    }
    final on = consent.isValid;
    return FoldSpread(
      padding: _pagePadding,
      start: [
        SectionLabel(
          context.l10n.analyticsSheetLabel,
          color: AppColors.tekhelet,
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            on
                ? context.l10n.analyticsSettingsGrantedTitle
                : context.l10n.analyticsSettingsNotGrantedTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Text(consent.text, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
      ],
      end: [
        if (on)
          OutlinedButton(
            onPressed: _busy ? null : () => _decide(consent, false),
            child: Text(context.l10n.analyticsSettingsWithdraw),
          )
        else
          ElevatedButton(
            onPressed: _busy ? null : () => _decide(consent, true),
            child: Text(context.l10n.analyticsSettingsAccept),
          ),
      ],
    );
  }
}
