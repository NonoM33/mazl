import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/privacy/religious_data_consent.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/religious_consent_sheet.dart';
import '../../../../l10n/l10n.dart';

/// Shows the state of the religious-data consent and lets the member give or
/// withdraw it. Withdrawing erases the four practice fields on the server.
class ReligiousDataSettingsScreen extends ConsumerStatefulWidget {
  const ReligiousDataSettingsScreen({super.key});

  @override
  ConsumerState<ReligiousDataSettingsScreen> createState() =>
      _ReligiousDataSettingsScreenState();
}

const _pagePadding = EdgeInsets.fromLTRB(24, 8, 24, 48);

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
        title: Text(context.l10n.privacySettingsWithdrawTitle),
        content: Text(context.l10n.privacySettingsWithdrawBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.privacySettingsWithdraw),
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
      _toast(context.l10n.privacySettingsWithdrawFailed);
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religiousDataConsentProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacySettingsTitle)),
      // Held like a book: the explanation on the page where the reading
      // starts, the decision on the other.
      body: _content(state),
    );
  }

  Widget _content(AsyncValue<ApiResponse<ReligiousDataConsent>> state) {
    final consent = state.valueOrNull?.data;
    if (state.isLoading) {
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
            child: Text(context.l10n.privacySettingsLoadFailed),
          ),
          TextButton(
            onPressed: _refresh,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      );
    }
    final valid = consent.isValid;
    return FoldSpread(
      padding: _pagePadding,
      start: [
        SectionLabel(context.l10n.privacySheetLabel, color: AppColors.tekhelet),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            valid
                ? context.l10n.privacySettingsGrantedTitle
                : context.l10n.privacySettingsNotGrantedTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Text(consent.text, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
      ],
      end: [
        if (valid)
          OutlinedButton(
            onPressed: _busy ? null : () => _withdraw(consent),
            child: Text(context.l10n.privacySettingsWithdraw),
          )
        else
          ElevatedButton(
            onPressed: _busy ? null : () => _grant(consent),
            child: Text(context.l10n.privacyGive),
          ),
      ],
    );
  }
}
