import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/identity_providers.dart';
import 'identity_flow_controller.dart';
import 'identity_flow_state.dart';

final identityFlowControllerProvider =
    StateNotifierProvider.autoDispose<IdentityFlowController, IdentityFlowState>((ref) {
  return IdentityFlowController(
    chipReader: ref.watch(chipReaderProvider),
    api: ref.watch(identityVerificationApiProvider),
    liveness: ref.watch(identityLivenessCaptureProvider),
  );
});
