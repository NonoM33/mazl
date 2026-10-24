import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/chat/chat_realtime.dart';
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_chat_realtime.dart';
import 'package:mazl/core/dev/demo_fixtures.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/models/chat_message.dart';

import '../../features/chat/chat_fakes.dart';

void main() {
  const me = 7;
  const tick = Duration(seconds: 1);

  late FakeChatApi api;
  late List<ChatMessage> server; // oldest first
  late bool typing;
  late DemoChatRealtimeSource source;
  late List<ChatRealtimeEvent> events;

  setUp(() {
    api = FakeChatApi(myUserId: me);
    server = [serverMessage(id: 1, content: 'Salut')];
    typing = false;
    events = [];
    api.onGet = (before, limit) async => MessagePage(messages: server.reversed.toList(), hasMore: false);
    source = DemoChatRealtimeSource(api: api, myUserId: () => me, isTyping: (_) => typing);
  });

  void listen(FakeAsync async, void Function(StreamSubscription<ChatRealtimeEvent>) body) {
    final sub = source.events(40).listen(events.add);
    body(sub);
  }

  test('nothing is fetched until someone listens', () {
    fakeAsync((async) {
      async.elapse(const Duration(seconds: 10));
      expect(api.getCalls, isEmpty);
    });
  });

  test('listening polls page 1 immediately, then every second', () {
    fakeAsync((async) {
      listen(async, (_) {
        async.flushMicrotasks();
        expect(api.getCalls, hasLength(1));
        expect(api.getCalls.single.before, isNull);
        async.elapse(tick * 3);
        expect(api.getCalls, hasLength(4));
      });
    });
  });

  test('cancelling the subscription stops the polling', () {
    fakeAsync((async) {
      listen(async, (sub) {
        async.elapse(tick * 2);
        final calls = api.getCalls.length;
        sub.cancel();
        async.elapse(tick * 10);
        expect(api.getCalls.length, calls);
      });
    });
  });

  test('a message the controller may not have seen is emitted once, then only changes', () {
    fakeAsync((async) {
      listen(async, (_) {
        async.elapse(tick * 3);
        expect(events.whereType<ChatMessageArrived>().map((e) => e.message.id), [1]);
      });
    });
  });

  test('a new message from the other side arrives as chat:message, oldest first', () {
    fakeAsync((async) {
      listen(async, (_) {
        async.elapse(tick);
        events.clear();
        server
          ..add(serverMessage(id: 2, content: 'Deux'))
          ..add(serverMessage(id: 3, content: 'Trois'));
        async.elapse(tick);
        expect(events.whereType<ChatMessageArrived>().map((e) => e.message.id), [2, 3]);
      });
    });
  });

  test('reactions or a link preview changing is a chat:updated', () {
    fakeAsync((async) {
      listen(async, (_) {
        async.elapse(tick);
        events.clear();
        server[0] = serverMessage(id: 1, reactions: [
          {'emoji': '❤️', 'user_ids': [me]},
        ]);
        async.elapse(tick);
        final updated = events.whereType<ChatMessageUpdated>().single;
        expect(updated.message.reactions.single.emoji, '❤️');
        events.clear();
        async.elapse(tick * 3);
        expect(events, isEmpty);
      });
    });
  });

  test('my message becoming read is a chat:read from the other member', () {
    fakeAsync((async) {
      server = [
        serverMessage(id: 1, senderId: 45, content: 'Hello'),
        serverMessage(id: 2, senderId: me, content: 'Salut'),
      ];
      listen(async, (_) {
        async.elapse(tick);
        events.clear();
        server[1] = serverMessage(id: 2, senderId: me, content: 'Salut', readAt: '2026-10-22T20:05:00.000Z');
        async.elapse(tick);
        final read = events.whereType<ChatReadUpTo>().single;
        expect(read.conversationId, 40);
        expect(read.userId, 45);
        expect(read.upToId, 2);
        expect(read.readAt, DateTime.utc(2026, 10, 22, 20, 5));
        expect(events.whereType<ChatMessageUpdated>(), isEmpty);
      });
    });
  });

  test('typing comes from the demo store and is emitted on change only', () {
    fakeAsync((async) {
      listen(async, (_) {
        async.elapse(tick);
        expect(events.whereType<ChatTypingChanged>(), isEmpty);
        typing = true;
        async.elapse(tick * 3);
        var typed = events.whereType<ChatTypingChanged>().toList();
        expect(typed, hasLength(1));
        expect(typed.single.isTyping, isTrue);
        expect(typed.single.userId, 45);
        expect(typed.single.conversationId, 40);
        typing = false;
        async.elapse(tick);
        typed = events.whereType<ChatTypingChanged>().toList();
        expect(typed.map((e) => e.isTyping), [true, false]);
      });
    });
  });

  test('a failing poll is retried at the next tick', () {
    fakeAsync((async) {
      var fail = true;
      api.onGet = (before, limit) async {
        if (fail) throw const ChatApiException(ChatApiErrorKind.network);
        return MessagePage(messages: server.reversed.toList(), hasMore: false);
      };
      listen(async, (_) {
        async.elapse(tick * 2);
        expect(events, isEmpty);
        fail = false;
        async.elapse(tick);
        expect(events.whereType<ChatMessageArrived>(), hasLength(1));
      });
    });
  });

  test('a slow poll is not doubled up', () {
    fakeAsync((async) {
      api.onGet = (before, limit) => Future.delayed(
            const Duration(seconds: 3),
            () => MessagePage(messages: server.reversed.toList(), hasMore: false),
          );
      listen(async, (_) {
        async.elapse(const Duration(milliseconds: 2500));
        expect(api.getCalls, hasLength(1));
      });
    });
  });

  test('sendTyping does nothing in the demo', () {
    source.sendTyping(40, true);
  });

  group('with the real demo store and the demo HTTP client', () {
    tearDown(() {
      DevSession.stop();
      DemoStore.clock = DateTime.now;
    });

    test('my message: typing, then read, then the fictitious reply, all pushed', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 10, 22, 20);
        DemoStore.clock = () => now;
        DevSession.start();
        final demoApi = HttpChatApi(
          baseUrl: 'https://demo.invalid',
          token: () => null,
          clientFactory: () => DemoHttpClient(
            MockClient((_) async => throw StateError('the demo must not reach the network')),
            latency: Duration.zero,
          ),
        );
        const conversation = 101; // with Noémie (301)
        final demo = DemoChatRealtimeSource(api: demoApi, myUserId: () => DemoFixtures.meId);
        void step() {
          now = now.add(const Duration(seconds: 1));
          async.elapse(const Duration(seconds: 1));
        }

        final received = <ChatRealtimeEvent>[];
        final sub = demo.events(conversation).listen(received.add);
        step();
        received.clear();

        demoApi.sendMessage(conversation, clientId: 'c-demo', type: ChatMessageType.text, content: 'Coucou');
        for (var i = 0; i < 8; i++) {
          step();
        }
        sub.cancel();

        final mine = received.whereType<ChatMessageArrived>().where((e) => e.message.clientId == 'c-demo');
        expect(mine, hasLength(1));
        expect(received.whereType<ChatTypingChanged>().map((e) => e.isTyping), [true, false]);
        expect(received.whereType<ChatReadUpTo>(), isNotEmpty);
        expect(
          received.whereType<ChatMessageArrived>().where((e) => e.message.senderId != DemoFixtures.meId),
          isNotEmpty,
          reason: 'the correspondent answers',
        );
      });
    });
  });
}
