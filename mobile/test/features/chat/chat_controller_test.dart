import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/chat/chat_realtime.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';

import 'chat_fakes.dart';

const me = 7;
const other = 45;
const conversation = 40;
final clockNow = DateTime.utc(2026, 10, 22, 21);

class Harness {
  Harness({FakeChatApi? api, FakeChatRealtime? realtime, Future<int> Function()? user})
      : api = api ?? FakeChatApi(myUserId: me),
        realtime = realtime ?? FakeChatRealtime() {
    var counter = 0;
    controller = ChatControllerImpl(
      conversationId: conversation,
      api: this.api,
      realtime: this.realtime,
      resolveMyUserId: user ?? () async => me,
      now: () => now,
      newClientId: () => 'c-${++counter}',
    );
  }

  final FakeChatApi api;
  final FakeChatRealtime realtime;
  late final ChatControllerImpl controller;
  DateTime now = clockNow;

  ChatState get state => controller.state;
  List<ChatMessage> get messages => state.messages;

  /// First load with [serverNewestFirst] as page 1.
  Future<void> load([List<ChatMessage> serverNewestFirst = const [], bool hasMore = false]) async {
    api.onGet = (before, limit) async => MessagePage(messages: serverNewestFirst, hasMore: hasMore);
    await controller.load();
  }

  void dispose() => controller.dispose();
}

Uint8List bytes(int n) => Uint8List.fromList(List.filled(n, 1));

void main() {
  group('load', () {
    test('shows server messages oldest first and clears the spinner', () async {
      final h = Harness();
      expect(h.state.loading, isTrue);

      await h.load([serverMessage(id: 3), serverMessage(id: 2), serverMessage(id: 1)], true);

      expect(h.messages.map((m) => m.id), [1, 2, 3]);
      expect(h.state.loading, isFalse);
      expect(h.state.hasMore, isTrue);
      expect(h.state.myUserId, me);
      expect(h.state.conversationId, conversation);
      expect(h.state.error, isNull);
      expect(h.api.getCalls.single.before, isNull);
      expect(h.api.getCalls.single.limit, 30);
    });

    test('a failed first load surfaces a French message, and loading again recovers', () async {
      final h = Harness();
      h.api.onGet = (b, l) async => throw const ChatApiException('Pas de connexion internet.');
      await h.controller.load();

      expect(h.state.loading, isFalse);
      expect(h.state.error, 'Pas de connexion internet.');
      expect(h.messages, isEmpty);

      await h.load([serverMessage(id: 1)]);
      expect(h.state.error, isNull);
      expect(h.messages, hasLength(1));
    });

    test('an unresolvable user id is reported, not thrown', () async {
      final h = Harness(user: () async => throw StateError('no session'));
      await h.controller.load();
      expect(h.state.error, 'Impossible de charger la conversation.');
      expect(h.state.loading, isFalse);
    });

    test('loading again keeps the failed messages typed meanwhile and merges, never duplicates', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      h.api.onSend = (call) async => throw const ChatApiException('Pas de connexion internet.');
      await h.controller.sendText('perdu');
      await h.load([serverMessage(id: 2), serverMessage(id: 1)]);

      expect(h.messages.where((m) => m.id > 0).map((m) => m.id), [1, 2]);
      expect(h.messages.where((m) => m.status == MessageStatus.failed), hasLength(1));
    });
  });

  group('loadOlder', () {
    test('asks for the page before the oldest known id and prepends it', () async {
      final h = Harness();
      await h.load([serverMessage(id: 12), serverMessage(id: 11)], true);
      h.api.onGet = (before, limit) async => MessagePage(messages: [serverMessage(id: 10), serverMessage(id: 9)], hasMore: true);

      await h.controller.loadOlder();

      expect(h.api.getCalls.last.before, 11);
      expect(h.messages.map((m) => m.id), [9, 10, 11, 12]);
      expect(h.state.hasMore, isTrue);
      expect(h.state.loadingOlder, isFalse);
    });

    test('stops for good once the server says has_more is false', () async {
      final h = Harness();
      await h.load([serverMessage(id: 12)], true);
      h.api.onGet = (b, l) async => MessagePage(messages: [serverMessage(id: 5)], hasMore: false);
      await h.controller.loadOlder();
      expect(h.state.hasMore, isFalse);

      final calls = h.api.getCalls.length;
      await h.controller.loadOlder();
      await h.controller.loadOlder();
      expect(h.api.getCalls.length, calls);
    });

    test('does nothing when has_more was false from the start', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)], false);
      final calls = h.api.getCalls.length;
      await h.controller.loadOlder();
      expect(h.api.getCalls.length, calls);
    });

    test('two quick calls fetch one page', () async {
      final h = Harness();
      await h.load([serverMessage(id: 12)], true);
      final gate = Completer<MessagePage>();
      h.api.onGet = (b, l) => gate.future;
      final first = h.controller.loadOlder();
      final second = h.controller.loadOlder();
      expect(h.state.loadingOlder, isTrue);
      gate.complete(MessagePage(messages: [serverMessage(id: 3)], hasMore: true));
      await Future.wait([first, second]);
      expect(h.api.getCalls.where((c) => c.before == 12), hasLength(1));
    });

    test('an empty page also ends the pagination', () async {
      final h = Harness();
      await h.load([serverMessage(id: 12)], true);
      h.api.onGet = (b, l) async => const MessagePage(messages: [], hasMore: true);
      await h.controller.loadOlder();
      expect(h.state.hasMore, isFalse);
    });

    test('a failure keeps the list and lets the user try again', () async {
      final h = Harness();
      await h.load([serverMessage(id: 12)], true);
      h.api.onGet = (b, l) async => throw const ChatApiException('Délai dépassé, vérifiez votre connexion.');
      await h.controller.loadOlder();
      expect(h.messages, hasLength(1));
      expect(h.state.hasMore, isTrue);
      expect(h.state.loadingOlder, isFalse);
      expect(h.state.error, isNull);
    });
  });

  group('sending text', () {
    test('the bubble is there at once, sending, then becomes the server message', () async {
      final h = Harness();
      await h.load();
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;

      final done = h.controller.sendText('Salut toi');
      await pumpEventQueue();

      expect(h.messages, hasLength(1));
      final pending = h.messages.single;
      expect(pending.id, lessThan(0));
      expect(pending.isLocal, isTrue);
      expect(pending.clientId, 'c-1');
      expect(pending.status, MessageStatus.sending);
      expect(pending.senderId, me);
      expect(pending.content, 'Salut toi');
      expect(pending.type, ChatMessageType.text);
      expect(pending.createdAt, clockNow);

      gate.complete(h.api.echo(h.api.sendCalls.single));
      expect(await done, isNull);

      final sent = h.messages.single;
      expect(sent.id, 1000);
      expect(sent.status, MessageStatus.sent);
      expect(sent.clientId, 'c-1');
      expect(h.api.sendCalls.single.type, ChatMessageType.text);
      expect(h.api.sendCalls.single.content, 'Salut toi');
    });

    test('blank text is not sent', () async {
      final h = Harness();
      await h.load();
      expect(await h.controller.sendText('   \n'), isNull);
      expect(h.messages, isEmpty);
      expect(h.api.sendCalls, isEmpty);
    });

    test('text is trimmed', () async {
      final h = Harness();
      await h.load();
      await h.controller.sendText('  coucou  ');
      expect(h.api.sendCalls.single.content, 'coucou');
    });

    test('WebSocket echo first, HTTP answer after: one message', () async {
      final h = Harness();
      await h.load();
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;
      final done = h.controller.sendText('Hello');
      await pumpEventQueue();
      final echo = h.api.echo(h.api.sendCalls.single);

      h.realtime.emit(ChatMessageArrived(echo));
      expect(h.messages, hasLength(1));
      expect(h.messages.single.id, 1000);
      expect(h.messages.single.status, MessageStatus.sent);

      gate.complete(echo);
      await done;
      expect(h.messages, hasLength(1));
      expect(h.messages.single.id, 1000);
    });

    test('HTTP answer first, WebSocket echo after: one message', () async {
      final h = Harness();
      await h.load();
      await h.controller.sendText('Hello');
      final echo = h.api.echo(h.api.sendCalls.single);

      h.realtime.emit(ChatMessageArrived(echo));
      h.realtime.emit(ChatMessageArrived(echo));

      expect(h.messages, hasLength(1));
      expect(h.messages.single.id, 1000);
    });

    test('a failure leaves a failed bubble and returns the French message', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('Pas de connexion internet.');

      final error = await h.controller.sendText('Hello');

      expect(error, 'Pas de connexion internet.');
      expect(h.messages.single.status, MessageStatus.failed);
      expect(h.messages.single.content, 'Hello');
    });

    test('retry sends the SAME client_id and succeeds', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('Pas de connexion internet.');
      await h.controller.sendText('Hello');
      h.api.onSend = null;

      final error = await h.controller.retry('c-1');

      expect(error, isNull);
      expect(h.api.sendCalls.map((c) => c.clientId), ['c-1', 'c-1']);
      expect(h.messages, hasLength(1));
      expect(h.messages.single.status, MessageStatus.sent);
      expect(h.messages.single.id, 1000);
    });

    test('retry shows sending again while it is in flight', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('x');
      await h.controller.sendText('Hello');
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;

      final retrying = h.controller.retry('c-1');
      await pumpEventQueue();
      expect(h.messages.single.status, MessageStatus.sending);

      gate.complete(h.api.echo(h.api.sendCalls.last));
      await retrying;
    });

    test('a second failure keeps it failed and returns the error again', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('Le serveur est indisponible, réessayez.');
      await h.controller.sendText('Hello');
      final error = await h.controller.retry('c-1');
      expect(error, 'Le serveur est indisponible, réessayez.');
      expect(h.messages.single.status, MessageStatus.failed);
    });

    test('the HTTP call fails but the WebSocket echo already arrived: it is NOT failed', () async {
      final h = Harness();
      await h.load();
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;
      final done = h.controller.sendText('Hello');
      await pumpEventQueue();

      h.realtime.emit(ChatMessageArrived(h.api.echo(h.api.sendCalls.single)));
      gate.completeError(const ChatApiException('Délai dépassé, vérifiez votre connexion.'));
      await done;

      expect(h.messages.single.status, MessageStatus.sent);
      expect(h.messages.single.id, 1000);
    });

    test('discard removes a failed message and forgets it', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('x');
      await h.controller.sendText('Hello');

      h.controller.discard('c-1');

      expect(h.messages, isEmpty);
      expect(await h.controller.retry('c-1'), isNotNull);
      expect(h.api.sendCalls, hasLength(1));
    });

    test('discard never removes a message that is not failed', () async {
      final h = Harness();
      await h.load();
      await h.controller.sendText('Hello');
      h.controller.discard('c-1');
      expect(h.messages, hasLength(1));
    });

    test('two messages keep their order and get their own client_id', () async {
      final h = Harness();
      await h.load();
      await h.controller.sendText('un');
      h.now = clockNow.add(const Duration(seconds: 5));
      h.api.serverNow = () => clockNow.add(const Duration(seconds: 5));
      await h.controller.sendText('deux');

      expect(h.messages.map((m) => m.content), ['un', 'deux']);
      expect(h.api.sendCalls.map((c) => c.clientId), ['c-1', 'c-2']);
    });

    test('replying: the id goes to the server and the bubble quotes the original', () async {
      final h = Harness();
      await h.load([serverMessage(id: 5, senderId: other, content: 'On se voit jeudi ?')]);
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;

      final done = h.controller.sendText('Oui !', replyToId: 5);
      await pumpEventQueue();

      expect(h.api.sendCalls.single.replyToId, 5);
      final reply = h.messages.last.replyTo!;
      expect(reply.id, 5);
      expect(reply.senderId, other);
      expect(reply.preview, 'On se voit jeudi ?');
      gate.complete(h.api.echo(h.api.sendCalls.single));
      await done;
    });

    test('a long quoted text is cut to 80 characters', () async {
      final h = Harness();
      await h.load([serverMessage(id: 5, senderId: other, content: 'a' * 200)]);
      h.api.onSend = (call) => Completer<ChatMessage>().future;
      unawaited(h.controller.sendText('ok', replyToId: 5));
      await pumpEventQueue();
      expect(h.messages.last.replyTo!.preview.length, 80);
    });
  });

  group('photos', () {
    test('each photo is uploaded, then ONE message carries all media_ids and the caption', () async {
      final h = Harness();
      await h.load();
      final a = bytes(3);
      final b = bytes(4);
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;

      final done = h.controller.sendPhotos([a, b], caption: 'Regarde');
      await pumpEventQueue();

      final pending = h.messages.single;
      expect(pending.type, ChatMessageType.photo);
      expect(pending.status, MessageStatus.sending);
      expect(pending.localMedia, [a, b]);
      expect(pending.content, 'Regarde');

      expect(h.api.uploadCalls, hasLength(2));
      expect(h.api.uploadCalls.every((u) => u.kind == MediaKind.photo), isTrue);
      expect(h.api.uploadCalls.map((u) => u.bytes), [a, b]);
      final call = h.api.sendCalls.single;
      expect(call.type, ChatMessageType.photo);
      expect(call.mediaIds, [500, 501]);
      expect(call.content, 'Regarde');

      gate.complete(h.api.echo(call));
      expect(await done, isNull);
      expect(h.messages.single.media.map((m) => m.id), [500, 501]);
      expect(h.messages.single.status, MessageStatus.sent);
    });

    test('media_ids follow the order of the photos, even if uploads finish out of order', () async {
      final h = Harness();
      await h.load();
      final first = Completer<ChatMedia>();
      var n = 0;
      h.api.onUpload = (call) {
        n++;
        if (n == 1) return first.future;
        return Future.value(const ChatMedia(id: 22, url: 'u2'));
      };
      final done = h.controller.sendPhotos([bytes(1), bytes(2)]);
      await pumpEventQueue();
      first.complete(const ChatMedia(id: 11, url: 'u1'));
      await done;
      expect(h.api.sendCalls.single.mediaIds, [11, 22]);
    });

    test('an upload failure marks the message failed; retry uploads only what is missing', () async {
      final h = Harness();
      await h.load();
      var failSecond = true;
      var id = 600;
      h.api.onUpload = (call) async {
        if (call.bytes.length == 2 && failSecond) throw const ChatApiException('Fichier trop volumineux.');
        return ChatMedia(id: id++, url: 'u');
      };

      final error = await h.controller.sendPhotos([bytes(1), bytes(2)]);

      expect(error, 'Fichier trop volumineux.');
      expect(h.messages.single.status, MessageStatus.failed);
      expect(h.api.sendCalls, isEmpty);
      final uploadsBefore = h.api.uploadCalls.length;

      failSecond = false;
      expect(await h.controller.retry('c-1'), isNull);

      expect(h.api.uploadCalls.length, uploadsBefore + 1, reason: 'the first photo is not uploaded twice');
      expect(h.api.uploadCalls.last.bytes.length, 2);
      expect(h.api.sendCalls.single.mediaIds, [600, 601]);
      expect(h.messages.single.status, MessageStatus.sent);
    });

    test('uploads done, send failed: retry does not upload again', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) async => throw const ChatApiException('x');
      await h.controller.sendPhotos([bytes(1)]);
      expect(h.api.uploadCalls, hasLength(1));

      h.api.onSend = null;
      await h.controller.retry('c-1');

      expect(h.api.uploadCalls, hasLength(1));
      expect(h.api.sendCalls, hasLength(2));
      expect(h.api.sendCalls.last.mediaIds, h.api.sendCalls.first.mediaIds);
    });

    test('more than ten photos are refused before anything is sent', () async {
      final h = Harness();
      await h.load();
      final error = await h.controller.sendPhotos([for (var i = 0; i < 11; i++) bytes(1)]);
      expect(error, 'Dix photos au maximum par message.');
      expect(h.messages, isEmpty);
      expect(h.api.uploadCalls, isEmpty);
    });

    test('no photo, nothing to do', () async {
      final h = Harness();
      await h.load();
      expect(await h.controller.sendPhotos(const []), isNull);
      expect(h.messages, isEmpty);
    });
  });

  group('voice', () {
    test('uploads the clip with its duration and waveform, then sends a voice message', () async {
      final h = Harness();
      await h.load();
      final aac = bytes(10);
      final waveform = [for (var i = 0; i < 48; i++) i];
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;

      final done = h.controller.sendVoice(aac, durationMs: 4200, waveform: waveform);
      await pumpEventQueue();

      final pending = h.messages.single;
      expect(pending.type, ChatMessageType.voice);
      expect(pending.status, MessageStatus.sending);
      expect(pending.voice!.durationMs, 4200);
      expect(pending.voice!.waveform, waveform);
      expect(pending.voice!.url, startsWith('data:audio/mp4;base64,'));
      expect(base64Decode(pending.voice!.url.split(',').last), aac);

      final upload = h.api.uploadCalls.single;
      expect(upload.kind, MediaKind.voice);
      expect(upload.durationMs, 4200);
      expect(upload.waveform, waveform);
      final call = h.api.sendCalls.single;
      expect(call.type, ChatMessageType.voice);
      expect(call.mediaIds, [500]);
      expect(call.content, '');

      gate.complete(h.api.echo(call));
      expect(await done, isNull);
      expect(h.messages.single.voice!.url, 'https://cdn.example.com/v');
      expect(h.messages.single.status, MessageStatus.sent);
    });

    test('a failed voice upload can be retried or discarded', () async {
      final h = Harness();
      await h.load();
      h.api.onUpload = (call) async => throw const ChatApiException('Pas de connexion internet.');
      expect(await h.controller.sendVoice(bytes(5), durationMs: 2000, waveform: List.filled(48, 3)), 'Pas de connexion internet.');
      expect(h.messages.single.status, MessageStatus.failed);

      h.api.onUpload = null;
      expect(await h.controller.retry('c-1'), isNull);
      expect(h.messages.single.status, MessageStatus.sent);
      expect(h.api.sendCalls.single.mediaIds, [500]);
    });

    test('a voice reply carries reply_to_id', () async {
      final h = Harness();
      await h.load([serverMessage(id: 5, senderId: other)]);
      await h.controller.sendVoice(bytes(5), durationMs: 2000, waveform: List.filled(48, 3), replyToId: 5);
      expect(h.api.sendCalls.single.replyToId, 5);
    });
  });

  group('messages from the other side', () {
    test('a chat:message is appended, once, and ends the typing indicator', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      h.realtime.emit(const ChatTypingChanged(conversationId: conversation, userId: other, isTyping: true));
      expect(h.state.otherIsTyping, isTrue);

      final incoming = serverMessage(id: 2, content: 'Coucou', createdAt: '2026-10-22T20:30:00.000Z');
      h.realtime.emit(ChatMessageArrived(incoming));
      h.realtime.emit(ChatMessageArrived(incoming));

      expect(h.messages.map((m) => m.id), [1, 2]);
      expect(h.state.otherIsTyping, isFalse);
    });

    test('a message for another conversation is ignored', () async {
      final h = Harness();
      await h.load();
      h.realtime.emit(ChatMessageArrived(ChatMessage.fromJson(messageJson(id: 9, conversationId: 99))));
      expect(h.messages, isEmpty);
    });

    test('chat:updated replaces the message (link preview arrived)', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, content: 'https://example.com')]);
      expect(h.messages.single.linkPreview, isNull);

      h.realtime.emit(ChatMessageUpdated(serverMessage(id: 1, content: 'https://example.com', linkPreview: {
        'url': 'https://example.com',
        'title': 'Exemple',
        'description': null,
        'image_url': null,
        'site_name': 'Example',
      })));

      expect(h.messages.single.linkPreview!.title, 'Exemple');
      expect(h.messages, hasLength(1));
    });

    test('chat:updated for an unsent message shows it as removed', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      h.realtime.emit(ChatMessageUpdated(serverMessage(id: 1, content: '', unsent: true)));
      expect(h.messages.single.unsent, isTrue);
      expect(h.messages.single.content, '');
    });

    test('chat:updated for a message we never loaded does not invent it', () async {
      final h = Harness();
      await h.load([serverMessage(id: 10)]);
      h.realtime.emit(ChatMessageUpdated(serverMessage(id: 3)));
      expect(h.messages.map((m) => m.id), [10]);
    });

    test('messages stay ordered by time when they arrive late', () async {
      final h = Harness();
      await h.load([serverMessage(id: 2, createdAt: '2026-10-22T20:10:00.000Z')]);
      h.realtime.emit(ChatMessageArrived(serverMessage(id: 3, createdAt: '2026-10-22T20:20:00.000Z')));
      h.realtime.emit(ChatMessageArrived(serverMessage(id: 1, createdAt: '2026-10-22T20:05:00.000Z')));
      expect(h.messages.map((m) => m.id), [1, 2, 3]);
    });

    test('a message from the other device of mine (echo without local copy) is added', () async {
      final h = Harness();
      await h.load();
      h.realtime.emit(ChatMessageArrived(serverMessage(id: 8, senderId: me, clientId: 'c-other-device')));
      expect(h.messages.single.senderId, me);
    });
  });

  group('typing indicator of the other side', () {
    test('on, then off by itself after 6 seconds', () {
      fakeAsync((async) {
        final h = Harness();
        h.load();
        async.flushMicrotasks();

        h.realtime.emit(const ChatTypingChanged(conversationId: conversation, userId: other, isTyping: true));
        expect(h.state.otherIsTyping, isTrue);
        async.elapse(const Duration(seconds: 5));
        expect(h.state.otherIsTyping, isTrue);
        async.elapse(const Duration(seconds: 2));
        expect(h.state.otherIsTyping, isFalse);
        h.dispose();
      });
    });

    test('each typing event restarts the 6 seconds', () {
      fakeAsync((async) {
        final h = Harness();
        h.load();
        async.flushMicrotasks();
        const on = ChatTypingChanged(conversationId: conversation, userId: other, isTyping: true);

        h.realtime.emit(on);
        async.elapse(const Duration(seconds: 4));
        h.realtime.emit(on);
        async.elapse(const Duration(seconds: 4));
        expect(h.state.otherIsTyping, isTrue);
        async.elapse(const Duration(seconds: 3));
        expect(h.state.otherIsTyping, isFalse);
        h.dispose();
      });
    });

    test('an explicit stop turns it off at once', () async {
      final h = Harness();
      await h.load();
      h.realtime.emit(const ChatTypingChanged(conversationId: conversation, userId: other, isTyping: true));
      h.realtime.emit(const ChatTypingChanged(conversationId: conversation, userId: other, isTyping: false));
      expect(h.state.otherIsTyping, isFalse);
    });

    test('my own typing echo and other conversations are ignored', () async {
      final h = Harness();
      await h.load();
      h.realtime.emit(const ChatTypingChanged(conversationId: conversation, userId: me, isTyping: true));
      h.realtime.emit(const ChatTypingChanged(conversationId: 99, userId: other, isTyping: true));
      expect(h.state.otherIsTyping, isFalse);
    });
  });

  group('my typing', () {
    test('true at the first keystroke only, false after 3 seconds of silence', () {
      fakeAsync((async) {
        final h = Harness();
        h.load();
        async.flushMicrotasks();

        h.controller.setTyping(true);
        expect(h.realtime.typingSent, [true]);
        async.elapse(const Duration(seconds: 1));
        h.controller.setTyping(true);
        h.controller.setTyping(true);
        expect(h.realtime.typingSent, [true]);

        async.elapse(const Duration(seconds: 2, milliseconds: 900));
        expect(h.realtime.typingSent, [true], reason: 'still within 3 s of the last keystroke');
        async.elapse(const Duration(milliseconds: 200));
        expect(h.realtime.typingSent, [true, false]);

        async.elapse(const Duration(seconds: 30));
        expect(h.realtime.typingSent, [true, false]);
        h.dispose();
      });
    });

    test('typing for a long time refreshes true so the other side does not time out', () {
      fakeAsync((async) {
        final h = Harness();
        h.load();
        async.flushMicrotasks();

        for (var i = 0; i < 10; i++) {
          h.controller.setTyping(true);
          async.elapse(const Duration(seconds: 1));
        }
        final trues = h.realtime.typingSent.where((t) => t).length;
        expect(trues, greaterThanOrEqualTo(2));
        expect(h.realtime.typingSent.where((t) => !t), isEmpty);
        async.elapse(const Duration(seconds: 3));
        expect(h.realtime.typingSent.last, isFalse);
        expect(h.realtime.typingSent.where((t) => !t), hasLength(1));
        h.dispose();
      });
    });

    test('an explicit false (field emptied) is sent at once, once', () {
      fakeAsync((async) {
        final h = Harness();
        h.load();
        async.flushMicrotasks();
        h.controller.setTyping(true);
        h.controller.setTyping(false);
        h.controller.setTyping(false);
        expect(h.realtime.typingSent, [true, false]);
        async.elapse(const Duration(seconds: 30));
        expect(h.realtime.typingSent, [true, false]);
        h.dispose();
      });
    });

    test('false when never typing sends nothing', () async {
      final h = Harness();
      await h.load();
      h.controller.setTyping(false);
      expect(h.realtime.typingSent, isEmpty);
    });

    test('sending a message ends my typing', () async {
      final h = Harness();
      await h.load();
      h.controller.setTyping(true);
      await h.controller.sendText('hop');
      expect(h.realtime.typingSent, [true, false]);
    });

    test('leaving the screen while typing says false', () async {
      final h = Harness();
      await h.load();
      h.controller.setTyping(true);
      h.controller.dispose();
      expect(h.realtime.typingSent, [true, false]);
    });
  });

  group('read receipts', () {
    test('markReadUpTo only calls the server when the id grows', () async {
      final h = Harness();
      await h.load();

      h.controller.markReadUpTo(812);
      h.controller.markReadUpTo(812);
      h.controller.markReadUpTo(700);
      h.controller.markReadUpTo(0);
      h.controller.markReadUpTo(-3);
      await pumpEventQueue();
      expect(h.api.readCalls, [812]);

      h.controller.markReadUpTo(900);
      await pumpEventQueue();
      expect(h.api.readCalls, [812, 900]);
    });

    test('a failed call can be retried with the same id later', () async {
      final h = Harness();
      await h.load();
      h.api.onRead = (id) async => throw const ChatApiException('Pas de connexion internet.');
      h.controller.markReadUpTo(812);
      await pumpEventQueue();

      h.api.onRead = null;
      h.controller.markReadUpTo(812);
      await pumpEventQueue();
      expect(h.api.readCalls, [812, 812]);
    });

    test('chat:read from the other turns my messages up to that id into Vu', () async {
      final h = Harness();
      await h.load([
        serverMessage(id: 4, senderId: me),
        serverMessage(id: 3, senderId: other),
        serverMessage(id: 2, senderId: me),
        serverMessage(id: 1, senderId: me),
      ]);

      h.realtime.emit(ChatReadUpTo(
        conversationId: conversation,
        userId: other,
        upToId: 2,
        readAt: DateTime.utc(2026, 10, 22, 20, 47),
      ));

      MessageStatus status(int id) => h.messages.firstWhere((m) => m.id == id).status;
      expect(status(1), MessageStatus.seen);
      expect(status(2), MessageStatus.seen);
      expect(h.messages.firstWhere((m) => m.id == 2).readAt, DateTime.utc(2026, 10, 22, 20, 47));
      expect(status(3), MessageStatus.sent, reason: 'their own message is not "seen" by them');
      expect(status(4), MessageStatus.sent, reason: 'beyond up_to_id');
    });

    test('chat:read from myself or another conversation changes nothing', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: me)]);
      final at = DateTime.utc(2026, 10, 22, 20, 47);
      h.realtime.emit(ChatReadUpTo(conversationId: conversation, userId: me, upToId: 1, readAt: at));
      h.realtime.emit(ChatReadUpTo(conversationId: 99, userId: other, upToId: 1, readAt: at));
      expect(h.messages.single.status, MessageStatus.sent);
    });

    test('a pending message is not marked seen by a read event', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) => Completer<ChatMessage>().future;
      unawaited(h.controller.sendText('en cours'));
      await pumpEventQueue();
      h.realtime.emit(ChatReadUpTo(
        conversationId: conversation,
        userId: other,
        upToId: 999999,
        readAt: DateTime.utc(2026, 10, 22, 20, 47),
      ));
      expect(h.messages.single.status, MessageStatus.sending);
    });
  });

  group('reactions', () {
    List<Map<String, dynamic>> reacts(Map<String, List<int>> by) =>
        [for (final e in by.entries) {'emoji': e.key, 'user_ids': e.value}];

    test('the reaction shows at once and the server answer replaces it', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: other)]);
      final gate = Completer<List<Reaction>>();
      h.api.onReaction = (id, emoji) => gate.future;

      final done = h.controller.toggleReaction(1, '❤️');
      await pumpEventQueue();
      expect(h.messages.single.reactions.single.emoji, '❤️');
      expect(h.messages.single.reactions.single.userIds, [me]);

      gate.complete(const [
        Reaction(emoji: '❤️', userIds: [other, me]),
      ]);
      expect(await done, isNull);
      expect(h.messages.single.reactions.single.userIds, [other, me]);
      expect(h.api.reactionCalls.single, (messageId: 1, emoji: '❤️'));
    });

    test('toggling my own reaction again removes it', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, reactions: reacts({'👍': [me, other]}))]);
      h.api.onReaction = (id, emoji) async => const [Reaction(emoji: '👍', userIds: [other])];

      final done = h.controller.toggleReaction(1, '👍');
      await pumpEventQueue();
      expect(h.messages.single.reactions.single.userIds, [other]);
      await done;
    });

    test('removing the only reaction leaves no empty entry', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, reactions: reacts({'👍': [me]}))]);
      final gate = Completer<List<Reaction>>();
      h.api.onReaction = (id, emoji) => gate.future;
      final done = h.controller.toggleReaction(1, '👍');
      await pumpEventQueue();
      expect(h.messages.single.reactions, isEmpty);
      gate.complete(const []);
      await done;
    });

    test('one reaction per member: another emoji replaces mine', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, reactions: reacts({'👍': [me, other], '😂': [other]}))]);
      final gate = Completer<List<Reaction>>();
      h.api.onReaction = (id, emoji) => gate.future;

      final done = h.controller.toggleReaction(1, '😂');
      await pumpEventQueue();

      final byEmoji = {for (final r in h.messages.single.reactions) r.emoji: r.userIds};
      expect(byEmoji, {'👍': [other], '😂': [other, me]});
      gate.complete(const [
        Reaction(emoji: '👍', userIds: [other]),
        Reaction(emoji: '😂', userIds: [other, me]),
      ]);
      await done;
    });

    test('a failure puts the previous reactions back and returns the error', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, reactions: reacts({'👍': [other]}))]);
      h.api.onReaction = (id, emoji) async => throw const ChatApiException('Pas de connexion internet.');

      final error = await h.controller.toggleReaction(1, '❤️');

      expect(error, 'Pas de connexion internet.');
      final byEmoji = {for (final r in h.messages.single.reactions) r.emoji: r.userIds};
      expect(byEmoji, {'👍': [other]});
    });

    test('an emoji outside the six allowed ones is refused without a call', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      expect(await h.controller.toggleReaction(1, '🦄'), 'Réaction indisponible.');
      expect(h.api.reactionCalls, isEmpty);
    });

    test('a message that is not sent yet cannot be reacted to', () async {
      final h = Harness();
      await h.load();
      h.api.onSend = (call) => Completer<ChatMessage>().future;
      unawaited(h.controller.sendText('en cours'));
      await pumpEventQueue();
      expect(await h.controller.toggleReaction(h.messages.single.id, '❤️'), isNotNull);
      expect(h.api.reactionCalls, isEmpty);
    });

    test('unknown message', () async {
      final h = Harness();
      await h.load();
      expect(await h.controller.toggleReaction(404, '❤️'), isNotNull);
      expect(h.api.reactionCalls, isEmpty);
    });
  });

  group('unsend', () {
    test('the message turns into "Message retiré" at once and stays so on success', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: me, createdAt: '2026-10-22T20:55:00.000Z')]);
      final gate = Completer<ChatMessage?>();
      h.api.onUnsend = (id) => gate.future;

      final done = h.controller.unsend(1);
      await pumpEventQueue();
      expect(h.messages.single.unsent, isTrue);
      expect(h.messages.single.content, '');

      gate.complete(null);
      expect(await done, isNull);
      expect(h.messages.single.unsent, isTrue);
      expect(h.api.unsendCalls, [1]);
    });

    test('a failure brings the message back', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: me, content: 'Bonjour', createdAt: '2026-10-22T20:55:00.000Z')]);
      h.api.onUnsend = (id) async => throw const ChatApiException('Ce message ne peut plus être retiré.');

      final error = await h.controller.unsend(1);

      expect(error, 'Ce message ne peut plus être retiré.');
      expect(h.messages.single.unsent, isFalse);
      expect(h.messages.single.content, 'Bonjour');
    });

    test('only my own messages', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: other, createdAt: '2026-10-22T20:55:00.000Z')]);
      expect(await h.controller.unsend(1), isNotNull);
      expect(h.api.unsendCalls, isEmpty);
      expect(h.messages.single.unsent, isFalse);
    });

    test('not after 15 minutes: refused without calling the server', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: me, createdAt: '2026-10-22T20:44:00.000Z')]);
      expect(await h.controller.unsend(1), 'Ce message ne peut plus être retiré.');
      expect(h.api.unsendCalls, isEmpty);
    });

    test('exactly inside the window still goes through', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1, senderId: me, createdAt: '2026-10-22T20:45:30.000Z')]);
      expect(await h.controller.unsend(1), isNull);
      expect(h.api.unsendCalls, [1]);
    });
  });

  group('report', () {
    test('sends the reason', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      expect(await h.controller.report(1, 'spam'), isNull);
      expect(h.api.reportCalls.single, (messageId: 1, reason: 'spam'));
    });

    test('returns the French error', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      h.api.onReport = (id, reason) async => throw const ChatApiException('Trop d’envois, patientez un instant.');
      expect(await h.controller.report(1, 'spam'), 'Trop d’envois, patientez un instant.');
    });
  });

  group('socket drops', () {
    test('after a reconnection the missed messages are fetched and merged', () async {
      final h = Harness();
      await h.load([serverMessage(id: 1)]);
      h.api.onGet = (b, l) async => MessagePage(messages: [serverMessage(id: 2), serverMessage(id: 1)], hasMore: false);

      h.realtime.emit(const ChatReconnected());
      await pumpEventQueue();

      expect(h.messages.map((m) => m.id), [1, 2]);
      expect(h.state.loading, isFalse);
    });
  });

  group('lifetime', () {
    test('listens to the realtime source for its conversation only while alive', () async {
      final h = Harness();
      expect(h.realtime.hasListeners, isTrue);
      h.controller.dispose();
      expect(h.realtime.hasListeners, isFalse);
    });

    test('an answer arriving after dispose does not throw', () async {
      final h = Harness();
      await h.load();
      final gate = Completer<ChatMessage>();
      h.api.onSend = (call) => gate.future;
      final done = h.controller.sendText('tard');
      await pumpEventQueue();
      h.controller.dispose();
      gate.complete(h.api.echo(h.api.sendCalls.single));
      await done;
    });

    test('actions wait for the user id when called before load', () async {
      final h = Harness();
      await h.controller.sendText('tôt');
      expect(h.messages.single.senderId, me);
    });
  });
}
