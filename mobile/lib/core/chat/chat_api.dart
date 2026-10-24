import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

// Typed HTTP client for the chat. CONTRACT: docs/chat/CONTRAT.md §1 and §2.
// Failures are typed here ([ChatApiErrorKind]) and the screens write the
// sentence in the member's language; the server's own error text is never
// shown (nor logged), and no message content is ever logged.

/// Why a chat call failed, from the HTTP status and, when the server sends
/// one, its stable error code (`blocked`, `not_author`, `too_late`,
/// `too_many_pending`, `rate_limited`).
enum ChatApiErrorKind {
  sessionExpired,
  cannotUnsend,
  conversationGone,
  blocked,
  tooLarge,
  rateLimited,
  server,
  fileRejected,
  messageRejected,
  timeout,
  network,
  unknown,
}

/// A failed chat call. It carries a [kind], never a sentence.
class ChatApiException implements Exception {
  const ChatApiException(this.kind, {this.status});

  final ChatApiErrorKind kind;

  /// HTTP status, null for network failures.
  final int? status;

  @override
  String toString() => 'ChatApiException($status)';
}

class MessagePage {
  const MessagePage({required this.messages, required this.hasMore});

  /// Newest first, as the server sends them.
  final List<ChatMessage> messages;
  final bool hasMore;
}

enum MediaKind { photo, voice }

abstract class ChatApi {
  /// Most recent first; pass the oldest id you have as [before] for older ones.
  Future<MessagePage> getMessages(int conversationId, {int? before, int limit = 30});

  Future<ChatMedia> uploadMedia(
    int conversationId, {
    required Uint8List bytes,
    required MediaKind kind,
    int? durationMs,
    List<int>? waveform,
  });

  /// Idempotent on [clientId]: sending twice returns the same message.
  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String clientId,
    required ChatMessageType type,
    String content = '',
    List<int> mediaIds = const [],
    int? replyToId,
  });

  /// Toggles the caller's reaction; returns the message's reactions.
  Future<List<Reaction>> toggleReaction(int messageId, String emoji);

  /// Returns the updated message when the server sends it.
  Future<ChatMessage?> unsend(int messageId);

  Future<void> markRead(int conversationId, {required int upToId});

  Future<void> report(int messageId, String reason);
}

const _requestTimeout = Duration(seconds: 15);
const _uploadTimeout = Duration(seconds: 60);

class HttpChatApi implements ChatApi {
  HttpChatApi({
    required this.baseUrl,
    required this.token,
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final String baseUrl;
  final String? Function() token;

  /// A client is created per call, like `http.get` does, so the demo client
  /// installed with `runWithClient` is the one that answers in demo mode.
  final http.Client Function() _clientFactory;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> get _headers {
    final jwt = token();
    return {if (jwt != null) 'Authorization': 'Bearer $jwt'};
  }

  Map<String, String> get _jsonHeaders => {..._headers, 'Content-Type': 'application/json'};

  @override
  Future<MessagePage> getMessages(int conversationId, {int? before, int limit = 30}) {
    final uri = _uri('/api/conversations/$conversationId/messages', {
      if (before != null) 'before': '$before',
      'limit': '$limit',
    });
    return _run(() async {
      final data = await _send('GET', uri, _headers);
      return MessagePage(
        messages: _messages(data['messages']),
        hasMore: data['has_more'] == true,
      );
    });
  }

  @override
  Future<ChatMedia> uploadMedia(
    int conversationId, {
    required Uint8List bytes,
    required MediaKind kind,
    int? durationMs,
    List<int>? waveform,
  }) {
    final uri = _uri('/api/conversations/$conversationId/media');
    return _run(() async {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers)
        ..fields['kind'] = kind.name
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: kind == MediaKind.photo ? 'photo.jpg' : 'voice.m4a',
        ));
      if (durationMs != null) request.fields['duration_ms'] = '$durationMs';
      if (waveform != null) request.fields['waveform'] = jsonEncode(waveform);
      final data = await _sendRequest(request, timeout: _uploadTimeout, upload: true);
      return ChatMedia.fromJson(data['media'] as Map<String, dynamic>);
    });
  }

  @override
  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String clientId,
    required ChatMessageType type,
    String content = '',
    List<int> mediaIds = const [],
    int? replyToId,
  }) {
    final uri = _uri('/api/conversations/$conversationId/messages');
    return _run(() async {
      final data = await _send('POST', uri, _jsonHeaders, body: {
        'client_id': clientId,
        'type': type.name,
        'content': content,
        if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
        if (replyToId != null) 'reply_to_id': replyToId,
      });
      return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
    });
  }

  @override
  Future<List<Reaction>> toggleReaction(int messageId, String emoji) {
    final uri = _uri('/api/messages/$messageId/reactions');
    return _run(() async {
      final data = await _send('POST', uri, _jsonHeaders, body: {'emoji': emoji});
      return [for (final r in data['reactions'] as List<dynamic>) Reaction.fromJson(r as Map<String, dynamic>)];
    });
  }

  @override
  Future<ChatMessage?> unsend(int messageId) {
    final uri = _uri('/api/messages/$messageId/unsend');
    return _run(() async {
      final data = await _send('POST', uri, _jsonHeaders, body: const {});
      final message = data['message'];
      return message is Map<String, dynamic> ? ChatMessage.fromJson(message) : null;
    });
  }

  @override
  Future<void> markRead(int conversationId, {required int upToId}) {
    final uri = _uri('/api/conversations/$conversationId/read');
    return _run(() async {
      await _send('PUT', uri, _jsonHeaders, body: {'up_to_id': upToId});
    });
  }

  @override
  Future<void> report(int messageId, String reason) {
    final uri = _uri('/api/messages/$messageId/report');
    return _run(() async {
      await _send('POST', uri, _jsonHeaders, body: {'reason': reason});
    });
  }

  List<ChatMessage> _messages(Object? raw) =>
      [for (final m in raw as List<dynamic>) ChatMessage.fromJson(m as Map<String, dynamic>)];

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri,
    Map<String, String> headers, {
    Map<String, dynamic>? body,
  }) {
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    return _sendRequest(request, timeout: _requestTimeout);
  }

  Future<Map<String, dynamic>> _sendRequest(
    http.BaseRequest request, {
    required Duration timeout,
    bool upload = false,
  }) async {
    final client = _clientFactory();
    try {
      final streamed = await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed).timeout(timeout);
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        throw ChatApiException(
          chatErrorKindFor(
            status,
            code: _serverCode(response.bodyBytes),
            upload: upload,
            unsend: _isUnsend(request),
          ),
          status: status,
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw ChatApiException(ChatApiErrorKind.unknown, status: status);
      }
      return decoded;
    } finally {
      client.close();
    }
  }

  bool _isUnsend(http.BaseRequest request) => request.url.path.endsWith('/unsend');

  /// Maps any failure to a [ChatApiException]; decoding errors included.
  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ChatApiException {
      rethrow;
    } on TimeoutException {
      throw const ChatApiException(ChatApiErrorKind.timeout);
    } on SocketException {
      throw const ChatApiException(ChatApiErrorKind.network);
    } on http.ClientException {
      throw const ChatApiException(ChatApiErrorKind.network);
    } catch (_) {
      throw const ChatApiException(ChatApiErrorKind.unknown);
    }
  }
}

/// The stable code of an error body (`{ success: false, error: "blocked" }`),
/// only when it is one the app knows: free text from the server is dropped.
String? _serverCode(List<int> body) {
  try {
    final decoded = jsonDecode(utf8.decode(body));
    final code = decoded is Map<String, dynamic> ? decoded['error'] : null;
    return code is String && _knownCodes.contains(code) ? code : null;
  } on FormatException {
    return null;
  }
}

const _knownCodes = {'blocked', 'not_author', 'too_late', 'too_many_pending', 'rate_limited'};

/// The kind of a refused call. The server code wins over the bare status:
/// a 403 is « blocked » on a write and « cannot unsend » on a retraction.
ChatApiErrorKind chatErrorKindFor(
  int status, {
  String? code,
  bool upload = false,
  bool unsend = false,
}) {
  switch (code) {
    case 'blocked':
      return ChatApiErrorKind.blocked;
    case 'not_author' || 'too_late':
      return ChatApiErrorKind.cannotUnsend;
    case 'too_many_pending' || 'rate_limited':
      return ChatApiErrorKind.rateLimited;
  }
  if (status == 401) return ChatApiErrorKind.sessionExpired;
  if (unsend && (status == 403 || status == 409 || status == 422)) {
    return ChatApiErrorKind.cannotUnsend;
  }
  // 404: not a member or gone (the server never says which). 403: the pair
  // is blocked, the thread stays readable but nobody can write.
  if (status == 404) return ChatApiErrorKind.conversationGone;
  if (status == 403) return ChatApiErrorKind.blocked;
  if (status == 413) return ChatApiErrorKind.tooLarge;
  if (status == 429) return ChatApiErrorKind.rateLimited;
  if (status >= 500) return ChatApiErrorKind.server;
  if (upload && (status == 400 || status == 415 || status == 422)) {
    return ChatApiErrorKind.fileRejected;
  }
  if (status == 400 || status == 422) return ChatApiErrorKind.messageRejected;
  return ChatApiErrorKind.unknown;
}
