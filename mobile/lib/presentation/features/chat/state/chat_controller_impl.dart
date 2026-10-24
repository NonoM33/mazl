import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/chat/chat_api.dart';
import '../../../../core/chat/chat_providers.dart';
import '../../../../core/chat/chat_realtime.dart';
import 'chat_controller.dart';
import 'chat_message_ops.dart';

// The conversation controller. CONTRACT: docs/chat/CONTRAT.md §4. The screen
// depends on [ChatState] and [ChatActions] only. Message content is never
// logged.

const maxPhotosPerMessage = 10;
const unsendWindow = Duration(minutes: 15);

/// Delays of the typing indicator, injectable for tests.
class ChatTimings {
  const ChatTimings({
    this.typingIdle = const Duration(seconds: 3),
    this.typingRefresh = const Duration(seconds: 4),
    this.otherTypingExpiry = const Duration(seconds: 6),
  });

  /// Silence after which I stop "typing".
  final Duration typingIdle;

  /// While I keep typing, the next keystroke after this delay repeats `true`
  /// so the other side's indicator ([otherTypingExpiry]) does not lapse.
  final Duration typingRefresh;

  /// The other side's indicator goes off by itself after this long.
  final Duration otherTypingExpiry;
}

final chatControllerProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, conversationId) {
  ref.watch(chatSessionProvider);
  return ChatControllerImpl(
    conversationId: conversationId,
    api: ref.watch(chatApiProvider),
    realtime: ref.watch(chatRealtimeSourceProvider),
    resolveMyUserId: () => ref.read(chatMyUserIdProvider.future),
  );
});

/// What is needed to (re)send a message, kept while it has not been delivered.
class _Outgoing {
  _Outgoing({
    required this.type,
    this.content = '',
    this.photos = const [],
    this.voiceBytes,
    this.durationMs,
    this.waveform,
    this.replyToId,
  });

  final ChatMessageType type;
  final String content;
  final List<Uint8List> photos;
  final Uint8List? voiceBytes;
  final int? durationMs;
  final List<int>? waveform;
  final int? replyToId;

  /// Already uploaded media, so a retry never uploads twice.
  final Map<int, int> photoMediaIds = {};
  int? voiceMediaId;
  bool inFlight = false;
}

class ChatControllerImpl extends ChatNotifier {
  ChatControllerImpl({
    required this.conversationId,
    required ChatApi api,
    required ChatRealtimeSource realtime,
    required Future<int> Function() resolveMyUserId,
    this.timings = const ChatTimings(),
    DateTime Function()? now,
    String Function()? newClientId,
  })  : _api = api,
        _realtime = realtime,
        _resolveMyUserId = resolveMyUserId,
        _now = now ?? DateTime.now,
        _newClientId = newClientId ?? (() => 'c-${const Uuid().v4()}'),
        super(ChatState(conversationId: conversationId, myUserId: 0)) {
    _subscription = realtime.events(conversationId).listen(_onEvent);
  }

  final int conversationId;
  final ChatTimings timings;
  final ChatApi _api;
  final ChatRealtimeSource _realtime;
  final Future<int> Function() _resolveMyUserId;
  final DateTime Function() _now;
  final String Function() _newClientId;

  StreamSubscription<ChatRealtimeEvent>? _subscription;
  Future<int>? _userFuture;
  int _me = 0;
  int _nextLocalId = -1;
  int _lastReadSent = 0;
  final _outbox = <String, _Outgoing>{};

  Timer? _otherTypingTimer;
  Timer? _idleTimer;
  Timer? _refreshTimer;
  bool _typingSent = false;
  bool _refreshDue = false;

  // ---- state helpers ----

  void _update(ChatState Function(ChatState) change) {
    if (mounted) state = change(state);
  }

  void _setMessages(List<ChatMessage> Function(List<ChatMessage>) change) =>
      _update((s) => s.copyWith(messages: change(s.messages)));

  Future<int> _ensureUser() {
    if (_me != 0) return Future.value(_me);
    return _userFuture ??= _resolveMyUserId().then((id) {
      _me = id;
      return id;
    }).catchError((Object error) {
      _userFuture = null;
      throw error;
    });
  }

  ChatMessage? _byId(int id) {
    for (final m in state.messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  ChatMessage? _byClientId(String clientId) {
    for (final m in state.messages) {
      if (m.clientId == clientId) return m;
    }
    return null;
  }

  // ---- loading ----

  @override
  Future<void> load() async {
    _update((s) => s.copyWith(loading: s.messages.isEmpty, clearError: true));
    try {
      final me = await _ensureUser();
      final firstLoad = !state.messages.any((m) => !m.isLocal);
      final page = await _api.getMessages(conversationId);
      _update((s) => s.copyWith(
            myUserId: me,
            messages: _mergePage(s.messages, page.messages),
            loading: false,
            hasMore: firstLoad ? page.hasMore : s.hasMore,
          ));
    } on ChatApiException catch (e) {
      _loadFailed(e.message);
    } on Object {
      _loadFailed('Impossible de charger la conversation.');
    }
  }

  void _loadFailed(String message) =>
      _update((s) => s.copyWith(loading: false, error: s.messages.isEmpty ? message : null));

  List<ChatMessage> _mergePage(List<ChatMessage> current, List<ChatMessage> newestFirst) {
    var merged = current;
    for (final m in newestFirst.reversed) {
      merged = upsertMessage(merged, m);
    }
    return merged;
  }

  @override
  Future<void> loadOlder() async {
    if (state.loading || state.loadingOlder || !state.hasMore) return;
    final oldest = state.messages.where((m) => !m.isLocal).map((m) => m.id).fold<int?>(
          null,
          (min, id) => min == null || id < min ? id : min,
        );
    if (oldest == null) return;
    _update((s) => s.copyWith(loadingOlder: true));
    try {
      final page = await _api.getMessages(conversationId, before: oldest);
      _update((s) => s.copyWith(
            messages: _mergePage(s.messages, page.messages),
            hasMore: page.messages.isNotEmpty && page.hasMore,
            loadingOlder: false,
          ));
    } on ChatApiException {
      _update((s) => s.copyWith(loadingOlder: false));
    }
  }

  Future<void> _refreshAfterReconnect() async {
    try {
      final page = await _api.getMessages(conversationId);
      _setMessages((list) => _mergePage(list, page.messages));
    } on ChatApiException {
      // The next event or screen visit refreshes again.
    }
  }

  // ---- sending ----

  @override
  Future<String?> sendText(String text, {int? replyToId}) {
    final content = text.trim();
    if (content.isEmpty) return Future.value();
    return _enqueue(_Outgoing(type: ChatMessageType.text, content: content, replyToId: replyToId));
  }

  @override
  Future<String?> sendPhotos(List<Uint8List> jpegs, {String caption = '', int? replyToId}) {
    if (jpegs.isEmpty) return Future.value();
    if (jpegs.length > maxPhotosPerMessage) return Future.value('Dix photos au maximum par message.');
    return _enqueue(_Outgoing(
      type: ChatMessageType.photo,
      content: caption.trim(),
      photos: List.unmodifiable(jpegs),
      replyToId: replyToId,
    ));
  }

  @override
  Future<String?> sendVoice(
    Uint8List aac, {
    required int durationMs,
    required List<int> waveform,
    int? replyToId,
  }) =>
      _enqueue(_Outgoing(
        type: ChatMessageType.voice,
        voiceBytes: aac,
        durationMs: durationMs,
        waveform: List.unmodifiable(waveform),
        replyToId: replyToId,
      ));

  Future<String?> _enqueue(_Outgoing outgoing) async {
    try {
      await _ensureUser();
    } on Object {
      return 'Impossible d’envoyer pour le moment.';
    }
    final clientId = _newClientId();
    _outbox[clientId] = outgoing;
    _stopTyping();
    final original = outgoing.replyToId == null ? null : _byId(outgoing.replyToId!);
    final pending = ChatMessage(
      id: _nextLocalId--,
      clientId: clientId,
      conversationId: conversationId,
      senderId: _me,
      type: outgoing.type,
      content: outgoing.content,
      createdAt: _now(),
      status: MessageStatus.sending,
      localMedia: outgoing.photos,
      voice: _optimisticVoice(outgoing),
      replyTo: original == null ? null : replyRefFor(original),
    );
    _setMessages((list) => upsertMessage(list, pending));
    return _deliver(clientId);
  }

  VoiceNote? _optimisticVoice(_Outgoing outgoing) {
    final bytes = outgoing.voiceBytes;
    if (bytes == null) return null;
    return VoiceNote(
      id: 0,
      url: 'data:audio/mp4;base64,${base64Encode(bytes)}',
      durationMs: outgoing.durationMs ?? 0,
      waveform: outgoing.waveform ?? const [],
    );
  }

  @override
  Future<String?> retry(String clientId) async {
    final outgoing = _outbox[clientId];
    if (outgoing == null || _byClientId(clientId) == null) return 'Ce message n’existe plus.';
    if (outgoing.inFlight) return null;
    return _deliver(clientId);
  }

  @override
  void discard(String clientId) {
    final message = _byClientId(clientId);
    if (message == null || message.status != MessageStatus.failed) return;
    _outbox.remove(clientId);
    _setMessages((list) => [
          for (final m in list)
            if (m.clientId != clientId) m,
        ]);
  }

  /// Uploads what is missing, sends, and settles the bubble. Returns the French
  /// error, or null when delivered (or when the message turned out to be
  /// delivered already, because the WebSocket echo beat a failing HTTP call).
  Future<String?> _deliver(String clientId) async {
    final outgoing = _outbox[clientId];
    if (outgoing == null) return null;
    outgoing.inFlight = true;
    _setStatus(clientId, MessageStatus.sending);
    try {
      final mediaIds = await _uploadMedia(outgoing);
      final sent = await _api.sendMessage(
        conversationId,
        clientId: clientId,
        type: outgoing.type,
        content: outgoing.content,
        mediaIds: mediaIds,
        replyToId: outgoing.replyToId,
      );
      _outbox.remove(clientId);
      _setMessages((list) => upsertMessage(list, sent));
      return null;
    } on ChatApiException catch (e) {
      return _failed(clientId, e.message);
    } on Object {
      return _failed(clientId, 'Une erreur est survenue.');
    } finally {
      outgoing.inFlight = false;
    }
  }

  String? _failed(String clientId, String message) {
    final current = _byClientId(clientId);
    if (current != null && !current.isLocal) {
      _outbox.remove(clientId);
      return null;
    }
    _setStatus(clientId, MessageStatus.failed);
    return message;
  }

  void _setStatus(String clientId, MessageStatus status) => _setMessages((list) => [
        for (final m in list)
          if (m.clientId == clientId && m.isLocal) m.copyWith(status: status) else m,
      ]);

  Future<List<int>> _uploadMedia(_Outgoing outgoing) async {
    switch (outgoing.type) {
      case ChatMessageType.text:
        return const [];
      case ChatMessageType.photo:
        await Future.wait([
          for (var i = 0; i < outgoing.photos.length; i++)
            if (!outgoing.photoMediaIds.containsKey(i))
              _api
                  .uploadMedia(conversationId, bytes: outgoing.photos[i], kind: MediaKind.photo)
                  .then((media) => outgoing.photoMediaIds[i] = media.id),
        ]);
        return [for (var i = 0; i < outgoing.photos.length; i++) outgoing.photoMediaIds[i]!];
      case ChatMessageType.voice:
        final existing = outgoing.voiceMediaId;
        if (existing != null) return [existing];
        final media = await _api.uploadMedia(
          conversationId,
          bytes: outgoing.voiceBytes!,
          kind: MediaKind.voice,
          durationMs: outgoing.durationMs,
          waveform: outgoing.waveform,
        );
        outgoing.voiceMediaId = media.id;
        return [media.id];
    }
  }

  // ---- reactions, unsend, report ----

  @override
  Future<String?> toggleReaction(int messageId, String emoji) async {
    if (!allowedReactions.contains(emoji)) return 'Réaction indisponible.';
    final message = _byId(messageId);
    if (message == null || message.isLocal) return 'Ce message n’est pas encore envoyé.';
    final before = message.reactions;
    _replace(message.copyWith(reactions: toggleMyReaction(before, emoji, _me)));
    try {
      final confirmed = await _api.toggleReaction(messageId, emoji);
      _replaceFields(messageId, (m) => m.copyWith(reactions: confirmed));
      return null;
    } on ChatApiException catch (e) {
      _replaceFields(messageId, (m) => m.copyWith(reactions: before));
      return e.message;
    }
  }

  @override
  Future<String?> unsend(int messageId) async {
    final message = _byId(messageId);
    if (message == null) return 'Ce message n’existe plus.';
    if (message.senderId != _me) return 'Seul l’auteur peut retirer un message.';
    if (_now().difference(message.createdAt) > unsendWindow) return 'Ce message ne peut plus être retiré.';
    _replace(message.copyWith(unsent: true));
    try {
      final updated = await _api.unsend(messageId);
      if (updated != null) _setMessages((list) => replaceMessage(list, updated));
      return null;
    } on ChatApiException catch (e) {
      _replace(message);
      return e.message;
    }
  }

  @override
  Future<String?> report(int messageId, String reason) async {
    try {
      await _api.report(messageId, reason);
      return null;
    } on ChatApiException catch (e) {
      return e.message;
    }
  }

  void _replace(ChatMessage message) => _setMessages((list) => replaceMessage(list, message));

  void _replaceFields(int id, ChatMessage Function(ChatMessage) change) => _setMessages((list) => [
        for (final m in list)
          if (m.id == id) change(m) else m,
      ]);

  // ---- typing and read receipts ----

  @override
  void setTyping(bool typing) {
    if (!typing) {
      _stopTyping();
      return;
    }
    if (!_typingSent || _refreshDue) {
      _typingSent = true;
      _refreshDue = false;
      _realtime.sendTyping(conversationId, true);
      _refreshTimer?.cancel();
      _refreshTimer = Timer(timings.typingRefresh, () => _refreshDue = true);
    }
    _idleTimer?.cancel();
    _idleTimer = Timer(timings.typingIdle, _stopTyping);
  }

  void _stopTyping() {
    _idleTimer?.cancel();
    _refreshTimer?.cancel();
    _idleTimer = null;
    _refreshTimer = null;
    _refreshDue = false;
    if (_typingSent) {
      _typingSent = false;
      _realtime.sendTyping(conversationId, false);
    }
  }

  @override
  void markReadUpTo(int messageId) {
    if (messageId <= _lastReadSent) return;
    final previous = _lastReadSent;
    _lastReadSent = messageId;
    unawaited(_api.markRead(conversationId, upToId: messageId).onError<ChatApiException>((_, __) {
      if (_lastReadSent == messageId) _lastReadSent = previous;
    }));
  }

  // ---- real-time ----

  void _onEvent(ChatRealtimeEvent event) {
    switch (event) {
      case ChatMessageArrived(:final message):
        if (message.conversationId != conversationId) return;
        _setMessages((list) => upsertMessage(list, message));
        if (message.senderId != _me) _setOtherTyping(false);
      case ChatMessageUpdated(:final message):
        if (message.conversationId != conversationId) return;
        _setMessages((list) => replaceMessage(list, message));
      case ChatTypingChanged(:final conversationId, :final userId, :final isTyping):
        if (conversationId != this.conversationId || userId == _me) return;
        _setOtherTyping(isTyping);
      case ChatReadUpTo(:final conversationId, :final userId, :final upToId, :final readAt):
        if (conversationId != this.conversationId || userId == _me) return;
        _setMessages((list) => markSeenUpTo(list, me: _me, upToId: upToId, readAt: readAt));
      case ChatReconnected():
        unawaited(_refreshAfterReconnect());
    }
  }

  void _setOtherTyping(bool typing) {
    _otherTypingTimer?.cancel();
    _otherTypingTimer = null;
    if (typing) {
      _otherTypingTimer = Timer(timings.otherTypingExpiry, () => _update((s) => s.copyWith(otherIsTyping: false)));
    }
    if (state.otherIsTyping != typing) _update((s) => s.copyWith(otherIsTyping: typing));
  }

  @override
  void dispose() {
    _stopTyping();
    _otherTypingTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
