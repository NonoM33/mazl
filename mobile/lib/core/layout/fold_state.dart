import 'package:flutter/widgets.dart';

/// The hinge of a foldable iPhone, as UIKit reports it (`UIHinge.Status`,
/// iOS 27.1). Every other device, and older systems, stay [unknown].
enum HingeStatus { unknown, closed, partiallyOpen, fullyOpen }

/// What the fold of the device means for the layout right now.
///
/// [divisions] are the ACTIVE division regions of the window (UIKit's
/// `reservedRegions(kind: .division)`): the curve of a half-open display,
/// margins included, in logical points of the window. Interactive elements
/// stay out of them; scrolling content may cross them. Empty when the device
/// is closed, fully open, or not foldable.
@immutable
class FoldState {
  const FoldState({required this.hinge, this.divisions = const []});

  static const unknown = FoldState(hinge: HingeStatus.unknown);

  final HingeStatus hinge;
  final List<Rect> divisions;

  /// The fold the layout has to avoid, if any.
  Rect? get activeDivision => divisions.isEmpty ? null : divisions.first;

  /// Reads a message of the `mazl/fold` channel:
  /// `{hinge: 'unknown'|'closed'|'partiallyOpen'|'fullyOpen',
  ///   divisions: [{x, y, width, height}, ...]}`.
  /// Anything malformed reads as [unknown]: a wrong message must never move
  /// the layout.
  static FoldState fromMessage(Object? message) {
    if (message is! Map) return unknown;
    final hinge = HingeStatus.values.asNameMap()[message['hinge']];
    if (hinge == null) return unknown;
    final rawDivisions = message['divisions'];
    if (rawDivisions is! List) return FoldState(hinge: hinge);
    final divisions = <Rect>[];
    for (final raw in rawDivisions) {
      final rect = _rectFrom(raw);
      if (rect == null) return FoldState(hinge: hinge);
      divisions.add(rect);
    }
    return FoldState(hinge: hinge, divisions: List.unmodifiable(divisions));
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
      other.divisions.length == divisions.length &&
      Iterable<int>.generate(
        divisions.length,
      ).every((i) => other.divisions[i] == divisions[i]);

  @override
  int get hashCode => Object.hash(hinge, Object.hashAll(divisions));
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
