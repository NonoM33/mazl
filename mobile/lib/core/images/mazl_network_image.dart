import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../motion/mazl_motion.dart';
import '../theme/app_colors.dart';
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
    return _NoNaturalSize(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final logical = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : (constraints.hasBoundedHeight ? constraints.maxHeight : null);
          final width = logical == null || !logical.isFinite
              ? null
              : bucketedPixels(logical, dpr);
          final key = photoCacheKey(url);
          final fade = MazlMotion.reduced(context)
              ? Duration.zero
              : fadeDuration;
          return Image(
            image: mazlImageProvider(url, cacheWidth: width),
            fit: fit,
            gaplessPlayback: true,
            // A photo that cannot load ends on the flat tint, never on a spinner.
            errorBuilder: (context, error, stack) =>
                errorBuilder?.call(context) ?? _PhotoPlaceholder(cacheKey: key),
            frameBuilder: (context, child, frame, synchronous) {
              if (frame == null) {
                return placeholder?.call(context) ??
                    _PhotoPlaceholder(cacheKey: key);
              }
              return _ShownImage(
                cacheKey: key,
                synchronous: synchronous,
                fade: fade,
                placeholder:
                    placeholder?.call(context) ??
                    _PhotoPlaceholder(cacheKey: key),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

/// A photo not loaded yet has no natural size: it answers zero when a parent
/// such as IntrinsicHeight asks, instead of reaching the LayoutBuilder, which
/// cannot answer and breaks the layout.
class _NoNaturalSize extends SingleChildRenderObjectWidget {
  const _NoNaturalSize({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNoNaturalSize();
}

class _RenderNoNaturalSize extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
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

/// Ce qu'on voit avant la photo : sa vignette floutée si le cache l'a déjà, sinon
/// l'aplat de la teinte de repli, choisie par l'identifiant de la photo.
class _PhotoPlaceholder extends StatefulWidget {
  const _PhotoPlaceholder({required this.cacheKey});

  final String cacheKey;

  @override
  State<_PhotoPlaceholder> createState() => _PhotoPlaceholderState();
}

class _PhotoPlaceholderState extends State<_PhotoPlaceholder> {
  ImageProvider<Object>? _thumbnail;

  @override
  void initState() {
    super.initState();
    cachedThumbnail(widget.cacheKey).then((thumbnail) {
      if (mounted && thumbnail != null) setState(() => _thumbnail = thumbnail);
    });
  }

  /// Le même identifiant donne toujours la même teinte (jetons photo-1 à 5).
  Color get _tint {
    final id = RegExp(r'/(\d+)$').firstMatch(widget.cacheKey)?.group(1);
    final index = id == null ? widget.cacheKey.hashCode : int.parse(id);
    return AppColors.photoTints[index.abs() % AppColors.photoTints.length];
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = _thumbnail;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: _tint),
        if (thumbnail != null)
          ClipRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
                tileMode: TileMode.clamp,
              ),
              child: Image(
                image: thumbnail,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
      ],
    );
  }
}
