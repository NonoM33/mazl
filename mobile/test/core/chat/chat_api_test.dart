import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/models/chat_message.dart';

// JSON below is copied from docs/chat/CONTRAT.md §1/§2, not from the parser.
const textJson = {
  'id': 812,
  'conversation_id': 40,
  'sender_id': 7,
  'client_id': 'c-5f2a',
  'type': 'text',
  'content': 'Salut !',
  'media': <Object>[],
  'voice': null,
  'reply_to': {'id': 799, 'sender_id': 45, 'type': 'text', 'preview': 'On se voit jeudi ?'},
  'reactions': [
    {'emoji': '❤️', 'user_ids': [45]},
  ],
  'link_preview': {
    'url': 'https://example.com/a',
    'title': 'Titre',
    'description': 'Desc',
    'image_url': null,
    'site_name': 'Example',
  },
  'created_at': '2026-10-22T20:45:00.000Z',
  'read_at': null,
  'unsent': false,
};

const photoJson = {
  'id': 813,
  'conversation_id': 40,
  'sender_id': 45,
  'client_id': null,
  'type': 'photo',
  'content': 'Regarde',
  'media': [
    {'id': 31, 'kind': 'photo', 'url': 'https://cdn.example.com/p.jpg?sig=x', 'width': 1200, 'height': 1600},
  ],
  'voice': null,
  'reply_to': null,
  'reactions': <Object>[],
  'link_preview': null,
  'created_at': '2026-10-22T20:46:00.000Z',
  'read_at': '2026-10-22T20:47:00.000Z',
  'unsent': false,
};

const voiceJson = {
  'id': 814,
  'conversation_id': 40,
  'sender_id': 45,
  'client_id': null,
  'type': 'voice',
  'content': '',
  'media': <Object>[],
  'voice': {
    'id': 32,
    'url': 'https://cdn.example.com/v.m4a?sig=y',
    'duration_ms': 8300,
    'waveform': [0, 12, 40],
  },
  'reply_to': null,
  'reactions': <Object>[],
  'link_preview': null,
  'created_at': '2026-10-22T20:48:00.000Z',
  'read_at': null,
  'unsent': false,
};

http.Response json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class Recorded {
  late http.Request request;
  Map<String, dynamic> get body => jsonDecode(request.body) as Map<String, dynamic>;
}

HttpChatApi apiWith(Future<http.Response> Function(http.Request) handler, {String? token = 'jwt-123'}) =>
    HttpChatApi(
      baseUrl: 'https://api.example.com',
      token: () => token,
      clientFactory: () => MockClient(handler),
    );

void main() {
  group('getMessages', () {
    test('first page: no cursor, limit 30, bearer token', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'messages': [textJson], 'has_more': true});
      });

      final page = await api.getMessages(40);

      expect(seen.request.method, 'GET');
      expect(seen.request.url.toString(), 'https://api.example.com/api/conversations/40/messages?limit=30');
      expect(seen.request.headers['Authorization'], 'Bearer jwt-123');
      expect(page.hasMore, isTrue);
      expect(page.messages.single.id, 812);
    });

    test('older page uses the before cursor and a custom limit', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'messages': <Object>[], 'has_more': false});
      });

      final page = await api.getMessages(40, before: 812, limit: 20);

      expect(seen.request.url.queryParameters, {'before': '812', 'limit': '20'});
      expect(page.hasMore, isFalse);
      expect(page.messages, isEmpty);
    });

    test('decodes text, photo and voice messages from the contract shapes', () async {
      final api = apiWith((r) async => json({
            'success': true,
            'messages': [voiceJson, photoJson, textJson],
            'has_more': false,
          }));

      final messages = (await api.getMessages(40)).messages;

      final voice = messages[0];
      expect(voice.type, ChatMessageType.voice);
      expect(voice.voice!.durationMs, 8300);
      expect(voice.voice!.waveform, [0, 12, 40]);
      expect(voice.voice!.url, 'https://cdn.example.com/v.m4a?sig=y');

      final photo = messages[1];
      expect(photo.type, ChatMessageType.photo);
      expect(photo.content, 'Regarde');
      expect(photo.media.single.width, 1200);
      expect(photo.readAt, DateTime.utc(2026, 10, 22, 20, 47));
      expect(photo.status, MessageStatus.seen);

      final text = messages[2];
      expect(text.clientId, 'c-5f2a');
      expect(text.senderId, 7);
      expect(text.conversationId, 40);
      expect(text.replyTo!.id, 799);
      expect(text.replyTo!.preview, 'On se voit jeudi ?');
      expect(text.reactions.single.emoji, '❤️');
      expect(text.reactions.single.userIds, [45]);
      expect(text.linkPreview!.siteName, 'Example');
      expect(text.linkPreview!.imageUrl, isNull);
      expect(text.status, MessageStatus.sent);
    });

    test('without a token no Authorization header is sent', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'messages': <Object>[], 'has_more': false});
      }, token: null);
      await api.getMessages(1);
      expect(seen.request.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('sendMessage', () {
    test('text: client_id, type and content, nothing else', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'message': textJson});
      });

      final message = await api.sendMessage(40, clientId: 'c-5f2a', type: ChatMessageType.text, content: 'Salut !');

      expect(seen.request.method, 'POST');
      expect(seen.request.url.path, '/api/conversations/40/messages');
      expect(seen.request.headers['Content-Type'], contains('application/json'));
      expect(seen.body, {'client_id': 'c-5f2a', 'type': 'text', 'content': 'Salut !'});
      expect(message.id, 812);
    });

    test('photos: media_ids, caption and reply_to_id', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'message': photoJson});
      });

      await api.sendMessage(
        40,
        clientId: 'c-1',
        type: ChatMessageType.photo,
        content: 'Regarde',
        mediaIds: [31, 32],
        replyToId: 799,
      );

      expect(seen.body, {
        'client_id': 'c-1',
        'type': 'photo',
        'content': 'Regarde',
        'media_ids': [31, 32],
        'reply_to_id': 799,
      });
    });

    test('voice: media_ids with an empty content', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true, 'message': voiceJson});
      });

      final message = await api.sendMessage(40, clientId: 'c-2', type: ChatMessageType.voice, mediaIds: [32]);

      expect(seen.body, {'client_id': 'c-2', 'type': 'voice', 'content': '', 'media_ids': [32]});
      expect(message.voice!.id, 32);
    });
  });

  group('uploadMedia', () {
    Future<(http.Request, String)> capture(
      Future<void> Function(HttpChatApi) call, {
      Map<String, dynamic>? reply,
    }) async {
      late http.Request request;
      final api = apiWith((r) async {
        request = r;
        return json(reply ?? {'success': true, 'media': {'id': 31, 'kind': 'photo', 'url': 'https://cdn.example.com/p?sig=x', 'width': 800, 'height': 600}});
      });
      await call(api);
      return (request, utf8.decode(request.bodyBytes, allowMalformed: true));
    }

    test('photo: multipart POST with file and kind, no voice fields', () async {
      final (request, body) = await capture((api) async {
        final media = await api.uploadMedia(40, bytes: Uint8List.fromList([1, 2, 3]), kind: MediaKind.photo);
        expect(media.id, 31);
        expect(media.width, 800);
      });

      expect(request.method, 'POST');
      expect(request.url.path, '/api/conversations/40/media');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      expect(request.headers['Authorization'], 'Bearer jwt-123');
      expect(body, contains('name="kind"'));
      expect(body, contains('photo'));
      expect(body, contains('name="file"'));
      expect(body, contains('filename="photo.jpg"'));
      expect(body, isNot(contains('duration_ms')));
      expect(body, isNot(contains('waveform')));
    });

    test('voice: kind, duration_ms and the waveform as JSON', () async {
      final (_, body) = await capture((api) async {
        await api.uploadMedia(
          40,
          bytes: Uint8List.fromList([9, 9]),
          kind: MediaKind.voice,
          durationMs: 8300,
          waveform: const [0, 12, 40],
        );
      }, reply: {
        'success': true,
        'media': {'id': 32, 'kind': 'voice', 'url': 'https://cdn.example.com/v?sig=y'},
      });

      expect(body, contains('name="file"'));
      expect(body, contains('filename="voice.m4a"'));
      expect(RegExp(r'name="duration_ms"\r\n\r\n8300\r\n').hasMatch(body), isTrue, reason: body);
      expect(RegExp(r'name="waveform"\r\n\r\n\[0,12,40\]\r\n').hasMatch(body), isTrue, reason: body);
      expect(RegExp(r'name="kind"\r\n\r\nvoice\r\n').hasMatch(body), isTrue, reason: body);
    });
  });

  group('reactions, unsend, read, report', () {
    test('toggleReaction posts the emoji and returns the new reactions', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({
          'success': true,
          'reactions': [
            {'emoji': '😂', 'user_ids': [7, 45]},
          ],
        });
      });

      final reactions = await api.toggleReaction(812, '😂');

      expect(seen.request.method, 'POST');
      expect(seen.request.url.path, '/api/messages/812/reactions');
      expect(seen.body, {'emoji': '😂'});
      expect(reactions.single.userIds, [7, 45]);
    });

    test('unsend posts to /unsend and returns the updated message when given', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({
          'success': true,
          'message': {...textJson, 'content': '', 'unsent': true, 'media': <Object>[], 'link_preview': null},
        });
      });

      final message = await api.unsend(812);

      expect(seen.request.method, 'POST');
      expect(seen.request.url.path, '/api/messages/812/unsend');
      expect(message!.unsent, isTrue);
    });

    test('unsend without a message in the reply returns null', () async {
      final api = apiWith((r) async => json({'success': true}));
      expect(await api.unsend(812), isNull);
    });

    test('markRead is a PUT with up_to_id', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true});
      });

      await api.markRead(40, upToId: 812);

      expect(seen.request.method, 'PUT');
      expect(seen.request.url.path, '/api/conversations/40/read');
      expect(seen.body, {'up_to_id': 812});
    });

    test('report posts the reason', () async {
      final seen = Recorded();
      final api = apiWith((r) async {
        seen.request = r;
        return json({'success': true});
      });

      await api.report(812, 'spam');

      expect(seen.request.url.path, '/api/messages/812/report');
      expect(seen.body, {'reason': 'spam'});
    });
  });

  group('errors become short French messages', () {
    Future<ChatApiException> failing(int status, Future<void> Function(HttpChatApi) call) async {
      final api = apiWith((r) async => json({'success': false, 'error': 'Not found: secret details'}, status));
      try {
        await call(api);
      } on ChatApiException catch (e) {
        return e;
      }
      fail('expected a ChatApiException');
    }

    test('401', () async {
      final e = await failing(401, (a) => a.getMessages(1));
      expect(e.message, 'Session expirée, reconnectez-vous.');
      expect(e.status, 401);
    });

    test('404: the conversation is gone (or never was ours), without saying which', () async {
      final e = await failing(404, (a) => a.getMessages(1));
      expect(e.message, 'Cette conversation n’est plus disponible.');
    });

    test('403 on a write: the pair is blocked (server CONTRAT §0.1)', () async {
      for (final call in <Future<Object?> Function(ChatApi)>[
        (a) => a.sendMessage(1, clientId: 'c', type: ChatMessageType.text, content: 'x'),
        (a) => a.toggleReaction(1, '❤️'),
      ]) {
        final e = await failing(403, call);
        expect(e.message, 'Vous ne pouvez plus écrire dans cette conversation.');
      }
    });

    test('429', () async {
      final e = await failing(429, (a) => a.sendMessage(1, clientId: 'c', type: ChatMessageType.text, content: 'x'));
      expect(e.message, 'Trop d’envois, patientez un instant.');
    });

    test('5xx', () async {
      final e = await failing(503, (a) => a.getMessages(1));
      expect(e.message, 'Le serveur est indisponible, réessayez.');
    });

    test('413 on upload', () async {
      final e = await failing(
        413,
        (a) => a.uploadMedia(1, bytes: Uint8List(1), kind: MediaKind.photo),
      );
      expect(e.message, 'Fichier trop volumineux.');
    });

    test('415 and 422 on upload mean the file was refused', () async {
      for (final status in [400, 415, 422]) {
        final e = await failing(status, (a) => a.uploadMedia(1, bytes: Uint8List(1), kind: MediaKind.voice));
        expect(e.message, 'Fichier refusé, essayez-en un autre.');
      }
    });

    test('unsend refused after 15 minutes', () async {
      for (final status in [403, 409, 422]) {
        final e = await failing(status, (a) => a.unsend(1));
        expect(e.message, 'Ce message ne peut plus être retiré.');
      }
    });

    test('the server error text is never shown', () async {
      final e = await failing(400, (a) => a.sendMessage(1, clientId: 'c', type: ChatMessageType.text, content: 'x'));
      expect(e.message, isNot(contains('secret')));
      expect(e.message, 'Message refusé.');
    });

    test('timeout', () async {
      final api = apiWith((r) async => throw TimeoutException('slow'));
      expect(
        () => api.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Délai dépassé, vérifiez votre connexion.')),
      );
    });

    test('no network', () async {
      final api = apiWith((r) async => throw const SocketException('down'));
      expect(
        () => api.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Pas de connexion internet.')),
      );
      final api2 = apiWith((r) async => throw http.ClientException('down'));
      expect(
        () => api2.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Pas de connexion internet.')),
      );
    });

    test('200 with success false', () async {
      final api = apiWith((r) async => json({'success': false, 'error': 'x'}));
      expect(
        () => api.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Une erreur est survenue.')),
      );
    });

    test('a body that is not the contract shape', () async {
      final api = apiWith((r) async => http.Response('<html>oops</html>', 200));
      expect(
        () => api.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Une erreur est survenue.')),
      );
      final api2 = apiWith((r) async => json({'success': true, 'messages': 'nope'}));
      expect(
        () => api2.getMessages(1),
        throwsA(isA<ChatApiException>().having((e) => e.message, 'message', 'Une erreur est survenue.')),
      );
    });
  });
}
