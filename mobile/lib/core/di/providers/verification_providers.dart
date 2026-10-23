import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/http_verification_api.dart';
import '../../services/verification_api.dart';

/// Verification endpoints (levels 1 and 2). Overridden by fakes in tests.
final verificationApiProvider = Provider<VerificationApi>((ref) => HttpVerificationApi());
