import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dev/demo_chat_realtime.dart';
import '../dev/demo_fixtures.dart';
import '../dev/dev_session.dart';
import '../di/providers/service_providers.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import 'chat_api.dart';
import 'chat_realtime.dart';
import 'websocket_chat_realtime_source.dart';

/// The HTTP client of the chat, on the app's base URL and the signed-in token.
final chatApiProvider = Provider<ChatApi>(
  (ref) => HttpChatApi(
    baseUrl: ApiConfig.baseUrl,
    token: () => AuthService().currentUser?.jwtToken,
  ),
);

/// My numeric user id (the one messages carry as `sender_id`). Recomputed when
/// another account signs in.
final chatMyUserIdProvider = FutureProvider<int>((ref) async {
  ref.watch(chatSessionProvider);
  final response = await ApiService().getCurrentUser();
  final user = response.data;
  if (!response.success || user == null) {
    throw StateError('current user unavailable');
  }
  return user.id;
});

/// Changes when another account signs in or out, so chat state is rebuilt.
final chatSessionProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider.select((user) => user?.id)),
);

/// Real-time input of the chat: the WebSocket, or in the demo session a source
/// that polls the same [ChatApi] (the demo has no socket).
final chatRealtimeSourceProvider = Provider<ChatRealtimeSource>((ref) {
  ref.watch(chatSessionProvider);
  if (DevSession.isActive) {
    return DemoChatRealtimeSource(
      api: ref.watch(chatApiProvider),
      myUserId: () => DemoFixtures.meId,
    );
  }
  return WebSocketChatRealtimeSource(WebSocketService());
});
