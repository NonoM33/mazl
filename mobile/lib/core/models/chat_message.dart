import 'package:flutter/foundation.dart';

import '_json_parsing.dart';

// Chat models. CONTRACT: docs/chat/CONTRAT.md §1. The server shape is decoded
// here only; screens never read raw JSON.

enum ChatMessageType { text, photo, voice }

/// Lifecycle of a message as the user sees it. Server messages are [sent]
/// (or [seen] once read); optimistic ones go [sending] → [sent] or [failed].
enum MessageStatus { sending, sent, seen, failed }

const allowedReactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];

@immutable
class ChatMedia {
  const ChatMedia({required this.id, required this.url, this.width, this.height});

  final int id;
  final String url;
  final int? width;
  final int? height;

  factory ChatMedia.fromJson(Map<String, dynamic> json) => ChatMedia(
        id: parseIntSafe(json['id']) ?? 0,
        url: json['url'] as String,
        width: parseIntSafe(json['width']),
        height: parseIntSafe(json['height']),
      );
}

@immutable
class VoiceNote {
  const VoiceNote({required this.id, required this.url, required this.durationMs, required this.waveform});

  final int id;
  final String url;
  final int durationMs;

  /// 48 values, 0–100.
  final List<int> waveform;

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        id: parseIntSafe(json['id']) ?? 0,
        url: json['url'] as String,
        durationMs: parseIntSafe(json['duration_ms']) ?? 0,
        waveform: [for (final v in (json['waveform'] as List<dynamic>? ?? const [])) parseIntSafe(v) ?? 0],
      );
}

@immutable
class ReplyRef {
  const ReplyRef({required this.id, required this.senderId, required this.type, required this.preview});

  final int id;
  final int senderId;
  final ChatMessageType type;
  final String preview;

  factory ReplyRef.fromJson(Map<String, dynamic> json) => ReplyRef(
        id: parseIntSafe(json['id']) ?? 0,
        senderId: parseIntSafe(json['sender_id']) ?? 0,
        type: chatMessageTypeFromJson(json['type'] as String?),
        preview: json['preview'] as String? ?? '',
      );
}

@immutable
class Reaction {
  const Reaction({required this.emoji, required this.userIds});

  final String emoji;
  final List<int> userIds;

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        emoji: json['emoji'] as String,
        userIds: [for (final id in (json['user_ids'] as List<dynamic>? ?? const [])) parseIntSafe(id) ?? 0],
      );
}

@immutable
class LinkPreview {
  const LinkPreview({required this.url, this.title, this.description, this.imageUrl, this.siteName});

  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        url: json['url'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        siteName: json['site_name'] as String?,
      );
}

ChatMessageType chatMessageTypeFromJson(String? value) => switch (value) {
      'photo' => ChatMessageType.photo,
      'voice' => ChatMessageType.voice,
      _ => ChatMessageType.text,
    };

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.clientId,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.media = const [],
    this.voice,
    this.replyTo,
    this.reactions = const [],
    this.linkPreview,
    this.readAt,
    this.unsent = false,
    this.status = MessageStatus.sent,
    this.localMedia = const [],
  });

  /// Server id; negative while the message only exists locally.
  final int id;
  final String? clientId;
  final int conversationId;
  final int senderId;
  final ChatMessageType type;
  final String content;
  final DateTime createdAt;
  final List<ChatMedia> media;
  final VoiceNote? voice;
  final ReplyRef? replyTo;
  final List<Reaction> reactions;
  final LinkPreview? linkPreview;
  final DateTime? readAt;
  final bool unsent;
  final MessageStatus status;

  /// Bytes of photos being sent, shown before the upload finishes.
  final List<Uint8List> localMedia;

  bool get isLocal => id < 0;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String);
    return ChatMessage(
      id: parseIntSafe(json['id']) ?? 0,
      clientId: json['client_id'] as String?,
      conversationId: parseIntSafe(json['conversation_id']) ?? 0,
      senderId: parseIntSafe(json['sender_id']) ?? 0,
      type: chatMessageTypeFromJson(json['type'] as String?),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      media: [for (final m in (json['media'] as List<dynamic>? ?? const [])) ChatMedia.fromJson(m as Map<String, dynamic>)],
      voice: json['voice'] == null ? null : VoiceNote.fromJson(json['voice'] as Map<String, dynamic>),
      replyTo: json['reply_to'] == null ? null : ReplyRef.fromJson(json['reply_to'] as Map<String, dynamic>),
      reactions: [for (final r in (json['reactions'] as List<dynamic>? ?? const [])) Reaction.fromJson(r as Map<String, dynamic>)],
      linkPreview: json['link_preview'] == null ? null : LinkPreview.fromJson(json['link_preview'] as Map<String, dynamic>),
      readAt: readAt,
      unsent: json['unsent'] == true,
      status: readAt != null ? MessageStatus.seen : MessageStatus.sent,
    );
  }

  ChatMessage copyWith({
    int? id,
    List<ChatMedia>? media,
    VoiceNote? voice,
    List<Reaction>? reactions,
    LinkPreview? linkPreview,
    DateTime? readAt,
    bool? unsent,
    MessageStatus? status,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        clientId: clientId,
        conversationId: conversationId,
        senderId: senderId,
        type: type,
        content: unsent == true ? '' : content,
        createdAt: createdAt,
        media: unsent == true ? const [] : (media ?? this.media),
        voice: unsent == true ? null : (voice ?? this.voice),
        replyTo: replyTo,
        reactions: reactions ?? this.reactions,
        linkPreview: unsent == true ? null : (linkPreview ?? this.linkPreview),
        readAt: readAt ?? this.readAt,
        unsent: unsent ?? this.unsent,
        status: status ?? this.status,
        localMedia: localMedia,
      );
}
