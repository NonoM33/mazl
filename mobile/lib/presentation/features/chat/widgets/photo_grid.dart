import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/chat_controller.dart';
import 'chat_image.dart';

/// One photo of a message: a remote/demo URL, or bytes still being sent.
class PhotoSource {
  const PhotoSource({this.url, this.bytes, this.width, this.height});

  final String? url;
  final Uint8List? bytes;
  final int? width;
  final int? height;

  static List<PhotoSource> of(ChatMessage message) {
    if (message.media.isNotEmpty) {
      return [
        for (final m in message.media)
          PhotoSource(url: m.url, width: m.width, height: m.height),
      ];
    }
    return [for (final b in message.localMedia) PhotoSource(bytes: b)];
  }

  Widget image({BoxFit fit = BoxFit.cover, int tint = 0}) =>
      ChatImage(url: url, bytes: bytes, fit: fit, tint: tint);
}

/// Photos of a bubble (docs/design/CHAT.md §7): one photo at its own ratio,
/// otherwise a 2-column grid of at most 4 cells with « +N » on the last.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.radius,
    required this.heroPrefix,
    required this.onOpen,
    this.blurred = false,
    this.onReveal,
  });

  static const width = 220.0;
  static const gap = 2.0;
  static const cell = (width - gap) / 2;

  final List<PhotoSource> photos;
  final BorderRadius radius;

  /// Hero tags are `<prefix>-<index>`; null disables the hero (menu overlay).
  final String? heroPrefix;
  final void Function(int index) onOpen;

  /// Received photos are blurred until the first tap.
  final bool blurred;
  final VoidCallback? onReveal;

  static double singleHeight(PhotoSource photo) {
    final w = photo.width, h = photo.height;
    if (w == null || h == null || w <= 0 || h <= 0) return width;
    return (width * h / w).clamp(160.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final grid = ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: width, child: _layout()),
    );
    if (!blurred) return grid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onReveal,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 24,
                sigmaY: 24,
                tileMode: TileMode.mirror,
              ),
              child: IgnorePointer(child: grid),
            ),
            const _RevealPill(),
          ],
        ),
      ),
    );
  }

  Widget _layout() {
    final total = photos.length;
    if (total == 1) {
      return SizedBox(
        height: singleHeight(photos.first),
        child: _cell(0, double.infinity),
      );
    }
    final rows = <Widget>[];
    if (total == 2) {
      rows.add(
        SizedBox(
          height: 160,
          child: Row(
            children: [
              _sized(0, cell),
              const SizedBox(width: gap),
              _sized(1, cell),
            ],
          ),
        ),
      );
    } else if (total == 3) {
      rows.add(SizedBox(height: 140, child: _cell(0, double.infinity)));
      rows.add(const SizedBox(height: gap));
      rows.add(
        SizedBox(
          height: cell,
          child: Row(
            children: [
              _sized(1, cell),
              const SizedBox(width: gap),
              _sized(2, cell),
            ],
          ),
        ),
      );
    } else {
      for (var r = 0; r < 2; r++) {
        if (r == 1) rows.add(const SizedBox(height: gap));
        rows.add(
          SizedBox(
            height: cell,
            child: Row(
              children: [
                _sized(r * 2, cell),
                const SizedBox(width: gap),
                _sized(r * 2 + 1, cell),
              ],
            ),
          ),
        );
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _sized(int index, double w) =>
      SizedBox(width: w, child: _cell(index, w));

  Widget _cell(int index, double w) {
    final hidden = index == 3 && photos.length > 4 ? photos.length - 4 : 0;
    Widget image = SizedBox.expand(child: photos[index].image(tint: index));
    if (heroPrefix != null) {
      image = Hero(tag: '$heroPrefix-$index', child: image);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (hidden > 0)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Text(
                  '+$hidden',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevealPill extends StatelessWidget {
  const _RevealPill();

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.eye, size: 16, color: Colors.white),
        SizedBox(width: 8),
        Text(
          'Voir la photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
