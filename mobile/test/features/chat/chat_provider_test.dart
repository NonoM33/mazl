import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/chat/chat_providers.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';

import 'chat_fakes.dart';

void main() {
  ProviderContainer container(FakeChatApi api, FakeChatRealtime realtime) => ProviderContainer(overrides: [
        chatSessionProvider.overrideWithValue('user-1'),
        chatApiProvider.overrideWithValue(api),
        chatRealtimeSourceProvider.overrideWithValue(realtime),
        chatMyUserIdProvider.overrideWith((ref) async => 7),
      ]);

  test('chatControllerProvider(id) exposes ChatState and ChatActions and loads', () async {
    final api = FakeChatApi()
      ..onGet = (before, limit) async => MessagePage(messages: [serverMessage(id: 2), serverMessage(id: 1)], hasMore: false);
    final realtime = FakeChatRealtime();
    final c = container(api, realtime);
    addTearDown(c.dispose);

    final ChatActions actions = c.read(chatControllerProvider(40).notifier);
    expect(c.read(chatControllerProvider(40)).loading, isTrue);

    await actions.load();

    final ChatState state = c.read(chatControllerProvider(40));
    expect(state.messages.map((m) => m.id), [1, 2]);
    expect(state.myUserId, 7);
    expect(state.conversationId, 40);
  });

  test('each conversation has its own controller, kept between reads', () {
    final c = container(FakeChatApi(), FakeChatRealtime());
    addTearDown(c.dispose);
    expect(identical(c.read(chatControllerProvider(40).notifier), c.read(chatControllerProvider(40).notifier)), isTrue);
    expect(identical(c.read(chatControllerProvider(40).notifier), c.read(chatControllerProvider(41).notifier)), isFalse);
    expect(c.read(chatControllerProvider(41)).conversationId, 41);
  });

  test('a failed message survives leaving and re-entering the screen', () async {
    final api = FakeChatApi()..onSend = ((call) async => throw const ChatApiException(ChatApiErrorKind.network));
    final c = container(api, FakeChatRealtime());
    addTearDown(c.dispose);

    // The screen listens, then goes away (listener closed), then comes back.
    final first = c.listen(chatControllerProvider(40), (_, __) {});
    await c.read(chatControllerProvider(40).notifier).sendText('perdu');
    first.close();

    final again = c.read(chatControllerProvider(40));
    expect(again.messages.single.status, MessageStatus.failed);
  });

  test('disposing the container stops the controller listening', () {
    final realtime = FakeChatRealtime();
    final c = container(FakeChatApi(), realtime);
    c.read(chatControllerProvider(40));
    expect(realtime.hasListeners, isTrue);
    c.dispose();
    expect(realtime.hasListeners, isFalse);
  });
}
