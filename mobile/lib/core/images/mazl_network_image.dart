import 'package:flutter/material.dart';

import '../motion/mazl_motion.dart';
import 'photo_cache.dart';

/// L'image réseau de toute l'app. Clé de cache stable (l'identifiant de la
/// photo, pas sa signature), cache disque dédié, décodage à la taille
/// d'affichage. Le fondu n'a lieu qu'à la première apparition d'une photo :
/// une image déjà vue s'affiche d'un coup.
class MazlNetworkImage extends StatelessWidget {
  const MazlNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
    this.fadeDuration = const Duration(milliseconds: 220),
  });

  final String url;
  final BoxFit fit;

  /// Montré tant que la première image n'est pas là.
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final logical = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        final width = logical == null || !logical.isFinite
            ? null
            : bucketedPixels(logical, dpr);
        final key = photoCacheKey(url);
        final fade = MazlMotion.reduced(context) ? Duration.zero : fadeDuration;
        return Image(
          image: mazlImageProvider(url, cacheWidth: width),
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: errorBuilder == null
              ? null
              : (context, error, stack) => errorBuilder!(context),
          frameBuilder: (context, child, frame, synchronous) {
            if (frame == null) {
              return placeholder?.call(context) ?? const SizedBox.shrink();
            }
            return _ShownImage(
              cacheKey: key,
              synchronous: synchronous,
              fade: fade,
              placeholder: placeholder?.call(context),
              child: child,
            );
          },
        );
      },
    );
  }
}

/// Décide UNE fois, à la première image, s'il y a un fondu : une reconstruction
/// du parent ne doit ni le relancer ni le couper.
class _ShownImage extends StatefulWidget {
  const _ShownImage({
    required this.cacheKey,
    required this.synchronous,
    required this.fade,
    required this.child,
    this.placeholder,
  });

  final String cacheKey;
  final bool synchronous;
  final Duration fade;
  final Widget child;
  final Widget? placeholder;

  @override
  State<_ShownImage> createState() => _ShownImageState();
}

class _ShownImageState extends State<_ShownImage> {
  late final bool _animate;

  @override
  void initState() {
    super.initState();
    _animate =
        !widget.synchronous &&
        widget.fade > Duration.zero &&
        !MazlImageSeen.contains(widget.cacheKey);
    MazlImageSeen.add(widget.cacheKey);
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (widget.placeholder != null)
          Positioned.fill(child: widget.placeholder!),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: widget.fade,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: widget.child,
        ),
      ],
    );
  }
}
