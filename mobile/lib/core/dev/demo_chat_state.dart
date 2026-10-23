import 'dart:typed_data';

import 'demo_chat_media.dart';
import 'demo_chat_seed.dart';

const demoReactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];
const demoUnsendWindow = Duration(minutes: 15);

/// Un message de la démo, avec ce qu'il faut pour le servir sous la forme du
/// contrat (docs/chat/CONTRAT.md §1).
class DemoChatMessage {
  DemoChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.clientId,
    this.media = const [],
    this.voice,
    this.replyToId,
    this.readAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String? clientId;
  final String type;
  String content;
  final DateTime createdAt;
  List<DemoChatMedia> media;
  DemoChatMedia? voice;
  final int? replyToId;
  DateTime? readAt;
  bool unsent = false;

  /// Réactions dans l'ordre d'arrivée : emoji → membres.
  final Map<String, List<int>> reactions = {};

  /// Premier lien du texte, et l'instant où son aperçu « arrive ».
  String? linkUrl;
  DateTime? linkReadyAt;

  /// Résumé d'une ligne pour la liste des conversations et les réponses.
  String get summary => unsent
      ? 'Message retiré'
      : switch (type) {
          'photo' => 'Photo',
          'voice' => 'Message vocal',
          _ => content,
        };
}

/// Un effet du correspondant fictif, calculé à l'envoi et appliqué quand une
/// lecture rencontre l'horloge après [due] (aucun minuteur).
class _Effect {
  _Effect(this.due, this.ownMessageId, this.ordinal);

  final DateTime due;
  final int ownMessageId;

  /// Rang (1, 2, 3…) du message parmi ceux envoyés pendant la session dans
  /// cette conversation : il décide seul de la réaction du correspondant.
  final int ordinal;
}

/// État de la messagerie pendant une session fictive : messages de chaque
/// conversation, médias déposés et correspondant fictif. Les horloges sont
/// passées en paramètre, jamais lues ici.
class DemoChatState {
  /// Le correspondant « écrit » pendant ce délai, puis lit et peut répondre.
  static const typingDelay = Duration(seconds: 2);
  static const linkPreviewDelay = Duration(seconds: 1);

  final Map<int, List<DemoChatMessage>> _byConversation = {};
  final Map<int, DemoChatMedia> _media = {};
  final Map<int, List<_Effect>> _effects = {};
  final Map<int, int> _sentCount = {};
  int _nextMessageId = 20000;
  int _nextMediaId = 5000;

  /// Remplis par `DemoStore` : qui est l'autre membre, et la liste de départ.
  late int Function(int conversationId) otherUserOf;
  late int myId;

  List<DemoChatMessage> _list(int conversationId, DateTime now) =>
      _byConversation.putIfAbsent(
        conversationId,
        () => DemoChatSeed.messages(conversationId, now, myId, _id),
      );

  int _id() => _nextMessageId++;

  /// Appliquer les effets arrivés à échéance : lecture, réponse, réaction.
  void settle(DateTime now) {
    for (final entry in _effects.entries) {
      final due = entry.value.where((e) => !e.due.isAfter(now)).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      for (final effect in due) {
        entry.value.remove(effect);
        _apply(entry.key, effect, now);
      }
    }
  }

  void _apply(int conversationId, _Effect effect, DateTime now) {
    final all = _list(conversationId, now);
    final other = otherUserOf(conversationId);
    for (final m in all) {
      if (m.senderId == myId && m.readAt == null && !m.createdAt.isAfter(effect.due)) {
        m.readAt = effect.due;
      }
    }
    final own = all.where((m) => m.id == effect.ownMessageId);
    switch (effect.ordinal % 4) {
      case 1:
        _reply(conversationId, other, 'Haha 😄', effect.due);
      case 3:
        _reply(conversationId, other, 'Avec plaisir !', effect.due);
      case 0:
        if (own.isNotEmpty && !own.first.unsent) {
          own.first.reactions.putIfAbsent('❤️', () => []).add(other);
        }
    }
  }

  void _reply(int conversationId, int other, String text, DateTime at) =>
      _list(conversationId, at).add(
        DemoChatMessage(
          id: _id(),
          conversationId: conversationId,
          senderId: other,
          type: 'text',
          content: text,
          createdAt: at,
        ),
      );

  /// Le correspondant « écrit » : un message à moi attend sa lecture.
  bool isTyping(int conversationId, DateTime now) =>
      (_effects[conversationId] ?? const []).any((e) {
        final own = _byConversation[conversationId]?.where((m) => m.id == e.ownMessageId);
        final sentAt = own?.firstOrNull?.createdAt;
        return sentAt != null && !now.isBefore(sentAt) && now.isBefore(e.due);
      });

  /// Du plus récent au plus ancien ; `before` exclut ce message et les
  /// suivants. Rend aussi s'il en reste de plus anciens.
  ({List<DemoChatMessage> page, bool hasMore}) page(
    int conversationId,
    DateTime now, {
    int? before,
    required int limit,
  }) {
    final newestFirst = _list(conversationId, now).reversed
        .where((m) => before == null || m.id < before)
        .toList();
    return (
      page: newestFirst.take(limit).toList(),
      hasMore: newestFirst.length > limit,
    );
  }

  DemoChatMessage? _loaded(int id) {
    for (final conversationId in _byConversation.keys.toList()) {
      final found = _byConversation[conversationId]!.where((m) => m.id == id);
      if (found.isNotEmpty) return found.first;
    }
    return null;
  }

  /// Cherche aussi dans les conversations pas encore ouvertes.
  DemoChatMessage? find(int id, Iterable<int> conversationIds, DateTime now) {
    for (final conversationId in conversationIds) {
      _list(conversationId, now);
    }
    return _loaded(id);
  }

  DemoChatMessage? latest(int conversationId, DateTime now) =>
      _list(conversationId, now).lastOrNull;

  int unreadCount(int conversationId, DateTime now) => _list(conversationId, now)
      .where((m) => m.senderId != myId && m.readAt == null && !m.unsent)
      .length;

  // --- Médias ---

  DemoChatMedia addMedia({
    required int conversationId,
    required String kind,
    required String mime,
    required List<int> bytes,
    required DateTime now,
    int? width,
    int? height,
    int? durationMs,
    List<int>? waveform,
  }) {
    final media = DemoChatMedia(
      id: _nextMediaId++,
      conversationId: conversationId,
      kind: kind,
      mime: mime,
      bytes: Uint8List.fromList(bytes),
      createdAt: now,
      width: width,
      height: height,
      durationMs: durationMs,
      waveform: waveform,
    );
    _media[media.id] = media;
    return media;
  }

  /// Média libre de cette conversation, `null` s'il manque, appartient à une
  /// autre conversation, est déjà pris ou a été purgé.
  DemoChatMedia? freeMedia(int id, int conversationId, DateTime now) {
    final media = _media[id];
    if (media == null || media.conversationId != conversationId) return null;
    if (media.attachedTo != null || media.isPurged(now)) return null;
    return media;
  }

  // --- Messages ---

  DemoChatMessage? byClientId(int conversationId, String clientId, DateTime now) =>
      _list(conversationId, now)
          .where((m) => m.clientId == clientId)
          .firstOrNull;

  DemoChatMessage send({
    required int conversationId,
    required String? clientId,
    required String type,
    required String content,
    required DateTime now,
    List<DemoChatMedia> media = const [],
    int? replyToId,
  }) {
    final message = DemoChatMessage(
      id: _id(),
      conversationId: conversationId,
      senderId: myId,
      clientId: clientId,
      type: type,
      content: type == 'voice' ? '' : content,
      createdAt: now,
      media: type == 'photo' ? media : const [],
      voice: type == 'voice' ? media.first : null,
      replyToId: replyToId,
    );
    for (final m in media) {
      m.attachedTo = message.id;
    }
    final link = RegExp(r'https?://[^\s]+').firstMatch(message.content);
    if (link != null) {
      message.linkUrl = link.group(0);
      message.linkReadyAt = now.add(linkPreviewDelay);
    }
    _list(conversationId, now).add(message);
    final ordinal = _sentCount.update(conversationId, (n) => n + 1, ifAbsent: () => 1);
    _effects
        .putIfAbsent(conversationId, () => [])
        .add(_Effect(now.add(typingDelay), message.id, ordinal));
    return message;
  }

  /// Bascule la réaction de [userId] ; une seule par membre et par message.
  void toggleReaction(DemoChatMessage message, String emoji, int userId) {
    final had = message.reactions[emoji]?.contains(userId) ?? false;
    for (final users in message.reactions.values) {
      users.remove(userId);
    }
    if (!had) message.reactions.putIfAbsent(emoji, () => []).add(userId);
    message.reactions.removeWhere((_, users) => users.isEmpty);
  }

  void unsend(DemoChatMessage message) {
    message.unsent = true;
    message.content = '';
    for (final m in [...message.media, if (message.voice != null) message.voice!]) {
      _media.remove(m.id);
    }
    message.media = const [];
    message.voice = null;
    message.linkUrl = null;
  }

  /// Marque comme lus les messages de l'autre membre jusqu'à [upToId].
  void markRead(int conversationId, DateTime now, {int? upToId}) {
    for (final m in _list(conversationId, now)) {
      if (m.senderId != myId && m.readAt == null && (upToId == null || m.id <= upToId)) {
        m.readAt = now;
      }
    }
  }

  // --- Forme du contrat ---

  Map<String, dynamic> toJson(DemoChatMessage m, DateTime now) {
    final reply = m.replyToId == null ? null : _loaded(m.replyToId!);
    final linkReady =
        m.linkUrl != null && m.linkReadyAt != null && !m.linkReadyAt!.isAfter(now);
    return {
      'id': m.id,
      'conversation_id': m.conversationId,
      'sender_id': m.senderId,
      'client_id': m.clientId,
      'type': m.type,
      'content': m.unsent ? '' : m.content,
      'media': m.unsent ? <Object>[] : [for (final x in m.media) x.toJson()],
      'voice': m.unsent ? null : m.voice?.toJson(),
      'reply_to': reply == null
          ? null
          : {
              'id': reply.id,
              'sender_id': reply.senderId,
              'type': reply.type,
              'preview': _preview(reply),
            },
      'reactions': [
        for (final e in m.reactions.entries)
          {'emoji': e.key, 'user_ids': List<int>.of(e.value)},
      ],
      'link_preview': m.unsent || !linkReady ? null : DemoChatSeed.linkPreview(m.linkUrl!),
      'created_at': m.createdAt.toUtc().toIso8601String(),
      'read_at': m.readAt?.toUtc().toIso8601String(),
      'unsent': m.unsent,
    };
  }

  static String _preview(DemoChatMessage m) {
    final text = m.summary;
    final runes = text.runes.toList();
    return runes.length <= 80 ? text : '${String.fromCharCodes(runes.take(79))}…';
  }
}
