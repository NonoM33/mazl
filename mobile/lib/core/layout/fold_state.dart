import 'package:flutter/widgets.dart';

/// The hinge of a foldable iPhone, as UIKit reports it (`UIHinge.Status`,
/// iOS 27.1). Every other device, and older systems, stay [unknown].
enum HingeStatus { unknown, closed, partiallyOpen, fullyOpen }

/// The physical side where the system puts its vertical bar: the column that
/// holds the status bar, the Dynamic Island and the app's own bars (tab bar,
/// toolbar buttons) on the foldable iPhone, closed or held sideways.
enum VerticalBarSide { left, right }

/// What the fold of the device means for the layout right now.
///
/// [divisions] are the ACTIVE division regions of the window (UIKit's
/// `reservedRegions(kind: .division)`): the curve of a half-open display,
/// margins included, in logical points of the window. Interactive elements
/// stay out of them; scrolling content may cross them. Empty when the device
/// is closed, fully open, or not foldable.
@immutable
class FoldState {
  const FoldState({
    required this.hinge,
    this.divisions = const [],
    this.verticalBar,
    this.occlusions = const [],
  });

  static const unknown = FoldState(hinge: HingeStatus.unknown);

  final HingeStatus hinge;
  final List<Rect> divisions;

  /// Where the system puts its vertical bar (UIKit's `verticalBarEdge`, made
  /// physical), `null` when the bars are horizontal (inner display upright,
  /// any other iPhone) or unknown.
  final VerticalBarSide? verticalBar;

  /// The ACTIVE occlusion regions (UIKit's `reservedRegions(kind:
  /// .occlusion)`): what the system draws over the window, such as the status
  /// bar and the Dynamic Island in the vertical bar. App controls stay out.
  final List<Rect> occlusions;

  /// The fold the layout has to avoid, if any.
  Rect? get activeDivision => divisions.isEmpty ? null : divisions.first;

  /// Reads a message of the `mazl/fold` channel:
  /// `{hinge: 'unknown'|'closed'|'partiallyOpen'|'fullyOpen',
  ///   divisions: [{x, y, width, height}, ...],
  ///   verticalBar: 'left'|'right'|null, occlusions: [{x, y, width, height}, ...]}`.
  /// Anything malformed reads as [unknown] (or drops the malformed part): a
  /// wrong message must never move the layout.
  static FoldState fromMessage(Object? message) {
    if (message is! Map) return unknown;
    final hinge = HingeStatus.values.asNameMap()[message['hinge']];
    if (hinge == null) return unknown;
    return FoldState(
      hinge: hinge,
      divisions: _rectsFrom(message['divisions']),
      verticalBar: VerticalBarSide.values.asNameMap()[message['verticalBar']],
      occlusions: _rectsFrom(message['occlusions']),
    );
  }

  /// All the rectangles of [raw], or none when one of them is malformed.
  static List<Rect> _rectsFrom(Object? raw) {
    if (raw is! List) return const [];
    final rects = <Rect>[];
    for (final item in raw) {
      final rect = _rectFrom(item);
      if (rect == null) return const [];
      rects.add(rect);
    }
    return List.unmodifiable(rects);
  }

  static Rect? _rectFrom(Object? raw) {
    if (raw is! Map) return null;
    final values = [raw['x'], raw['y'], raw['width'], raw['height']];
    if (values.any((value) => value is! num)) return null;
    final [x, y, width, height] = values
        .cast<num>()
        .map((v) => v.toDouble())
        .toList();
    final finite = [x, y, width, height].every((v) => v.isFinite);
    if (!finite || width <= 0 || height <= 0) return null;
    return Rect.fromLTWH(x, y, width, height);
  }

  @override
  bool operator ==(Object other) =>
      other is FoldState &&
      other.hinge == hinge &&
      other.verticalBar == verticalBar &&
      _sameRects(other.occlusions, occlusions) &&
      _sameRects(other.divisions, divisions);

  static bool _sameRects(List<Rect> a, List<Rect> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  @override
  int get hashCode => Object.hash(
    hinge,
    verticalBar,
    Object.hashAll(divisions),
    Object.hashAll(occlusions),
  );
}

/// Hands the current [FoldState] to every screen below it.
class FoldScope extends InheritedWidget {
  const FoldScope({super.key, required this.state, required super.child});

  final FoldState state;

  /// The fold state of the window, [FoldState.unknown] without a scope.
  static FoldState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FoldScope>()?.state ??
      FoldState.unknown;

  @override
  bool updateShouldNotify(FoldScope oldWidget) => oldWidget.state != state;
}

/// Keeps a [FoldScope] up to date with a stream of fold states (the platform
/// channel in the app, a controller in tests).
class FoldStateHost extends StatefulWidget {
  const FoldStateHost({super.key, required this.states, required this.child});

  final Stream<FoldState> states;
  final Widget child;

  @override
  State<FoldStateHost> createState() => _FoldStateHostState();
}

class _FoldStateHostState extends State<FoldStateHost> {
  @override
  Widget build(BuildContext context) => StreamBuilder<FoldState>(
    stream: widget.states,
    initialData: FoldState.unknown,
    builder: (context, snapshot) => FoldScope(
      state: snapshot.data ?? FoldState.unknown,
      child: widget.child,
    ),
  );
}
