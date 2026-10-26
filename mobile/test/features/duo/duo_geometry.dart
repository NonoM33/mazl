import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/duo_poses.dart';

// What `expectFitsDuoPose` checks, with two differences the crawl needs:
//
// * it keeps going after the first problem: the crawl wants every element
//   that does not fit, to tell the next person what to fix;
// * an element of a scrolling list is judged on the part the list shows, not
//   on its whole box. `expectFitsDuoPose` flags any card half scrolled out of
//   a long list as "outside the safe area", which no layout can avoid; here
//   the list is scrolled to its end as well, where a bottom button hidden
//   under the home indicator shows.

/// Every element that reacts to a tap and is on screen (same predicate as
/// `expectFitsDuoPose`).
Iterable<Element> _tappables(WidgetTester tester) => find
    .byWidgetPredicate(
      (widget) =>
          (widget is GestureDetector && widget.onTap != null) ||
          (widget is InkWell && widget.onTap != null) ||
          widget is EditableText ||
          widget is Slider ||
          widget is RangeSlider,
    )
    .hitTestable()
    .evaluate();

/// A few words to find [element] in the code: its text, else its icon.
String describeElement(Element element) {
  String? text;
  IconData? icon;
  void visit(Element child) {
    final widget = child.widget;
    if (widget is Icon) {
      icon ??= widget.icon;
      return;
    }
    if (text == null) {
      if (widget is Text && (widget.data ?? '').trim().isNotEmpty) {
        text = widget.data;
      } else if (widget is RichText &&
          widget.text.toPlainText().trim().isNotEmpty) {
        text = widget.text.toPlainText();
      }
    }
    child.visitChildren(visit);
  }

  visit(element);
  final kind = element.widget.runtimeType.toString();
  if (text != null) return "$kind '${text!.replaceAll('\n', ' ')}'";
  if (icon != null) {
    return '$kind icon U+${icon!.codePoint.toRadixString(16)}';
  }
  return kind;
}

String _rect(Rect r) =>
    '${r.left.round()},${r.top.round()} ${r.width.round()}x${r.height.round()}';

/// By how much [rect] leaves [area], per side, in points. [vertical] and
/// [horizontal] switch a direction off (the one a list scrolls in).
String _beyond(
  Rect rect,
  Rect area, {
  bool vertical = true,
  bool horizontal = true,
}) {
  final sides = <String>[
    if (horizontal && rect.left < area.left - 0.5)
      'left ${(area.left - rect.left).ceil()} pt',
    if (vertical && rect.top < area.top - 0.5)
      'top ${(area.top - rect.top).ceil()} pt',
    if (horizontal && rect.right > area.right + 0.5)
      'right ${(rect.right - area.right).ceil()} pt',
    if (vertical && rect.bottom > area.bottom + 0.5)
      'bottom ${(rect.bottom - area.bottom).ceil()} pt',
  ];
  return sides.join(', ');
}

/// Where [element] is, as far as the lists it scrolls in let it be judged.
class _Placement {
  _Placement(this.whole);

  /// The whole box of the element, in window coordinates.
  final Rect whole;

  /// The part of it that its lists show.
  late Rect shown = whole;
  bool scrolls = false;

  /// Sides that a list may move the element past: the member scrolls it away,
  /// so it is not held against the element. A list is at its start or at its
  /// end when it cannot scroll further that way; there the side counts.
  bool freeTop = false;
  bool freeBottom = false;
  bool freeLeft = false;
  bool freeRight = false;
}

_Placement _placement(Element element) {
  final box = element.renderObject! as RenderBox;
  final placement = _Placement(box.localToGlobal(Offset.zero) & box.size);
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Scrollable && ancestor is StatefulElement) {
      placement.scrolls = true;
      final viewport = ancestor.findRenderObject();
      if (viewport is RenderBox) {
        placement.shown = placement.shown.intersect(
          viewport.localToGlobal(Offset.zero) & viewport.size,
        );
      }
      final position = (ancestor.state as ScrollableState).position;
      if (!position.hasPixels) return true;
      final atStart = position.pixels <= position.minScrollExtent + 0.5;
      final atEnd = position.pixels >= position.maxScrollExtent - 0.5;
      if (position.axis == Axis.vertical) {
        placement.freeTop |= !atStart;
        placement.freeBottom |= !atEnd;
      } else {
        placement.freeLeft |= !atStart;
        placement.freeRight |= !atEnd;
      }
    }
    return true;
  });
  return placement;
}

/// By how much [placement]'s shown part leaves [area], per side that counts.
String _beyondArea(_Placement placement, Rect area) {
  final rect = placement.shown;
  final sides = <String>[
    if (!placement.freeLeft && rect.left < area.left - 0.5)
      'left ${(area.left - rect.left).ceil()} pt',
    if (!placement.freeTop && rect.top < area.top - 0.5)
      'top ${(area.top - rect.top).ceil()} pt',
    if (!placement.freeRight && rect.right > area.right + 0.5)
      'right ${(rect.right - area.right).ceil()} pt',
    if (!placement.freeBottom && rect.bottom > area.bottom + 0.5)
      'bottom ${(rect.bottom - area.bottom).ceil()} pt',
  ];
  return sides.join(', ');
}

/// One line per tappable element that leaves the safe area (and the app's
/// part of the vertical bar), sits under a system element or touches the
/// fold outside a scrolling list. A side that a list can scroll the element
/// past is not held against it.
List<String> tappableProblems(WidgetTester tester, DuoPose pose) {
  final bar = pose.verticalBar?.controls;
  // An InkWell holds a GestureDetector: one line per box, the better named.
  final byBox = <String, String>{};
  for (final element in _tappables(tester)) {
    final placement = _placement(element);
    final shown = placement.shown;
    if (shown.isEmpty) continue;
    final leaves = _beyondArea(placement, pose.safeRect);
    final leavesBar = bar == null ? 'x' : _beyondArea(placement, bar);
    final issues = <String>[
      if (leaves.isNotEmpty && leavesBar.isNotEmpty)
        'outside the safe area ($leaves)',
      if (pose.foldState.occlusions.any(shown.overlaps) &&
          !placement.freeTop &&
          !placement.freeBottom)
        'under the system',
      if (pose.fold != null && !placement.scrolls && shown.overlaps(pose.fold!))
        'in the fold',
    ];
    if (issues.isNotEmpty) {
      final key = '${_rect(shown)}: ${issues.join(' + ')}';
      final name = describeElement(element);
      final known = byBox[key];
      if (known == null || (!known.contains("'") && name.contains("'"))) {
        byBox[key] = name;
      }
    }
  }
  return [for (final e in byBox.entries) '${e.value} at ${e.key}'];
}

/// Scrolls every long vertical list of the screen to its end, so that what
/// the bottom of the list leaves under the home indicator shows. Returns
/// whether anything moved.
Future<bool> scrollListsToTheEnd(WidgetTester tester) async {
  var moved = false;
  for (final state
      in find
          .byType(Scrollable)
          .evaluate()
          .map((e) => (e as StatefulElement).state as ScrollableState)) {
    final position = state.position;
    if (position.axis != Axis.vertical ||
        position.viewportDimension < 200 ||
        position.maxScrollExtent < 1) {
      continue;
    }
    position.jumpTo(position.maxScrollExtent);
    moved = true;
  }
  if (moved) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  return moved;
}

/// Why [finder] (the main action of a screen, which must be on it) is not
/// entirely in view, or null when it is. Not in view means: outside the safe
/// area, under the system, in the fold, or cut by the list it scrolls in.
String? primaryProblem(WidgetTester tester, DuoPose pose, Finder finder) {
  final element = finder.evaluate().first;
  final box = element.renderObject! as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final what = describeElement(element);
  bool inside(Rect area) =>
      area.inflate(0.5).contains(rect.topLeft) &&
      area.inflate(0.5).contains(rect.bottomRight);
  final bar = pose.verticalBar?.controls;
  if (!(inside(pose.safeRect) || (bar != null && inside(bar)))) {
    return 'main action $what at ${_rect(rect)} outside the safe area '
        '(${_beyond(rect, pose.safeRect)})';
  }
  if (pose.foldState.occlusions.any(rect.overlaps)) {
    return 'main action $what at ${_rect(rect)} under the system';
  }
  if (pose.fold != null && rect.overlaps(pose.fold!)) {
    return 'main action $what at ${_rect(rect)} in the fold';
  }
  final shown = _placement(element).shown;
  if ((shown.width - rect.width).abs() > 0.5 ||
      (shown.height - rect.height).abs() > 0.5) {
    return 'main action $what at ${_rect(rect)} needs a scroll '
        '(only ${_rect(shown)} shows)';
  }
  return null;
}
