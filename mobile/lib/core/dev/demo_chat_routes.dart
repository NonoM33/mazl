import 'dart:convert';
import 'dart:typed_data';

import 'demo_chat_media.dart';
import 'demo_chat_state.dart';
import 'demo_fixtures.dart';
import 'demo_routes.dart';
import 'demo_store.dart';

/// Routes de la messagerie en démo : mêmes formes et mêmes refus que le
/// serveur (`docs/chat/CONTRAT.md` §1-§2). Aucune ne rend 503 : un chemin de
/// messagerie inconnu rend 404.
abstract final class DemoChatRoutes {
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxVoiceBytes = 3 * 1024 * 1024;
  static const maxVoiceMs = 120000;
  static const maxPhotos = 10;

  static DemoReply _ok(Map<String, dynamic> body, {int status = 200}) =>
      DemoReply({'success': true, ...body}, status: status);

  static DemoReply _fail(int status, String error) =>
      DemoReply({'success': false, 'error': error}, status: status);

  static int _id(RegExpMatch m) => int.parse(m.group(1)!);

  /// Relit l'état à l'horloge de la démo : c'est ici que le correspondant lit
  /// et répond.
  static DateTime _tick() {
    final now = DemoStore.clock();
    DemoStore.chat.settle(now);
    return now;
  }

  static DemoHandler _inConversation(
    DemoReply Function(DemoRequest r, int conversationId, DateTime now) handler,
  ) => (r, m) {
    final now = _tick();
    final id = _id(m);
    if (!DemoStore.hasConversation(id)) {
      return _fail(404, 'Conversation not found');
    }
    return handler(r, id, now);
  };

  /// Message d'une de MES conversations (sinon 404, jamais 403).
  static DemoHandler _onMessage(
    DemoReply Function(DemoRequest r, DemoChatMessage message, DateTime now)
    handler,
  ) => (r, m) {
    final now = _tick();
    final message = DemoStore.chat.find(
      _id(m),
      DemoStore.conversationIds(),
      now,
    );
    if (message == null) return _fail(404, 'Message not found');
    return handler(r, message, now);
  };

  static Map<String, dynamic> _json(DemoChatMessage m, DateTime now) =>
      DemoStore.chat.toJson(m, now);

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  // --- Lecture ---

  static DemoReply _list(DemoRequest r, int conversationId, DateTime now) {
    final rawBefore = r.query['before'];
    final before = rawBefore == null ? null : int.tryParse(rawBefore);
    if (rawBefore != null && before == null) {
      return _fail(400, 'Invalid before');
    }
    final limit = (int.tryParse(r.query['limit'] ?? '') ?? 30).clamp(1, 50);
    final result = DemoStore.chat.page(
      conversationId,
      now,
      before: before,
      limit: limit,
    );
    return _ok({
      'messages': [for (final m in result.page) _json(m, now)],
      'has_more': result.hasMore,
    });
  }

  static DemoReply _read(DemoRequest r, int conversationId, DateTime now) {
    final raw = r.body['up_to_id'];
    final upTo = raw == null ? null : _int(raw);
    if (raw != null && upTo == null) return _fail(400, 'Invalid up_to_id');
    DemoStore.chat.markRead(conversationId, now, upToId: upTo);
    return _ok({});
  }

  // --- Médias ---

  static DemoReply _upload(DemoRequest r, int conversationId, DateTime now) {
    final kind = r.body['kind'];
    if (kind != 'photo' && kind != 'voice') return _fail(400, 'Invalid kind');
    final file = r.files.where((f) => f.field == 'file').firstOrNull;
    if (file == null || file.bytes.isEmpty) return _fail(400, 'file required');
    return kind == 'photo'
        ? _uploadPhoto(conversationId, file.bytes, now)
        : _uploadVoice(r, conversationId, file.bytes, now);
  }

  static DemoReply _uploadPhoto(
    int conversationId,
    Uint8List bytes,
    DateTime now,
  ) {
    if (bytes.length > maxPhotoBytes) return _fail(413, 'Photo too large');
    final image = DemoChatMediaSniffer.image(bytes);
    if (image == null) return _fail(400, 'Unsupported image');
    final media = DemoStore.chat.addMedia(
      conversationId: conversationId,
      kind: 'photo',
      mime: image.mime,
      bytes: bytes,
      now: now,
      width: image.width,
      height: image.height,
    );
    return _ok({'media': media.toJson()});
  }

  static DemoReply _uploadVoice(
    DemoRequest r,
    int conversationId,
    Uint8List bytes,
    DateTime now,
  ) {
    if (bytes.length > maxVoiceBytes) return _fail(413, 'Voice note too large');
    if (!DemoChatMediaSniffer.isM4a(bytes)) {
      return _fail(400, 'Unsupported audio');
    }
    final duration = _int(r.body['duration_ms']);
    if (duration == null || duration < 1 || duration > maxVoiceMs) {
      return _fail(400, 'Invalid duration_ms');
    }
    final waveform = _waveform(r.body['waveform']);
    if (waveform == null) return _fail(400, 'Invalid waveform');
    final media = DemoStore.chat.addMedia(
      conversationId: conversationId,
      kind: 'voice',
      mime: 'audio/mp4',
      bytes: bytes,
      now: now,
      durationMs: duration,
      waveform: waveform,
    );
    return _ok({'media': media.toJson()});
  }

  /// 48 entiers 0–100, en liste ou en JSON texte (multipart).
  static List<int>? _waveform(Object? raw) {
    Object? value = raw;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (value is! List || value.length != 48) return null;
    final result = <int>[];
    for (final v in value) {
      if (v is! num || v != v.toInt() || v < 0 || v > 100) return null;
      result.add(v.toInt());
    }
    return result;
  }

  // --- Envoi ---

  static DemoReply _send(DemoRequest r, int conversationId, DateTime now) {
    final clientId = r.body['client_id'];
    if (clientId != null && (clientId is! String || clientId.isEmpty)) {
      return _fail(400, 'Invalid client_id');
    }
    if (clientId is String) {
      final existing = DemoStore.chat.byClientId(conversationId, clientId, now);
      if (existing != null) return _ok({'message': _json(existing, now)});
    }
    final type = r.body['type'] ?? 'text';
    final content = r.body['content'] is String
        ? r.body['content'] as String
        : '';
    if (type != 'text' && type != 'photo' && type != 'voice') {
      return _fail(400, 'Invalid type');
    }
    if (type == 'text' && content.trim().isEmpty) {
      return _fail(400, 'content required');
    }

    final media = _attachable(
      r.body['media_ids'],
      type as String,
      conversationId,
      now,
    );
    if (media == null) return _fail(400, 'Invalid media_ids');

    final replyRaw = r.body['reply_to_id'];
    final replyTo = replyRaw == null ? null : _int(replyRaw);
    if (replyRaw != null) {
      final target = replyTo == null
          ? null
          : DemoStore.chat.find(replyTo, [conversationId], now);
      if (target == null || target.conversationId != conversationId) {
        return _fail(400, 'Invalid reply_to_id');
      }
    }
    final message = DemoStore.chat.send(
      conversationId: conversationId,
      clientId: clientId as String?,
      type: type,
      content: content,
      now: now,
      media: media,
      replyToId: replyTo,
    );
    return _ok({'message': _json(message, now)});
  }

  /// Les médias libres que ce message utilise, ou `null` si la liste ne
  /// convient pas à [type] : texte sans média, 1 à 10 photos, un seul vocal.
  static List<DemoChatMedia>? _attachable(
    Object? raw,
    String type,
    int conversationId,
    DateTime now,
  ) {
    final List<int?>? ids = raw == null
        ? <int?>[]
        : (raw is List ? [for (final v in raw) _int(v)] : null);
    if (ids == null || ids.contains(null)) return null;
    if (ids.toSet().length != ids.length) return null;
    if (type == 'text') return ids.isEmpty ? const [] : null;
    final media = [
      for (final id in ids) DemoStore.chat.freeMedia(id!, conversationId, now),
    ];
    if (media.contains(null)) return null;
    final found = media.cast<DemoChatMedia>();
    if (type == 'photo') {
      final ok =
          found.isNotEmpty &&
          found.length <= maxPhotos &&
          found.every((m) => m.isPhoto);
      return ok ? found : null;
    }
    return found.length == 1 && !found.first.isPhoto ? found : null;
  }

  // --- Sur un message ---

  static DemoReply _react(
    DemoRequest r,
    DemoChatMessage message,
    DateTime now,
  ) {
    final emoji = r.body['emoji'];
    if (emoji is! String || !demoReactions.contains(emoji)) {
      return _fail(400, 'Invalid emoji');
    }
    if (message.unsent) return _fail(400, 'Message unsent');
    DemoStore.chat.toggleReaction(message, emoji, DemoFixtures.meId);
    return _ok({'reactions': _json(message, now)['reactions']});
  }

  static DemoReply _unsend(
    DemoRequest r,
    DemoChatMessage message,
    DateTime now,
  ) {
    if (message.senderId != DemoFixtures.meId) return _fail(403, 'Forbidden');
    if (!message.unsent) {
      if (now.difference(message.createdAt) > demoUnsendWindow) {
        return _fail(403, 'Unsend window expired');
      }
      DemoStore.chat.unsend(message);
    }
    return _ok({'message': _json(message, now)});
  }

  static DemoReply _report(
    DemoRequest r,
    DemoChatMessage message,
    DateTime now,
  ) {
    final reason = r.body['reason'];
    if (reason is! String || reason.trim().isEmpty) {
      return _fail(400, 'reason required');
    }
    if (message.senderId == DemoFixtures.meId) {
      return _fail(400, 'Cannot report your own message');
    }
    return _ok({});
  }

  static final List<DemoRoute> routes = [
    DemoRoute(
      'GET',
      '/api/conversations/(\\d+)/messages',
      _inConversation(_list),
    ),
    DemoRoute(
      'POST',
      '/api/conversations/(\\d+)/messages',
      _inConversation(_send),
    ),
    DemoRoute(
      'POST',
      '/api/conversations/(\\d+)/media',
      _inConversation(_upload),
    ),
    DemoRoute('PUT', '/api/conversations/(\\d+)/read', _inConversation(_read)),
    DemoRoute('POST', '/api/messages/(\\d+)/reactions', _onMessage(_react)),
    DemoRoute('POST', '/api/messages/(\\d+)/unsend', _onMessage(_unsend)),
    DemoRoute('POST', '/api/messages/(\\d+)/report', _onMessage(_report)),

    // Tout autre chemin de messagerie : 404, jamais 503.
    DemoRoute('*', '/api/conversations/.*', (r, m) => _fail(404, 'Not Found')),
    DemoRoute('*', '/api/messages(?:/.*)?', (r, m) => _fail(404, 'Not Found')),
  ];
}
