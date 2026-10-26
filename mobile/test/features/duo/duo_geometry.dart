import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/presentation/common/widgets/directional_icon.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

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

  /// The directions its lists can move it in.
  final Set<Axis> axes = {};

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
      placement.axes.add(
        widget.axisDirection == AxisDirection.left ||
                widget.axisDirection == AxisDirection.right
            ? Axis.horizontal
            : Axis.vertical,
      );
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

/// One line per text, image or tappable element that the fold of [pose]
/// crosses. Apple moves text and images away from the curve and keeps
/// interactive elements out of it: held like a book, a page reads on one side
/// of the fold, never across it. Unlike [tappableProblems], a list does not
/// excuse an element unless it scrolls ACROSS the fold (a carousel under a
/// fold that runs down the page): a list that scrolls along the fold keeps
/// the element in the curve, row after row.
List<String> foldCrossingProblems(WidgetTester tester, DuoPose pose) {
  final fold = pose.fold;
  if (fold == null) return const [];
  final across = fold.height > fold.width ? Axis.horizontal : Axis.vertical;
  final candidates = find
      .byWidgetPredicate(
        (widget) =>
            (widget is RichText &&
                widget.text.toPlainText().trim().isNotEmpty) ||
            widget is RawImage ||
            (widget is GestureDetector && widget.onTap != null) ||
            (widget is InkWell && widget.onTap != null) ||
            widget is EditableText,
      )
      .hitTestable()
      .evaluate();
  final byBox = <String, String>{};
  for (final element in candidates) {
    final placement = _placement(element);
    final ink = _inkOf(element);
    final shown = ink == null
        ? placement.shown
        : placement.shown.intersect(ink);
    if (shown.isEmpty || placement.axes.contains(across)) continue;
    if (!shown.deflate(0.5).overlaps(fold)) continue;
    final key = _rect(shown);
    final name = describeElement(element);
    final known = byBox[key];
    if (known == null || (!known.contains("'") && name.contains("'"))) {
      byBox[key] = name;
    }
  }
  return [
    for (final e in byBox.entries) '${e.value} at ${e.key}: crosses the fold',
  ];
}

/// The arrows that only mean « back » on an icon button (a chevron also pages
/// through months, so it is left to the tooltip).
final Set<IconData> _backArrows = {
  LucideIcons.arrowLeft,
  LucideIcons.arrowRight,
  Icons.arrow_back,
  Icons.arrow_back_ios,
  Icons.arrow_back_ios_new,
};

bool _isBackArrow(Widget? icon) =>
    (icon is Icon && _backArrows.contains(icon.icon)) ||
    (icon is DirectionalIcon && _backArrows.contains(icon.icon));

/// One line per back or close button of the screen that is not in the
/// vertical bar. With a column (the foldable iPhone closed, sideways or held
/// like a book), iOS puts a screen's navigation at the top of that column,
/// within reach of the thumb, not in the top-left corner (regles/iphone-duo.md
/// §2.6). A back or close button is a [BackButton], a [CloseButton], or an
/// icon whose tooltip or label is the app's own « Retour », « Fermer » or
/// « Annuler » (the texts are read from the l10n of the tests, not written
/// here), or an icon button that draws a back arrow, tooltip or not. Without
/// a column, nothing is asked.
List<String> navigationOutsideColumnProblems(
  WidgetTester tester,
  DuoPose pose,
) {
  final column = pose.verticalBar?.controls;
  if (column == null) return const [];
  final l10n = lookupAppLocalizations(kTestLocale);
  final labels = {l10n.commonBack, l10n.commonClose, l10n.commonCancel};
  final buttons = find
      .byWidgetPredicate(
        (widget) =>
            widget is BackButton ||
            widget is CloseButton ||
            (widget is IconButton && _isBackArrow(widget.icon)) ||
            (widget is RoundIconButton && _backArrows.contains(widget.icon)) ||
            (widget is Tooltip && labels.contains(widget.message)) ||
            (widget is Semantics &&
                (widget.properties.button ?? false) &&
                labels.contains(widget.properties.label)),
      )
      .hitTestable()
      .evaluate();
  final byBox = <String, String>{};
  for (final element in buttons) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.isEmpty) continue;
    final inside = column.inflate(0.5);
    if (inside.contains(rect.topLeft) && inside.contains(rect.bottomRight)) {
      continue;
    }
    // An icon button and its tooltip are one button: said once.
    final key = _rect(
      Rect.fromCenter(center: rect.center.translate(0, 0), width: 1, height: 1),
    );
    byBox.putIfAbsent(
      key,
      () => '${describeElement(element)} at ${_rect(rect)}',
    );
  }
  return [
    for (final e in byBox.entries)
      '${e.value}: navigation outside the vertical bar '
          '(${_rect(column)})',
  ];
}

/// Where the glyphs of a text are drawn, in window coordinates: a line of
/// text often gets the whole width of its column and draws a word at its
/// start. `null` for anything but a paragraph.
Rect? _inkOf(Element element) {
  final paragraph = element.renderObject;
  if (paragraph is! RenderParagraph || !paragraph.hasSize) return null;
  final length = paragraph.text.toPlainText().length;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  if (boxes.isEmpty) return null;
  final local = boxes
      .map((box) => box.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return local.shift(paragraph.localToGlobal(Offset.zero));
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
  final window = Offset.zero & pose.size;
  if (!window.inflate(0.5).contains(rect.bottomRight)) {
    return 'main action $what at ${_rect(rect)} off the screen '
        '(${_beyond(rect, window)}): it needs a scroll';
  }
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
