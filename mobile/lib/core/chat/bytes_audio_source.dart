import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

// StreamAudioSource is the only way just_audio plays in-memory bytes (the
// `data:` URIs of the demo). It is marked experimental by the package, which
// is accepted here and confined to this file.
// ignore_for_file: experimental_member_use

/// Bytes served to the player, with range support.
class BytesAudioSource extends StreamAudioSource {
  BytesAudioSource(this._bytes, this._contentType);

  final Uint8List _bytes;
  final String _contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = (start ?? 0).clamp(0, _bytes.length);
    final to = (end ?? _bytes.length).clamp(from, _bytes.length);
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(_bytes.sublist(from, to)),
      contentType: _contentType,
    );
  }
}
