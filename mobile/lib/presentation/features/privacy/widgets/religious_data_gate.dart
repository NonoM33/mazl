import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/privacy/religious_data_consent.dart';
import '../../../../core/services/api_service.dart';
import 'religious_consent_sheet.dart';
import '../../../../l10n/l10n.dart';

/// Shows [child] (the practice fields) only once the member has given a valid
/// consent; otherwise shows a card that opens the consent sheet.
///
/// [onValidityChanged] reports whether the consent is valid (false while it is
/// loading or unknown), so the host screen can leave the four practice fields
/// out of the profile it sends: the server would ignore them anyway.
class ReligiousDataGate extends ConsumerStatefulWidget {
  const ReligiousDataGate({
    super.key,
    required this.child,
    required this.onValidityChanged,
  });

  final Widget child;
  final ValueChanged<bool> onValidityChanged;

  @override
  ConsumerState<ReligiousDataGate> createState() => _ReligiousDataGateState();
}

class _ReligiousDataGateState extends ConsumerState<ReligiousDataGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      religiousDataConsentProvider,
      (_, next) => widget.onValidityChanged(_validityOf(next)),
      fireImmediately: true,
    );
  }

  bool _validityOf(AsyncValue<ApiResponse<ReligiousDataConsent>> state) =>
      state.valueOrNull?.data?.isValid ?? false;

  Future<void> _ask(ReligiousDataConsent consent) async {
    final decided = await showReligiousConsentSheet(context, consent);
    if (decided != null) ref.invalidate(religiousDataConsentProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(religiousDataConsentProvider);
    if (_validityOf(state)) return widget.child;
    final consent = state.valueOrNull?.data;
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (consent == null) {
      return ReligiousDataNotice(
        text: context.l10n.privacyGateUnverifiable,
        actionLabel: context.l10n.commonRetry,
        onAction: () => ref.invalidate(religiousDataConsentProvider),
      );
    }
    return ReligiousDataNotice(
      text: context.l10n.privacyGateAsk,
      actionLabel: context.l10n.privacyGive,
      onAction: () => _ask(consent),
    );
  }
}

/// Card shown instead of the practice fields.
class ReligiousDataNotice extends StatelessWidget {
  const ReligiousDataNotice({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// Disables a practice field that lives outside the gate (the intention) while
/// there is no consent, and says why.
class ReligiousDataLocked extends StatelessWidget {
  const ReligiousDataLocked({
    super.key,
    required this.locked,
    required this.child,
  });

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
        const SizedBox(height: 8),
        Text(
          context.l10n.privacyLockedHint,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
