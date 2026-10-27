import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/models/event.dart';
import '../../../../core/motion/mazl_motion.dart';
import 'event_photo.dart';

/// What the list hands to the page it opens: the event it already knows (the
/// page shows it at once, then refreshes it) and where its photo sits.
@immutable
class EventFlight {
  const EventFlight({required this.event, required this.from});

  final Event event;

  /// The photo of the card, in window coordinates; `null` when the card is
  /// not on screen (the page then only fades in).
  final Rect? from;
}

/// The shared photo between the card of the list and the header of the page.
///
/// A `Hero` cannot do it: the list lives in the navigator of its tab and the
/// page in the root navigator, and heroes never fly between two navigators.
/// So the card registers where its photo is ([EventFlightSource]), the list
/// calls [prepare] just before it opens the page, and the page
/// ([EventFlightController]) draws the flying photo in the overlay of the
/// root navigator, driven by the animation of its own route: pushing flies
/// the photo to the header, popping flies it back to the card.
abstract final class EventFlights {
  static final Map<int, Rect? Function()> _sources = {};
  static EventFlight? _pending;

  static void registerSource(int eventId, Rect? Function() rect) =>
      _sources[eventId] = rect;

  static void unregisterSource(int eventId, Rect? Function() rect) {
    if (identical(_sources[eventId], rect)) _sources.remove(eventId);
  }

  /// Where the photo of [eventId] is now, or `null` when it is not on screen.
  static Rect? sourceRect(int eventId) => _sources[eventId]?.call();

  /// Called by the list when a card is tapped, before the page opens.
  static void prepare(Event event) {
    _pending = EventFlight(event: event, from: sourceRect(event.id));
  }

  /// The flight prepared for [eventId], once; `null` for a page opened any
  /// other way (a link, a notification).
  static EventFlight? take(int eventId) {
    final flight = _pending;
    _pending = null;
    return flight != null && flight.event.id == eventId ? flight : null;
  }
}

/// Registers the box of the photo of a card, so a page can fly from it.
class EventFlightSource extends StatefulWidget {
  const EventFlightSource({
    super.key,
    required this.eventId,
    required this.child,
  });

  final int eventId;
  final Widget child;

  @override
  State<EventFlightSource> createState() => _EventFlightSourceState();
}

class _EventFlightSourceState extends State<EventFlightSource> {
  late int _eventId = widget.eventId;

  Rect? _rect() {
    final box = context.findRenderObject();
    if (!mounted || box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final window = Offset.zero & MediaQuery.sizeOf(context);
    return rect.overlaps(window) ? rect : null;
  }

  @override
  void initState() {
    super.initState();
    EventFlights.registerSource(_eventId, _rect);
  }

  @override
  void didUpdateWidget(EventFlightSource old) {
    super.didUpdateWidget(old);
    if (old.eventId == widget.eventId) return;
    EventFlights.unregisterSource(_eventId, _rect);
    _eventId = widget.eventId;
    EventFlights.registerSource(_eventId, _rect);
  }

  @override
  void dispose() {
    EventFlights.unregisterSource(_eventId, _rect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Flies the photo from the card to the header of the page and back.
///
/// [flying] is true while the photo is in the air: the page hides its own
/// photo and its header texts, and shows them (the texts fade in) when it
/// lands.
class EventFlightController {
  EventFlightController({required this.eventId, bool expectFlight = false})
    : flying = ValueNotifier(expectFlight);

  final int eventId;

  /// True while the flying photo covers the header. Starts true when a
  /// flight is expected, so the page never shows its own photo for a frame
  /// before the flying one takes its place.
  final ValueNotifier<bool> flying;

  BuildContext? _context;
  Animation<double>? _route;
  GlobalKey? _headerKey;
  Widget Function(BuildContext context)? _photo;
  OverlayEntry? _entry;
  Rect? _from;

  /// Starts listening to the route of [context]. Call once the page has been
  /// built (its header is measured). [from] is where the card's photo was.
  void attach(
    BuildContext context, {
    required Rect? from,
    required GlobalKey headerKey,
    required Widget Function(BuildContext context) photo,
  }) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || MazlMotion.reduced(context)) {
      flying.value = false;
      return;
    }
    _context = context;
    _route = animation;
    _headerKey = headerKey;
    _photo = photo;
    _from = from;
    animation.addStatusListener(_onStatus);
    if (animation.status == AnimationStatus.completed || !_fly(from)) {
      flying.value = false;
    }
  }

  void _onStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        _land();
      case AnimationStatus.reverse:
        _fly(EventFlights.sourceRect(eventId) ?? _from);
      case AnimationStatus.dismissed:
        _remove();
      case AnimationStatus.forward:
        break;
    }
  }

  Rect? _headerRect() {
    final box = _headerKey?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Puts the photo in the air; false when there is nothing to fly between.
  bool _fly(Rect? from) {
    final context = _context;
    final route = _route;
    if (context == null || !context.mounted || route == null) return false;
    final to = _headerRect();
    // A header scrolled away has nothing to land on: the page only fades.
    if (from == null || to == null || to.top < -1 || _entry != null) {
      return false;
    }
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject();
    if (overlayBox is! RenderBox) return false;
    final curved = CurvedAnimation(
      parent: route,
      curve: MazlMotion.eventOpenCurve,
      reverseCurve: MazlMotion.eventOpenCurve.flipped,
    );
    final photo = _photo!;
    flying.value = true;
    _entry = OverlayEntry(
      builder: (overlayContext) => IgnorePointer(
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            final t = curved.value;
            final rect = Rect.fromPoints(
              overlayBox.globalToLocal(Rect.lerp(from, to, t)!.topLeft),
              overlayBox.globalToLocal(Rect.lerp(from, to, t)!.bottomRight),
            );
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: ClipRRect(
                    // The photo of a card is rounded at the top only.
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        lerpDouble(MazlMotion.eventCardRadius, 0, t)!,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        photo(context),
                        Opacity(
                          opacity: t,
                          child: const EventPhotoScrimLayer(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    overlay.insert(_entry!);
    return true;
  }

  void _land() {
    if (_entry == null) return;
    flying.value = false;
    // One more frame with the photo above its twin, so nothing blinks.
    WidgetsBinding.instance.addPostFrameCallback((_) => _remove());
  }

  void _remove() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    if (flying.value) flying.value = false;
  }

  void dispose() {
    _route?.removeStatusListener(_onStatus);
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    flying.dispose();
  }
}

/// A group of the page that enters after the photo has landed: it fades in
/// and rises a little, [group] after [group] (the page of an event, from the
/// route animation). With « Réduire les animations », or outside a route
/// transition, it is drawn as is.
class EventReveal extends StatelessWidget {
  const EventReveal({super.key, required this.group, required this.child});

  final int group;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || MazlMotion.reduced(context)) return child;
    final start =
        MazlMotion.eventTextStart + group * MazlMotion.eventTextStagger;
    final interval = Interval(
      start.clamp(0.0, 0.95),
      (start + MazlMotion.eventTextSpan).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = interval.transform(animation.value);
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * MazlMotion.eventTextRise),
            child: child,
          ),
        );
      },
    );
  }
}
