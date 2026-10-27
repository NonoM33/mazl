import 'package:flutter/widgets.dart';

/// A vertical list whose side padding is a margin for each row rather than a
/// frame around the whole list: a [FullBleed] row runs to the edges, so a
/// horizontal strip of photos slides all the way to the edge of the column
/// instead of being cut at the margin.
class GutteredListView extends StatelessWidget {
  const GutteredListView({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final resolved = padding.resolve(Directionality.of(context));
    final gutter = EdgeInsets.only(left: resolved.left, right: resolved.right);
    return _GutterScope(
      gutter: gutter,
      child: ListView(
        physics: physics,
        padding: EdgeInsets.only(top: resolved.top, bottom: resolved.bottom),
        children: [
          for (final child in children)
            _bleeds(child) ? child : Padding(padding: gutter, child: child),
        ],
      ),
    );
  }

  static bool _bleeds(Widget child) =>
      child is FullBleed || (child is KeyedSubtree && child.child is FullBleed);
}

/// A row of a [GutteredListView] that runs to the edges of the list. Its
/// builder gets the list's side margins, to keep the content aligned with the
/// other rows at rest (as the padding of a horizontal list).
class FullBleed extends StatelessWidget {
  const FullBleed({super.key, required this.builder});

  final Widget Function(BuildContext context, EdgeInsets gutter) builder;

  @override
  Widget build(BuildContext context) => builder(
    context,
    context.dependOnInheritedWidgetOfExactType<_GutterScope>()?.gutter ??
        EdgeInsets.zero,
  );
}

class _GutterScope extends InheritedWidget {
  const _GutterScope({required this.gutter, required super.child});

  final EdgeInsets gutter;

  @override
  bool updateShouldNotify(_GutterScope oldWidget) => gutter != oldWidget.gutter;
}
