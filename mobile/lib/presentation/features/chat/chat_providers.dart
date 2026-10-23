import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/chat/voice.dart';
import 'state/chat_controller.dart';

// The seam between the conversation UI and its state. The real controller
// (HTTP + WebSocket) overrides the first four; widget tests override them with
// fakes. Nothing in the UI reads an API service directly.

/// What the screen of conversation `id` renders.
final chatStateProvider = Provider.family<ChatState, int>(
  (ref, conversationId) => throw UnimplementedError('chatStateProvider($conversationId) is not provided'),
);

/// What the screen of conversation `id` can ask for.
final chatActionsProvider = Provider.family<ChatActions, int>(
  (ref, conversationId) => throw UnimplementedError('chatActionsProvider($conversationId) is not provided'),
);

final voiceRecorderProvider = Provider<VoiceRecorder>(
  (ref) => throw UnimplementedError('voiceRecorderProvider is not provided'),
);

final voicePlayerProvider = Provider<VoicePlayer>(
  (ref) => throw UnimplementedError('voicePlayerProvider is not provided'),
);

/// Photos picked from the camera or the gallery, as JPEG bytes.
abstract class ChatMediaPicker {
  /// Up to [limit] photos; empty when the user cancels.
  Future<List<Uint8List>> fromGallery({int limit = 10});
  Future<List<Uint8List>> fromCamera();
}

class ImageChatMediaPicker implements ChatMediaPicker {
  ImageChatMediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<Uint8List>> fromGallery({int limit = 10}) async {
    final files = await _picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 82, limit: limit);
    return [for (final file in files) await file.readAsBytes()];
  }

  @override
  Future<List<Uint8List>> fromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 82);
    return file == null ? const [] : [await file.readAsBytes()];
  }
}

final chatMediaPickerProvider = Provider<ChatMediaPicker>((ref) => ImageChatMediaPicker());

/// Opens a link outside the app (link preview cards).
final chatLinkOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Ids of received photos the user already uncovered (they arrive blurred).
final revealedPhotosProvider = StateProvider<Set<int>>((ref) => const {});
