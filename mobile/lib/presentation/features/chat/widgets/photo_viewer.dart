import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'photo_grid.dart';

/// Opens the full-screen viewer on the root navigator (docs/design/CHAT.md §7).
Future<void> openPhotoViewer(
  BuildContext context, {
  required List<PhotoSource> photos,
  required int initialIndex,
  String? heroPrefix,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => PhotoViewer(photos: photos, initialIndex: initialIndex, heroPrefix: heroPrefix),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Black page: swipe between photos, pinch to zoom, drag down to close.
///
/// Zoom and paging come from photo_view's gallery (a PageView of zoomable
/// pages): a bare InteractiveViewer inside a PageView swallows the swipe.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, required this.initialIndex, this.heroPrefix});

  final List<PhotoSource> photos;
  final int initialIndex;
  final String? heroPrefix;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  double _dragOffset = 0;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _endDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 120 || velocity > 700) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / 300).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 1 - progress * 0.7),
        body: GestureDetector(
          onVerticalDragUpdate: _zoomed
              ? null
              : (d) => setState(() => _dragOffset = (_dragOffset + d.delta.dy).clamp(0.0, double.infinity)),
          onVerticalDragEnd: _zoomed ? null : _endDrag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _dragOffset),
                child: PhotoViewGallery.builder(
                  pageController: _pages,
                  itemCount: widget.photos.length,
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  onPageChanged: (i) => setState(() => _index = i),
                  scaleStateChangedCallback: (state) => setState(() => _zoomed = state != PhotoViewScaleState.initial),
                  builder: (_, i) => PhotoViewGalleryPageOptions.customChild(
                    child: widget.photos[i].image(fit: BoxFit.contain, tint: i),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained * 4,
                    heroAttributes: widget.heroPrefix == null ? null : PhotoViewHeroAttributes(tag: '${widget.heroPrefix}-$i'),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 8,
                child: Opacity(
                  opacity: 1 - progress,
                  child: SizedBox.square(
                    dimension: 44,
                    child: IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(LucideIcons.x, size: 24, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              if (widget.photos.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.photos.length; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: i == _index ? 1 : 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
