import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../../l10n/l10n.dart';
import 'photo_grid.dart';

/// Opens the full-screen viewer on the root navigator (docs/design/CHAT.md §7).
Future<void> openPhotoViewer(
  BuildContext context, {
  required List<PhotoSource> photos,
  required int initialIndex,
  String? heroPrefix,
}) {
  final reduced = MazlMotion.reduced(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      // The page paints its own black, which fades while it is dragged: a
      // black barrier underneath would hide that fade.
      transitionDuration: reduced
          ? MazlMotion.reducedFade
          : MazlMotion.viewerOpen,
      // Also the duration of the Hero flight back to the thumbnail.
      reverseTransitionDuration: reduced
          ? MazlMotion.reducedFade
          : MazlMotion.viewerReturnToThumbnail,
      pageBuilder: (_, __, ___) => PhotoViewer(
        photos: photos,
        initialIndex: initialIndex,
        heroPrefix: heroPrefix,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Black page: swipe between photos, pinch to zoom, drag to close.
///
/// Zoom and paging come from photo_view's gallery (a PageView of zoomable
/// pages): a bare InteractiveViewer inside a PageView swallows the swipe.
///
/// Drag to close (docs/design/CHAT.md §7): once a vertical drag starts, the
/// photo follows the finger in both axes, shrinks and lets the background
/// fade. Released short, it springs back; released far or fast downward, the
/// route pops and the Hero flies from where the photo was let go.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.heroPrefix,
  });

  final List<PhotoSource> photos;
  final int initialIndex;
  final String? heroPrefix;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer>
    with TickerProviderStateMixin {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  late final AnimationController _backX = AnimationController.unbounded(
    vsync: this,
  )..addListener(_followReturn);
  late final AnimationController _backY = AnimationController.unbounded(
    vsync: this,
  )..addListener(_followReturn);

  /// Finger sample used for the sideways velocity: the vertical drag
  /// recognizer only reports the vertical one.
  final VelocityTracker _tracker = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );

  Offset _offset = Offset.zero;
  bool _zoomed = false;
  bool _dragging = false;
  bool _closing = false;
  bool _pastDismiss = false;
  double _sidewaysBeforeDrag = 0;

  @override
  void dispose() {
    _pages.dispose();
    _backX.dispose();
    _backY.dispose();
    super.dispose();
  }

  void _followReturn() =>
      setState(() => _offset = Offset(_backX.value, _backY.value));

  void _pointerDown(PointerDownEvent e) {
    _sidewaysBeforeDrag = 0;
    _tracker.addPosition(e.timeStamp, e.position);
  }

  void _pointerMove(PointerMoveEvent e) {
    _tracker.addPosition(e.timeStamp, e.position);
    // The vertical delta comes from the drag recognizer, sideways from here.
    if (!_dragging) {
      _sidewaysBeforeDrag += e.delta.dx;
    } else if (e.delta.dx != 0) {
      setState(() => _offset += Offset(e.delta.dx, 0));
    }
  }

  void _dragStart(DragStartDetails _) {
    _backX.stop();
    _backY.stop();
    _dragging = true;
    // The finger moved sideways too before the vertical intent was clear.
    _offset += Offset(_sidewaysBeforeDrag, 0);
    _sidewaysBeforeDrag = 0;
    _pastDismiss = _offset.dy >= MazlMotion.viewerDismissDistance;
  }

  void _dragUpdate(DragUpdateDetails d) {
    final next = _offset + Offset(0, d.delta.dy);
    final past = next.dy >= MazlMotion.viewerDismissDistance;
    if (past && !_pastDismiss) HapticFeedback.selectionClick();
    _pastDismiss = past;
    setState(() => _offset = next);
  }

  void _dragEnd(DragEndDetails details) {
    _dragging = false;
    final velocityY = details.primaryVelocity ?? 0;
    // Flung back up past the threshold: the person changed their mind.
    final flungBack = velocityY < -MazlMotion.viewerDismissVelocity;
    if (!flungBack &&
        (_offset.dy >= MazlMotion.viewerDismissDistance ||
            velocityY > MazlMotion.viewerDismissVelocity)) {
      _close();
    } else {
      _springBack(Offset(_tracker.getVelocity().pixelsPerSecond.dx, velocityY));
    }
  }

  void _dragCancel() {
    _dragging = false;
    _springBack(Offset.zero);
  }

  void _close() {
    setState(() => _closing = true);
    Navigator.of(context).pop();
  }

  void _springBack(Offset velocity) {
    final from = _offset;
    if (from == Offset.zero) return;
    // Each controller's listener rebuilds the offset from both values.
    _backY.value = from.dy;
    _backX.value = from.dx;
    if (MazlMotion.reduced(context)) {
      for (final c in [_backX, _backY]) {
        c.animateTo(
          0,
          duration: MazlMotion.reducedReturn,
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    final settledX = _backX.animateWith(
      SpringSimulation(MazlMotion.spring, from.dx, 0, velocity.dx),
    );
    final settledY = _backY.animateWith(
      SpringSimulation(MazlMotion.spring, from.dy, 0, velocity.dy),
    );
    // A spring stops within a tolerance of 0, not on it.
    Future.wait([settledX, settledY]).then((_) {
      if (mounted) setState(() => _offset = Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MazlMotion.reduced(context);
    final progress = (_offset.distance / MazlMotion.viewerProgressDistance)
        .clamp(0.0, 1.0);
    final scale = reduced
        ? 1.0
        : 1 - (1 - MazlMotion.viewerMinScale) * progress;
    final draggable = !_zoomed && !_closing;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(
          alpha: 1 - progress * MazlMotion.viewerMaxFade,
        ),
        body: Listener(
          onPointerMove: _pointerMove,
          onPointerDown: _pointerDown,
          child: GestureDetector(
            // Count the touch slop too: the photo is under the finger.
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: draggable ? _dragStart : null,
            onVerticalDragUpdate: draggable ? _dragUpdate : null,
            onVerticalDragEnd: draggable ? _dragEnd : null,
            onVerticalDragCancel: draggable ? _dragCancel : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform(
                  key: const Key('viewer-photo'),
                  alignment: Alignment.center,
                  transform: Matrix4.translationValues(
                    _offset.dx,
                    _offset.dy,
                    0,
                  )..scaleByDouble(scale, scale, 1, 1),
                  child: PhotoViewGallery.builder(
                    pageController: _pages,
                    itemCount: widget.photos.length,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    onPageChanged: (i) => setState(() => _index = i),
                    scaleStateChangedCallback: (state) => setState(
                      () => _zoomed = state != PhotoViewScaleState.initial,
                    ),
                    builder: (_, i) => PhotoViewGalleryPageOptions.customChild(
                      child: widget.photos[i].image(
                        fit: BoxFit.contain,
                        tint: i,
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * 4,
                      // No flight under reduce motion: the page just fades.
                      heroAttributes: widget.heroPrefix == null || reduced
                          ? null
                          : PhotoViewHeroAttributes(
                              tag: '${widget.heroPrefix}-$i',
                            ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: MediaQuery.paddingOf(context).top + 8,
                  start: 8,
                  child: Opacity(
                    opacity: 1 - progress,
                    child: SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        tooltip: context.l10n.commonClose,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 24,
                          color: Colors.white,
                        ),
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
                              color: Colors.white.withValues(
                                alpha: i == _index ? 1 : 0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
