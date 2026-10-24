import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_fixtures.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/models/chat_message.dart';

/// Rejoue le VRAI décodeur du chat (`ChatMessage.fromJson`) sur chaque réponse
/// de la démo, et vérifie les règles du contrat (docs/chat/CONTRAT.md §1-§5).

typedef _Reply = ({int status, Map<String, dynamic> json});

late DateTime _now;
void _advance(Duration by) => _now = _now.add(by);

_Reply _call(
  String method,
  String path, {
  Map<String, dynamic> body = const {},
  Map<String, String> query = const {},
  List<DemoUpload> files = const [],
}) {
  final reply = DemoRoutes.respond(
    DemoRequest(method, path, query, body, files: files),
  );
  return (
    status: reply.status,
    json: jsonDecode(reply.json) as Map<String, dynamic>,
  );
}

const _mine = DemoFixtures.meId;
const _conv = 101; // avec Noémie (301)
const _other = 301;

ChatMessage _decode(Object? json) =>
    ChatMessage.fromJson(json! as Map<String, dynamic>);

List<ChatMessage> _messages(
  int conversation, {
  Map<String, String> query = const {},
}) {
  final r = _call(
    'GET',
    '/api/conversations/$conversation/messages',
    query: query,
  );
  expect(r.status, 200, reason: '${r.json}');
  return [for (final m in r.json['messages'] as List) _decode(m)];
}

Map<String, dynamic> _send(
  Map<String, dynamic> body, {
  int conversation = _conv,
  int status = 200,
}) {
  final r = _call(
    'POST',
    '/api/conversations/$conversation/messages',
    body: body,
  );
  expect(r.status, status, reason: '${r.json}');
  return r.json;
}

ChatMessage _text(
  String content, {
  int conversation = _conv,
  int? replyTo,
  String? id,
}) {
  final json = _send({
    'client_id': id ?? 'c-${DemoStore.nextId()}',
    'type': 'text',
    'content': content,
    'reply_to_id': ?replyTo,
  }, conversation: conversation);
  return _decode(json['message']);
}

// --- Fichiers d'essai, écrits depuis les formats (pas depuis le code testé) ---

Uint8List _png(int w, int h) {
  final b = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add([0, 0, 0, 13])
    ..add('IHDR'.codeUnits)
    ..add([w >> 24, (w >> 16) & 255, (w >> 8) & 255, w & 255])
    ..add([h >> 24, (h >> 16) & 255, (h >> 8) & 255, h & 255])
    ..add([8, 2, 0, 0, 0, 0, 0, 0, 0]);
  return b.toBytes();
}

Uint8List _jpeg(int w, int h) => Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0,
  16,
  0x4A,
  0x46,
  0x49,
  0x46,
  0,
  1,
  1,
  0,
  0,
  1,
  0,
  1,
  0,
  0,
  0xFF,
  0xC0,
  0,
  17,
  8,
  h >> 8,
  h & 255,
  w >> 8,
  w & 255,
  3,
  1,
  0x22,
  0,
  2,
  0x11,
  1,
  3,
  0x11,
  1,
  0xFF,
  0xD9,
]);

Uint8List _m4a() => Uint8List.fromList([
  0,
  0,
  0,
  0x18,
  ...'ftyp'.codeUnits,
  ...'M4A '.codeUnits,
  0,
  0,
  0,
  0,
  ...'M4A '.codeUnits,
  ...List.filled(64, 7),
]);

Uint8List _heic() => Uint8List.fromList([
  0,
  0,
  0,
  0x18,
  ...'ftyp'.codeUnits,
  ...'heic'.codeUnits,
  0,
  0,
  0,
  0,
  ...'mif1'.codeUnits,
  ...List.filled(64, 7),
]);

List<int> _wave([int v = 40]) => List.filled(48, v);

Map<String, dynamic> _uploadPhoto(Uint8List bytes, {int conversation = _conv}) {
  final r = _call(
    'POST',
    '/api/conversations/$conversation/media',
    body: {'kind': 'photo'},
    files: [DemoUpload('file', 'photo.jpg', bytes)],
  );
  expect(r.status, 200, reason: '${r.json}');
  return r.json['media'] as Map<String, dynamic>;
}

Map<String, dynamic> _uploadVoice({
  int conversation = _conv,
  int duration = 8300,
}) {
  final r = _call(
    'POST',
    '/api/conversations/$conversation/media',
    body: {
      'kind': 'voice',
      'duration_ms': '$duration',
      'waveform': jsonEncode(_wave()),
    },
    files: [DemoUpload('file', 'note.m4a', _m4a())],
  );
  expect(r.status, 200, reason: '${r.json}');
  return r.json['media'] as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DevSession.start();
    _now = DateTime.now();
    DemoStore.clock = () => _now;
  });
  tearDown(() {
    DemoStore.clock = DateTime.now;
    DevSession.stop();
  });

  group('lecture et pagination', () {
    test('les conversations de départ sont à la forme du contrat §1', () {
      for (final id in [101, 102, 103, 104, 105]) {
        final messages = _messages(id);
        expect(messages, isNotEmpty);
        for (final m in messages) {
          expect(m.conversationId, id);
          expect(m.type, ChatMessageType.text);
          expect(m.reactions, isEmpty);
          expect(m.media, isEmpty);
          expect(m.voice, isNull);
          expect(m.replyTo, isNull);
          expect(m.unsent, isFalse);
        }
      }
      final conversations =
          _call('GET', '/api/conversations').json['conversations'] as List;
      final first = conversations.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['id'] == 101,
      );
      expect(_messages(101).first.content, first['lastMessage']);
    });

    test(
      'du plus récent au plus ancien ; mes messages sont lus, ceux non lus de l\'autre non',
      () {
        final messages = _messages(101);
        expect(
          messages.map((m) => m.id).toList(),
          [...messages.map((m) => m.id)]..sort((a, b) => b.compareTo(a)),
        );
        final unread = messages.where(
          (m) => m.senderId == _other && m.readAt == null,
        );
        expect(
          unread,
          hasLength(2),
          reason: 'unreadCount de la conversation 101',
        );
        expect(
          messages
              .where((m) => m.senderId == _mine)
              .every((m) => m.readAt != null),
          isTrue,
        );
      },
    );

    test('before pagine sans trou ni doublon, has_more le dit', () {
      for (var i = 0; i < 35; i++) {
        _text('message $i');
      }
      final first = _call('GET', '/api/conversations/101/messages');
      final firstPage = [
        for (final m in first.json['messages'] as List) _decode(m),
      ];
      expect(firstPage, hasLength(30));
      expect(first.json['has_more'], isTrue);
      expect(firstPage.first.content, 'message 34');

      final second = _call(
        'GET',
        '/api/conversations/101/messages',
        query: {'before': '${firstPage.last.id}', 'limit': '30'},
      );
      final secondPage = [
        for (final m in second.json['messages'] as List) _decode(m),
      ];
      expect(secondPage, hasLength(9), reason: '35 envoyés + 4 de départ - 30');
      expect(second.json['has_more'], isFalse);
      expect(secondPage.first.id, lessThan(firstPage.last.id));
      final all = {
        ...firstPage.map((m) => m.id),
        ...secondPage.map((m) => m.id),
      };
      expect(all, hasLength(39));
    });

    test('limit borne la page ; before invalide rend 400', () {
      expect(_messages(101, query: {'limit': '2'}), hasLength(2));
      final bad = _call(
        'GET',
        '/api/conversations/101/messages',
        query: {'before': 'x'},
      );
      expect(bad.status, 400);
    });
  });

  group('envoi', () {
    test(
      'idempotent sur client_id : un second envoi rend le même message, 200',
      () {
        final a = _send({
          'client_id': 'c-1',
          'type': 'text',
          'content': 'Salut',
        });
        final b = _send({
          'client_id': 'c-1',
          'type': 'text',
          'content': 'Salut',
        });
        expect((b['message'] as Map)['id'], (a['message'] as Map)['id']);
        expect(_messages(101).where((m) => m.clientId == 'c-1'), hasLength(1));
      },
    );

    test('le message porte client_id, type, content et un read_at nul', () {
      final m = _text('Bonjour', id: 'c-42');
      expect(m.clientId, 'c-42');
      expect(m.conversationId, _conv);
      expect(m.senderId, _mine);
      expect(m.type, ChatMessageType.text);
      expect(m.content, 'Bonjour');
      expect(m.readAt, isNull);
    });

    test('l\'ancien envoi sans client_id reste accepté (texte seul)', () {
      final r = _call(
        'POST',
        '/api/conversations/101/messages',
        body: {'content': 'Coucou'},
      );
      expect(r.status, 200);
      expect(_decode(r.json['message']).content, 'Coucou');
    });

    test('refus : texte vide, type inconnu, media_ids sur un texte', () {
      _send({'client_id': 'a', 'type': 'text', 'content': '  '}, status: 400);
      _send({'client_id': 'b', 'type': 'gif', 'content': 'x'}, status: 400);
      final photo = _uploadPhoto(_jpeg(10, 10));
      _send({
        'client_id': 'c',
        'type': 'text',
        'content': 'x',
        'media_ids': [photo['id']],
      }, status: 400);
    });

    test('un lien reçoit son aperçu un peu plus tard', () {
      final m = _text('Regarde https://example.com/page');
      expect(_messages(101).first.linkPreview, isNull);
      _advance(const Duration(seconds: 2));
      final preview = _messages(
        101,
      ).firstWhere((x) => x.id == m.id).linkPreview;
      expect(preview?.url, 'https://example.com/page');
      expect(preview?.title, 'example.com');
    });
  });

  group('médias', () {
    test('une photo JPEG déposée rend ses dimensions et une URI data:', () {
      final media = _uploadPhoto(_jpeg(640, 480));
      expect(media['kind'], 'photo');
      expect(media['width'], 640);
      expect(media['height'], 480);
      expect(media['url'], startsWith('data:image/jpeg;base64,'));
      final decoded = ChatMedia.fromJson(media);
      expect([decoded.width, decoded.height], [640, 480]);
    });

    test('PNG : dimensions lues ; HEIC accepté sans dimensions', () {
      final png = _uploadPhoto(_png(300, 200));
      expect([png['width'], png['height']], [300, 200]);
      expect(png['url'], startsWith('data:image/png;base64,'));
      final heic = _uploadPhoto(_heic());
      expect(heic['width'], isNull);
      expect(heic['url'], startsWith('data:image/heic;base64,'));
    });

    test('les octets décident, pas l\'extension', () {
      final text = _call(
        'POST',
        '/api/conversations/101/media',
        body: {'kind': 'photo'},
        files: [
          DemoUpload(
            'file',
            'photo.jpg',
            Uint8List.fromList(utf8.encode('pas une image')),
          ),
        ],
      );
      expect(text.status, 400);
      final audioAsPhoto = _call(
        'POST',
        '/api/conversations/101/media',
        body: {'kind': 'photo'},
        files: [DemoUpload('file', 'photo.jpg', _m4a())],
      );
      expect(audioAsPhoto.status, 400);
      final imageAsVoice = _call(
        'POST',
        '/api/conversations/101/media',
        body: {'kind': 'voice', 'duration_ms': 1000, 'waveform': _wave()},
        files: [DemoUpload('file', 'note.m4a', _jpeg(5, 5))],
      );
      expect(imageAsVoice.status, 400);
    });

    test(
      'limites : photo > 10 Mo et vocal > 3 Mo rendent 413, vocal > 120 s 400',
      () {
        final bigPhoto = Uint8List(10 * 1024 * 1024 + 1)
          ..setAll(0, _jpeg(10, 10));
        expect(
          _call(
            'POST',
            '/api/conversations/101/media',
            body: {'kind': 'photo'},
            files: [DemoUpload('file', 'a.jpg', bigPhoto)],
          ).status,
          413,
        );
        final bigVoice = Uint8List(3 * 1024 * 1024 + 1)..setAll(0, _m4a());
        expect(
          _call(
            'POST',
            '/api/conversations/101/media',
            body: {'kind': 'voice', 'duration_ms': 1000, 'waveform': _wave()},
            files: [DemoUpload('file', 'a.m4a', bigVoice)],
          ).status,
          413,
        );
        expect(
          _call(
            'POST',
            '/api/conversations/101/media',
            body: {'kind': 'voice', 'duration_ms': 120001, 'waveform': _wave()},
            files: [DemoUpload('file', 'a.m4a', _m4a())],
          ).status,
          400,
        );
        expect(
          _call(
            'POST',
            '/api/conversations/101/media',
            body: {'kind': 'voice', 'duration_ms': 120000, 'waveform': _wave()},
            files: [DemoUpload('file', 'a.m4a', _m4a())],
          ).status,
          200,
        );
      },
    );

    test('kind, fichier ou forme d\'onde invalides : 400', () {
      expect(
        _call(
          'POST',
          '/api/conversations/101/media',
          body: {'kind': 'video'},
          files: [DemoUpload('file', 'a', _jpeg(5, 5))],
        ).status,
        400,
      );
      expect(
        _call(
          'POST',
          '/api/conversations/101/media',
          body: {'kind': 'photo'},
        ).status,
        400,
      );
      for (final waveform in [
        <int>[1, 2, 3],
        List.filled(48, 101),
        List.filled(48, -1),
        'pas du json',
      ]) {
        final r = _call(
          'POST',
          '/api/conversations/101/media',
          body: {'kind': 'voice', 'duration_ms': 1000, 'waveform': waveform},
          files: [DemoUpload('file', 'a.m4a', _m4a())],
        );
        expect(r.status, 400, reason: '$waveform');
      }
    });

    test('photo : un message jusqu\'à 10 photos, légende comprise', () {
      final ids = [
        for (var i = 0; i < 3; i++) _uploadPhoto(_jpeg(40 + i, 30))['id'],
      ];
      final json = _send({
        'client_id': 'p1',
        'type': 'photo',
        'content': 'Ma légende',
        'media_ids': ids,
      });
      final m = _decode(json['message']);
      expect(m.type, ChatMessageType.photo);
      expect(m.content, 'Ma légende');
      expect(m.media.map((x) => x.id), ids);
      expect(m.media.first.width, 40);
      expect(m.voice, isNull);
    });

    test(
      'plus de 10 photos, aucun média, média déjà pris ou d\'une autre conversation : 400',
      () {
        final eleven = [
          for (var i = 0; i < 11; i++) _uploadPhoto(_jpeg(8, 8))['id'],
        ];
        _send({
          'client_id': 'x1',
          'type': 'photo',
          'media_ids': eleven,
        }, status: 400);
        _send({
          'client_id': 'x2',
          'type': 'photo',
          'media_ids': <int>[],
        }, status: 400);
        _send({
          'client_id': 'x3',
          'type': 'photo',
          'media_ids': [999999],
        }, status: 400);

        final one = _uploadPhoto(_jpeg(8, 8))['id'];
        _send({
          'client_id': 'x4',
          'type': 'photo',
          'media_ids': [one],
        });
        _send({
          'client_id': 'x5',
          'type': 'photo',
          'media_ids': [one],
        }, status: 400);

        final elsewhere = _uploadPhoto(_jpeg(8, 8), conversation: 102)['id'];
        _send({
          'client_id': 'x6',
          'type': 'photo',
          'media_ids': [elsewhere],
        }, status: 400);
      },
    );

    test('un média orphelin depuis plus de 24 h est purgé', () {
      final id = _uploadPhoto(_jpeg(8, 8))['id'];
      _advance(const Duration(hours: 24, minutes: 1));
      _send({
        'client_id': 'late',
        'type': 'photo',
        'media_ids': [id],
      }, status: 400);
    });

    test(
      'vocal : un seul vocal, rendu avec durée et forme d\'onde, content vide',
      () {
        final media = _uploadVoice();
        expect(media['url'], startsWith('data:audio/mp4;base64,'));
        final json = _send({
          'client_id': 'v1',
          'type': 'voice',
          'content': 'ignoré',
          'media_ids': [media['id']],
        });
        final m = _decode(json['message']);
        expect(m.type, ChatMessageType.voice);
        expect(m.content, '');
        expect(m.voice?.durationMs, 8300);
        expect(m.voice?.waveform, hasLength(48));
        expect(m.voice?.url, startsWith('data:audio/mp4;base64,'));
        expect(m.media, isEmpty);

        final photo = _uploadPhoto(_jpeg(8, 8))['id'];
        _send({
          'client_id': 'v2',
          'type': 'voice',
          'media_ids': [photo],
        }, status: 400);
        final two = [_uploadVoice()['id'], _uploadVoice()['id']];
        _send({
          'client_id': 'v3',
          'type': 'voice',
          'media_ids': two,
        }, status: 400);
      },
    );

    test(
      'un envoi multipart passe par le vrai DemoHttpClient, octets compris',
      () async {
        final client = DemoHttpClient(
          MockClient((r) async => fail('Réseau réel joint : ${r.url}')),
          latency: Duration.zero,
        );
        final request =
            http.MultipartRequest(
                'POST',
                Uri.parse(
                  'https://api.example.com/api/conversations/101/media',
                ),
              )
              ..fields['kind'] = 'photo'
              ..files.add(
                http.MultipartFile.fromBytes(
                  'file',
                  _png(120, 90),
                  filename: 'p.png',
                ),
              );
        final response = await http.Response.fromStream(
          await client.send(request),
        );
        expect(response.statusCode, 200);
        final media =
            (jsonDecode(response.body) as Map<String, dynamic>)['media']
                as Map<String, dynamic>;
        expect([media['width'], media['height']], [120, 90]);
        expect(
          base64Decode((media['url'] as String).split(',').last),
          _png(120, 90),
        );

        final voice =
            http.MultipartRequest(
                'POST',
                Uri.parse(
                  'https://api.example.com/api/conversations/101/media',
                ),
              )
              ..fields['kind'] = 'voice'
              ..fields['duration_ms'] = '4200'
              ..fields['waveform'] = jsonEncode(_wave(10))
              ..files.add(
                http.MultipartFile.fromBytes('file', _m4a(), filename: 'n.m4a'),
              );
        final voiceResponse = await http.Response.fromStream(
          await client.send(voice),
        );
        expect(voiceResponse.statusCode, 200);
        expect(
          VoiceNote.fromJson({
            ...((jsonDecode(voiceResponse.body)
                    as Map<String, dynamic>)['media']
                as Map<String, dynamic>),
          }).durationMs,
          4200,
        );
      },
    );
  });

  group('réponses (reply_to)', () {
    test('aperçu d\'un texte, tronqué à 80 caractères', () {
      final long = _text('x' * 200);
      final reply = _text('Réponse', replyTo: long.id);
      expect(reply.replyTo?.id, long.id);
      expect(reply.replyTo?.senderId, _mine);
      expect(reply.replyTo?.type, ChatMessageType.text);
      expect(reply.replyTo!.preview.runes.length, lessThanOrEqualTo(80));
      expect(reply.replyTo!.preview, startsWith('xxxxxxxx'));

      final short = _text('On se voit jeudi ?');
      expect(
        _text('Oui', replyTo: short.id).replyTo?.preview,
        'On se voit jeudi ?',
      );
    });

    test(
      '« Photo » et « Message vocal » ; « Message retiré » après un retrait',
      () {
        final photo = _decode(
          _send({
            'client_id': 'ph',
            'type': 'photo',
            'content': 'une légende',
            'media_ids': [_uploadPhoto(_jpeg(8, 8))['id']],
          })['message'],
        );
        expect(_text('a', replyTo: photo.id).replyTo?.preview, 'Photo');
        expect(
          _text('a', replyTo: photo.id).replyTo?.type,
          ChatMessageType.photo,
        );

        final voice = _decode(
          _send({
            'client_id': 'vo',
            'type': 'voice',
            'media_ids': [_uploadVoice()['id']],
          })['message'],
        );
        final answer = _text('b', replyTo: voice.id);
        expect(answer.replyTo?.preview, 'Message vocal');

        _call('POST', '/api/messages/${voice.id}/unsend');
        final reread = _messages(101).firstWhere((m) => m.id == answer.id);
        expect(reread.replyTo?.preview, 'Message retiré');
      },
    );

    test('répondre au message de l\'autre : sender_id de l\'autre', () {
      final theirs = _messages(101).firstWhere((m) => m.senderId == _other);
      final reply = _text('ok', replyTo: theirs.id);
      expect(reply.replyTo?.senderId, _other);
    });

    test('reply_to_id inconnu ou d\'une autre conversation : 400', () {
      _send({
        'client_id': 'r1',
        'type': 'text',
        'content': 'x',
        'reply_to_id': 424242,
      }, status: 400);
      final elsewhere = _messages(102).first;
      _send({
        'client_id': 'r2',
        'type': 'text',
        'content': 'x',
        'reply_to_id': elsewhere.id,
      }, status: 400);
    });
  });

  group('réactions', () {
    test('la même réaction deux fois la retire ; une seule par membre', () {
      final m = _text('Salut');
      var r = _call(
        'POST',
        '/api/messages/${m.id}/reactions',
        body: {'emoji': '❤️'},
      );
      expect(r.status, 200);
      var reactions = [
        for (final x in r.json['reactions'] as List)
          Reaction.fromJson(x as Map<String, dynamic>),
      ];
      expect(reactions.single.emoji, '❤️');
      expect(reactions.single.userIds, [_mine]);

      r = _call(
        'POST',
        '/api/messages/${m.id}/reactions',
        body: {'emoji': '😂'},
      );
      reactions = [
        for (final x in r.json['reactions'] as List)
          Reaction.fromJson(x as Map<String, dynamic>),
      ];
      expect(reactions.map((x) => x.emoji), [
        '😂',
      ], reason: 'la nouvelle remplace l\'ancienne');

      r = _call(
        'POST',
        '/api/messages/${m.id}/reactions',
        body: {'emoji': '😂'},
      );
      expect(r.json['reactions'], isEmpty);
      expect(_messages(101).firstWhere((x) => x.id == m.id).reactions, isEmpty);
    });

    test(
      'réagir à un message de l\'autre ; les réactions se voient à la relecture',
      () {
        final theirs = _messages(101).firstWhere((m) => m.senderId == _other);
        for (final emoji in ['❤️', '😂', '😮', '😢', '🙏', '👍']) {
          expect(
            _call(
              'POST',
              '/api/messages/${theirs.id}/reactions',
              body: {'emoji': emoji},
            ).status,
            200,
          );
        }
        final reread = _messages(101).firstWhere((m) => m.id == theirs.id);
        expect(reread.reactions.single.emoji, '👍');
        expect(reread.reactions.single.userIds, [_mine]);
      },
    );

    test('emoji hors liste : 400 ; message inconnu : 404', () {
      final m = _text('x');
      expect(
        _call(
          'POST',
          '/api/messages/${m.id}/reactions',
          body: {'emoji': '🔥'},
        ).status,
        400,
      );
      expect(_call('POST', '/api/messages/${m.id}/reactions').status, 400);
      expect(
        _call(
          'POST',
          '/api/messages/987654/reactions',
          body: {'emoji': '❤️'},
        ).status,
        404,
      );
    });
  });

  group('retrait (unsend)', () {
    test('dans les 15 minutes : unsent, contenu et médias vidés', () {
      final photo = _decode(
        _send({
          'client_id': 'u1',
          'type': 'photo',
          'content': 'secret',
          'media_ids': [_uploadPhoto(_jpeg(8, 8))['id']],
        })['message'],
      );
      _advance(const Duration(minutes: 14, seconds: 59));
      final r = _call('POST', '/api/messages/${photo.id}/unsend');
      expect(r.status, 200);
      final m = _decode(r.json['message']);
      expect(m.unsent, isTrue);
      expect(m.content, '');
      expect(m.media, isEmpty);
      expect(m.voice, isNull);
      expect(m.linkPreview, isNull);
      expect(_messages(101).firstWhere((x) => x.id == photo.id).unsent, isTrue);
    });

    test('après 15 minutes : refus 403 et le message reste', () {
      final m = _text('trop tard');
      _advance(const Duration(minutes: 15, seconds: 1));
      expect(_call('POST', '/api/messages/${m.id}/unsend').status, 403);
      expect(_messages(101).firstWhere((x) => x.id == m.id).unsent, isFalse);
    });

    test(
      'seul l\'auteur peut retirer ; message inconnu : 404 ; deux fois : toujours 200',
      () {
        final theirs = _messages(101).firstWhere((m) => m.senderId == _other);
        expect(_call('POST', '/api/messages/${theirs.id}/unsend').status, 403);
        expect(_call('POST', '/api/messages/987654/unsend').status, 404);
        final mine = _text('x');
        expect(_call('POST', '/api/messages/${mine.id}/unsend').status, 200);
        expect(_call('POST', '/api/messages/${mine.id}/unsend').status, 200);
      },
    );

    test('on ne réagit plus à un message retiré', () {
      final m = _text('x');
      _call('POST', '/api/messages/${m.id}/unsend');
      expect(
        _call(
          'POST',
          '/api/messages/${m.id}/reactions',
          body: {'emoji': '❤️'},
        ).status,
        400,
      );
    });
  });

  group('lecture et signalement', () {
    test('up_to_id marque lu jusqu\'à ce message seulement', () {
      final theirs = _messages(101).where((m) => m.senderId == _other).toList();
      final unread = theirs.where((m) => m.readAt == null).toList();
      expect(unread, hasLength(2));
      final older = unread.last;
      expect(
        _call(
          'PUT',
          '/api/conversations/101/read',
          body: {'up_to_id': older.id},
        ).status,
        200,
      );
      final after = _messages(101).where((m) => m.senderId == _other);
      expect(after.where((m) => m.readAt == null), hasLength(1));
      expect(after.firstWhere((m) => m.id == older.id).readAt, isNotNull);
      final conv =
          (_call('GET', '/api/conversations').json['conversations'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((c) => c['id'] == 101);
      expect(conv['unreadCount'], 1);
    });

    test('sans up_to_id (ancienne app) : tout est lu', () {
      expect(
        _call('PUT', '/api/conversations/101/read', body: const {}).status,
        200,
      );
      expect(
        _messages(101).where((m) => m.senderId == _other && m.readAt == null),
        isEmpty,
      );
    });

    test('signalement : un message de l\'autre avec un motif', () {
      final theirs = _messages(101).firstWhere((m) => m.senderId == _other);
      final r = _call(
        'POST',
        '/api/messages/${theirs.id}/report',
        body: {'reason': 'spam'},
      );
      expect(r.status, 200);
      expect(r.json['success'], isTrue);
      expect(_call('POST', '/api/messages/${theirs.id}/report').status, 400);
      final mine = _text('x');
      expect(
        _call(
          'POST',
          '/api/messages/${mine.id}/report',
          body: {'reason': 'spam'},
        ).status,
        400,
      );
    });
  });

  group('correspondant fictif (§5)', () {
    test('il écrit 2 s, puis lit : read_at posé à l\'échéance, pas avant', () {
      final m = _text('Coucou');
      _advance(const Duration(milliseconds: 1999));
      expect(_messages(101).firstWhere((x) => x.id == m.id).readAt, isNull);
      _advance(const Duration(milliseconds: 1));
      final read = _messages(101).firstWhere((x) => x.id == m.id).readAt;
      expect(read, isNotNull);
      expect(read!.difference(m.createdAt), const Duration(seconds: 2));
    });

    test('1er message : il répond « Haha 😄 » juste après avoir lu', () {
      final m = _text('Coucou');
      _advance(const Duration(seconds: 2));
      final newest = _messages(101).first;
      expect(newest.content, 'Haha 😄');
      expect(newest.senderId, _other);
      expect(newest.id, greaterThan(m.id));
      expect(newest.type, ChatMessageType.text);
      expect(newest.createdAt.isAfter(m.createdAt), isTrue);
    });

    test(
      '2e : simplement lu ; 3e : « Avec plaisir ! » ; 4e : un ❤️ sur mon message',
      () {
        _text('un');
        _advance(const Duration(seconds: 2));
        final two = _text('deux');
        _advance(const Duration(seconds: 2));
        expect(_messages(101).first.id, two.id, reason: 'pas de réponse au 2e');
        expect(_messages(101).first.readAt, isNotNull);

        _text('trois');
        _advance(const Duration(seconds: 2));
        expect(_messages(101).first.content, 'Avec plaisir !');

        final four = _text('quatre');
        _advance(const Duration(seconds: 2));
        final reread = _messages(101);
        expect(reread.first.id, four.id);
        final reaction = reread.first.reactions.single;
        expect(reaction.emoji, '❤️');
        expect(reaction.userIds, [_other]);
      },
    );

    test(
      'rien n\'arrive sans lecture : pas de minuteur, l\'horloge décide',
      () {
        final m = _text('Coucou');
        _advance(const Duration(hours: 3));
        final messages = _messages(101);
        expect(messages.first.content, 'Haha 😄');
        expect(messages.firstWhere((x) => x.id == m.id).readAt, isNotNull);
      },
    );

    test('la liste des conversations montre la réponse et un non-lu', () {
      _text('Coucou');
      _advance(const Duration(seconds: 2));
      final conv =
          (_call('GET', '/api/conversations').json['conversations'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((c) => c['id'] == 101);
      expect(conv['lastMessage'], 'Haha 😄');
      expect(
        conv['unreadCount'],
        3,
        reason: '2 non lus de départ + la réponse',
      );
    });

    test('il lit aussi une photo envoyée', () {
      final photo = _decode(
        _send({
          'client_id': 'ph',
          'type': 'photo',
          'media_ids': [_uploadPhoto(_jpeg(8, 8))['id']],
        })['message'],
      );
      _advance(const Duration(seconds: 2));
      expect(
        _messages(101).firstWhere((x) => x.id == photo.id).readAt,
        isNotNull,
      );
    });

    test('une conversation ouverte par un match répond aussi', () {
      final r = _call(
        'POST',
        '/api/swipes',
        body: {'target_user_id': 201, 'action': 'like'},
      );
      expect(r.json['match'], isTrue);
      final conv =
          (_call('GET', '/api/conversations').json['conversations'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((c) => (c['otherUser'] as Map)['user_id'] == 201);
      final id = conv['id'] as int;
      expect(_messages(id), isEmpty);
      final m = _text('Enchanté', conversation: id);
      _advance(const Duration(seconds: 2));
      final messages = _messages(id);
      expect(messages.first.senderId, 201);
      expect(messages.last.id, m.id);
      expect(messages.last.readAt, isNotNull);
    });
  });

  group('404 et jamais 503', () {
    test(
      'conversation inconnue : 404 sur toutes les routes de conversation',
      () {
        for (final (method, path) in [
          ('GET', '/api/conversations/777/messages'),
          ('POST', '/api/conversations/777/messages'),
          ('POST', '/api/conversations/777/media'),
          ('PUT', '/api/conversations/777/read'),
        ]) {
          final r = _call(
            method,
            path,
            body: {
              'client_id': 'z',
              'type': 'text',
              'content': 'x',
              'kind': 'photo',
            },
          );
          expect(r.status, 404, reason: '$method $path');
          expect(r.json['success'], isFalse);
        }
      },
    );

    test('chemins de messagerie inconnus : 404', () {
      for (final (method, path) in [
        ('GET', '/api/conversations/101/typing'),
        ('DELETE', '/api/conversations/101/messages'),
        ('POST', '/api/messages/1/pin'),
        ('GET', '/api/messages/1/reactions'),
        ('GET', '/api/messages'),
        ('DELETE', '/api/conversations/101'),
      ]) {
        expect(_call(method, path).status, 404, reason: '$method $path');
      }
    });

    test('aucune route de messagerie ne rend 503', () {
      final m = _text('x');
      for (final (method, path) in [
        ('GET', '/api/conversations'),
        ('GET', '/api/conversations/101/messages'),
        ('POST', '/api/conversations/101/messages'),
        ('POST', '/api/conversations/101/media'),
        ('PUT', '/api/conversations/101/read'),
        ('POST', '/api/messages/${m.id}/reactions'),
        ('POST', '/api/messages/${m.id}/unsend'),
        ('POST', '/api/messages/${m.id}/report'),
      ]) {
        expect(_call(method, path).status, isNot(503), reason: '$method $path');
      }
    });

    test('une nouvelle session démo repart sans message envoyé', () {
      _text('éphémère');
      DevSession.start();
      expect(_messages(101).where((m) => m.content == 'éphémère'), isEmpty);
    });
  });
}
