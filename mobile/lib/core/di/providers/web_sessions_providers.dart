import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../web_sessions/web_sessions_api.dart';

/// Web login endpoints. Overridden by a fake in tests.
final webSessionsApiProvider = Provider<WebSessionsApi>(
  (ref) => HttpWebSessionsApi(),
);
