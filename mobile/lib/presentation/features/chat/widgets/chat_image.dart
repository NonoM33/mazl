import 'dart:collection';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The only image widget of the chat: http(s) URLs (cached), `data:` URIs
/// (demo mode, CONTRACT §4bis) and raw bytes (a photo being sent).
class ChatImage extends StatelessWidget {
  const ChatImage({
    super.key,
    this.url,
    this.bytes,
    this.fit = BoxFit.cover,
    this.tint = 0,
  }) : assert(url != null || bytes != null, 'a ChatImage needs a url or bytes');

  final String? url;
  final Uint8List? bytes;
  final BoxFit fit;

  /// Picks the neutral placeholder tint, so neighbours differ.
  final int tint;

  static final LinkedHashMap<String, Uint8List> _decoded = LinkedHashMap();

  /// Bytes of a `data:` URI, memoised (a list rebuilds its bubbles often).
  static Uint8List? decodeDataUri(String uri) {
    final cached = _decoded.remove(uri);
    if (cached != null) return _decoded[uri] = cached;
    try {
      final bytes = UriData.parse(uri).contentAsBytes();
      _decoded[uri] = bytes;
      if (_decoded.length > 48) _decoded.remove(_decoded.keys.first);
      return bytes;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      AppColors.photoTints[tint.abs() % AppColors.photoTints.length],
    );
    final raw = bytes ?? _memoryBytes();
    if (raw != null) {
      return Image.memory(
        raw,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _Placeholder(null, broken: true),
        frameBuilder: (context, child, frame, sync) =>
            frame == null && !sync ? placeholder : child,
      );
    }
    final address = url!;
    if (address.startsWith('http://') || address.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: address,
        fit: fit,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => const _Placeholder(null, broken: true),
      );
    }
    return const _Placeholder(null, broken: true);
  }

  Uint8List? _memoryBytes() =>
      url != null && url!.startsWith('data:') ? decodeDataUri(url!) : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.tint, {this.broken = false});

  final Color? tint;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: tint ?? scheme.surfaceContainer,
      child: broken
          ? Center(
              child: Icon(LucideIcons.imageOff, color: scheme.onSurfaceVariant),
            )
          : null,
    );
  }
}
