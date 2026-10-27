import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/motion/mazl_motion.dart';

/// Where a darkening gradient sits over a photo, so the badges and the title
/// drawn on it stay readable (contrast AA for white text).
enum EventPhotoScrim {
  none,

  /// Light at the top (the buttons), dark at the bottom (badges, title).
  bottom,
}

/// The photo of an event, filling its box.
///
/// While the photo loads: the color of the kind of event with a soft sheen
/// (still under « Réduire les animations »). With no photo, or when it cannot
/// be loaded: the plain color of the kind of event with its icon.
class EventPhoto extends StatelessWidget {
  const EventPhoto({
    super.key,
    required this.imageUrl,
    required this.typeColor,
    required this.typeIcon,
    this.fallbackEnd,
    this.iconSize = 48,
    this.scrim = EventPhotoScrim.none,
  });

  final String? imageUrl;
  final Color typeColor;
  final IconData typeIcon;

  /// The far color of the plain background; the kind's color faded by default.
  final Color? fallbackEnd;
  final double iconSize;
  final EventPhotoScrim scrim;

  /// A test serves its photos from memory instead of the network.
  @visibleForTesting
  static ImageProvider Function(String url)? debugProvider;

  BoxDecoration get _plain => BoxDecoration(
    gradient: LinearGradient(
      colors: [typeColor, fallbackEnd ?? typeColor.withValues(alpha: 0.7)],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    ),
  );

  Widget _fallback() => DecoratedBox(
    decoration: _plain,
    child: Center(
      child: Icon(typeIcon, size: iconSize, color: Colors.white54),
    ),
  );

  Widget _placeholder(BuildContext context) {
    final base = Color.alphaBlend(Colors.black26, typeColor);
    final sheen = Color.alphaBlend(Colors.white24, typeColor);
    return Stack(
      fit: StackFit.expand,
      children: [
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: sheen,
          period: MazlMotion.eventPlaceholderPeriod,
          enabled: !MazlMotion.reduced(context),
          child: const ColoredBox(color: Colors.white),
        ),
        Center(
          child: Icon(typeIcon, size: iconSize, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _photo(BuildContext context, String url) {
    final provider = debugProvider;
    if (provider != null) {
      return Image(
        image: provider(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }
    final fade = MazlMotion.reduced(context)
        ? Duration.zero
        : MazlMotion.eventPhotoFade;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: fade,
      fadeOutDuration: fade,
      placeholder: (context, url) => _placeholder(context),
      errorWidget: (context, url, error) => _fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        hasPhoto ? _photo(context, url) : _fallback(),
        if (scrim == EventPhotoScrim.bottom) const EventPhotoScrimLayer(),
      ],
    );
  }
}

/// The darkening gradient of [EventPhotoScrim.bottom], on its own so a flight
/// can fade it in.
class EventPhotoScrimLayer extends StatelessWidget {
  const EventPhotoScrimLayer({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66000000),
            Color(0x00000000),
            Color(0x33000000),
            Color(0xCC000000),
          ],
          stops: [0, 0.28, 0.5, 1],
        ),
      ),
    ),
  );
}
