import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/privacy_consent_api.dart';
import '../../privacy/religious_data_consent.dart';
import '../../services/api_service.dart';

/// Privacy consent endpoints. Overridden by a fake in tests.
final privacyConsentApiProvider = Provider<PrivacyConsentApi>(
  (ref) => HttpPrivacyConsentApi(),
);

/// The member's current religious-data consent. A failed fetch is kept as a
/// failed [ApiResponse] so screens can tell "not granted" from "unknown".
final religiousDataConsentProvider =
    FutureProvider.autoDispose<ApiResponse<ReligiousDataConsent>>(
      (ref) => ref.watch(privacyConsentApiProvider).religiousData(),
    );
