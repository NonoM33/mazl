import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/voice.dart';
import 'package:mazl/core/chat/voice_impl.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/chat_providers.dart';
import 'package:mazl/presentation/features/chat/screens/chat_conversation_screen.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';

const me = 1;
const other = 2;
const conversationId = 40;

/// A 1x1 PNG as a `data:` URI, the way the demo serves media (CONTRACT §4bis).
final tinyPngUri = 'data:image/png;base64,${base64Encode(_tinyPng)}';
const _tinyPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

DateTime today(int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

ChatMessage msg(
  int id,
  int sender,
  String text, {
  DateTime? at,
  ChatMessageType type = ChatMessageType.text,
  List<ChatMedia> media = const [],
  VoiceNote? voice,
  ReplyRef? replyTo,
  List<Reaction> reactions = const [],
  LinkPreview? linkPreview,
  DateTime? readAt,
  bool unsent = false,
  MessageStatus? status,
  String? clientId,
}) => ChatMessage(
  id: id,
  clientId: clientId ?? 'c-$id',
  conversationId: conversationId,
  senderId: sender,
  type: type,
  content: text,
  createdAt: at ?? today(10, id),
  media: media,
  voice: voice,
  replyTo: replyTo,
  reactions: reactions,
  linkPreview: linkPreview,
  readAt: readAt,
  unsent: unsent,
  status: status ?? (readAt != null ? MessageStatus.seen : MessageStatus.sent),
);

ChatState chatState(
  List<ChatMessage> messages, {
  bool hasMore = false,
  bool typing = false,
  bool loading = false,
  String? error,
}) => ChatState(
  conversationId: conversationId,
  myUserId: me,
  messages: messages,
  loading: loading,
  hasMore: hasMore,
  otherIsTyping: typing,
  error: error,
);

/// The real controller's seat: records every action, returns null (success)
/// unless [error] is set.
class FakeChatNotifier extends ChatNotifier {
  FakeChatNotifier(super.state);

  /// Pushes a new state to the screen.
  void emit(ChatState next) => state = next;

  ChatState get current => state;

  final calls = <String>[];
  final sentTexts = <({String text, int? replyToId})>[];
  final sentVoices = <({int durationMs, List<int> waveform, int? replyToId})>[];
  final sentPhotos = <int>[];
  final reactions = <({int messageId, String emoji})>[];
  final retried = <String>[];
  final discarded = <String>[];
  final reported = <({int id, String reason})>[];
  final readUpTo = <int>[];
  final unsent = <int>[];
  String? error;
  int loadOlderCalls = 0;
  int loadCalls = 0;

  @override
  Future<void> load() async => loadCalls++;
  @override
  Future<void> loadOlder() async => loadOlderCalls++;
  @override
  Future<String?> sendText(String text, {int? replyToId}) async {
    sentTexts.add((text: text, replyToId: replyToId));
    return error;
  }

  @override
  Future<String?> sendPhotos(
    List<Uint8List> jpegs, {
    String caption = '',
    int? replyToId,
  }) async {
    sentPhotos.add(jpegs.length);
    return error;
  }

  @override
  Future<String?> sendVoice(
    Uint8List aac, {
    required int durationMs,
    required List<int> waveform,
    int? replyToId,
  }) async {
    sentVoices.add((
      durationMs: durationMs,
      waveform: waveform,
      replyToId: replyToId,
    ));
    return error;
  }

  @override
  Future<String?> retry(String clientId) async {
    retried.add(clientId);
    return error;
  }

  @override
  void discard(String clientId) => discarded.add(clientId);
  @override
  Future<String?> toggleReaction(int messageId, String emoji) async {
    reactions.add((messageId: messageId, emoji: emoji));
    return error;
  }

  @override
  Future<String?> unsend(int messageId) async {
    unsent.add(messageId);
    return error;
  }

  @override
  Future<String?> report(int messageId, String reason) async {
    reported.add((id: messageId, reason: reason));
    return error;
  }

  @override
  void setTyping(bool typing) => calls.add('typing:$typing');
  @override
  void markReadUpTo(int messageId) => readUpTo.add(messageId);
}

class FakeVoiceRecorder implements VoiceRecorder {
  final levelsController = StreamController<int>.broadcast();
  final elapsedController = StreamController<Duration>.broadcast();
  bool permission = true;
  bool started = false;
  bool cancelled = false;
  bool stopped = false;
  VoiceRecording? result = VoiceRecording(
    aac: Uint8List.fromList([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70]),
    duration: const Duration(seconds: 3),
    waveform: List.filled(waveformBars, 40),
  );

  /// Number of start() calls, and failure modes seen on devices: the plugin
  /// throws (encoder unavailable…) or never answers.
  int startCalls = 0;
  int throwOnStarts = 0;
  Completer<bool>? hang;

  @override
  Future<bool> start() async {
    startCalls++;
    if (throwOnStarts > 0) {
      throwOnStarts--;
      throw StateError('encoder unavailable');
    }
    final pending = hang;
    if (pending != null) return pending.future;
    started = permission;
    return permission;
  }

  @override
  Stream<int> get levels => levelsController.stream;
  @override
  Stream<Duration> get elapsed => elapsedController.stream;
  @override
  Future<VoiceRecording?> stop() async {
    stopped = true;
    return result;
  }

  @override
  Future<void> cancel() async => cancelled = true;
  @override
  Future<void> dispose() async {}
}

class FakeVoicePlayer implements VoicePlayer {
  final played = <({String url, double speed})>[];
  final speeds = <double>[];
  int pauses = 0;
  final positionController = StreamController<Duration?>.broadcast();
  final playingController = StreamController<bool>.broadcast();
  String? _current;

  bool failNextPlay = false;

  @override
  Future<void> play(String url, {double speed = 1}) async {
    if (failNextPlay) {
      failNextPlay = false;
      throw StateError('expired');
    }
    _current = url;
    played.add((url: url, speed: speed));
    playingController.add(true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    playingController.add(false);
  }

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);
  @override
  Stream<Duration?> get position => positionController.stream;
  @override
  Stream<bool> get playing => playingController.stream;
  @override
  String? get currentUrl => _current;
  @override
  Future<void> dispose() async {}
}

class FakePicker implements ChatMediaPicker {
  List<Uint8List> gallery = [
    Uint8List.fromList([1]),
    Uint8List.fromList([2]),
  ];
  List<Uint8List> camera = [
    Uint8List.fromList([3]),
  ];
  @override
  Future<List<Uint8List>> fromGallery({int limit = 10}) async => gallery;
  @override
  Future<List<Uint8List>> fromCamera() async => camera;
}

class ChatHarness {
  ChatHarness({ChatState? initial})
    : initialState = initial ?? chatState(const []);

  final ChatState initialState;
  late final FakeChatNotifier actions = FakeChatNotifier(initialState);
  final recorder = FakeVoiceRecorder();
  final player = FakeVoicePlayer();
  final picker = FakePicker();
  final opened = <Uri>[];

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    bool Function(ChatMessage)? isScamFlagged,
    double safeBottom = 0,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: safeBottom);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWith((ref, id) => actions),
          voiceRecorderProvider.overrideWithValue(recorder),
          voicePlayerProvider.overrideWithValue(player),
          chatMediaPickerProvider.overrideWithValue(picker),
          chatLinkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          home: ChatConversationScreen(
            conversationId: conversationId,
            otherUser: ConversationUser(userId: other, displayName: 'Noémie'),
            isScamFlagged: isScamFlagged,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void setState(ChatState next) => actions.emit(next);
  ChatState get state => actions.current;
}

/// Real fonts, so text measures like on a phone (the default test font is
/// 15 px squares).
Future<void> loadChatFonts() async {
  final geist = FontLoader('Geist');
  for (final file in [
    'Geist-400.ttf',
    'Geist-500.ttf',
    'Geist-600.ttf',
    'Geist-700.ttf',
  ]) {
    geist.addFont(
      Future.value(
        ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
      ),
    );
  }
  await geist.load();
  final mono = FontLoader('GeistMono')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/GeistMono-400.ttf').readAsBytesSync(),
        ),
      ),
    );
  await mono.load();
}

Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

Finder bubbleOf(ChatMessage m) =>
    find.byKey(ValueKey('bubble-${m.clientId ?? 'id-${m.id}'}'));
