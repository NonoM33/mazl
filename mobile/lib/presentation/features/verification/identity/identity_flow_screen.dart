import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'identity_flow_controller.dart';
import 'identity_flow_provider.dart';
import 'identity_flow_state.dart';
import 'identity_intro_view.dart';
import 'identity_messages.dart';
import 'identity_status_views.dart';
import 'mrz_manual_view.dart';
import 'mrz_review_view.dart';
import 'mrz_scanner_view.dart';
import 'nfc_read_view.dart';

/// Level 2 verification: identity from the NFC chip of a passport or ID card.
/// Pops with `true` once the identity is verified.
class IdentityFlowScreen extends ConsumerStatefulWidget {
  const IdentityFlowScreen({super.key});

  @override
  ConsumerState<IdentityFlowScreen> createState() => _IdentityFlowScreenState();
}

class _IdentityFlowScreenState extends ConsumerState<IdentityFlowScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(identityFlowControllerProvider.notifier).initialize());
  }

  void _close({bool verified = false}) => Navigator.of(context).maybePop(verified);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityFlowControllerProvider);
    final flow = ref.read(identityFlowControllerProvider.notifier);
    final busy = state is IdentitySubmitting || (state is IdentityNfc && state.reading);
    return PopScope(
      canPop: !busy,
      child: _view(context, state, flow),
    );
  }

  Widget _view(BuildContext context, IdentityFlowState state, IdentityFlowController flow) {
    void close() => _close();
    return switch (state) {
      IdentityChecking() => IdentityCheckingView(onClose: close),
      IdentityUnavailable(:final reason) => IdentityUnavailableView(reason: reason, onClose: close),
      IdentityIntro() => IdentityIntroView(onStart: flow.begin, onClose: close),
      IdentityMrz(manual: false) =>
        MrzScannerView(onScanned: flow.submitMrz, onManual: flow.useManualEntry, onClose: close),
      IdentityMrz(manual: true) => MrzManualView(onSubmit: flow.submitMrz, onUseCamera: flow.useCamera, onClose: close),
      IdentityMrzReview(:final mrz) =>
        MrzReviewView(mrz: mrz, onConfirm: flow.confirmMrz, onReject: flow.rejectMrz, onClose: close),
      IdentityNfc() => NfcReadView(
          state: state,
          onRead: flow.readChip,
          onRereadPhotoPage: flow.rereadPhotoPage,
          onRecover: () => _recover(context, flow, state.failure),
          onClose: close,
        ),
      IdentityFace() => IdentityFaceView(onCapture: () => flow.captureFace(context), onClose: close),
      IdentitySubmitting(:final stage) => IdentitySubmittingView(stage: stage),
      IdentityDone() => IdentityDoneView(onDone: () => _close(verified: true)),
      IdentityFailed(:final info) =>
        IdentityFailedView(info: info, onAction: () => _recover(context, flow, info), onClose: close),
    };
  }

  void _recover(BuildContext context, IdentityFlowController flow, IdentityFailureInfo? info) {
    if (info?.recovery == IdentityRecovery.close) {
      _close();
    } else {
      flow.recover(context);
    }
  }
}
