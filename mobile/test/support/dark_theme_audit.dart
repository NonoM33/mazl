import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_colors.dart';

/// WCAG AA : 4,5:1 pour le texte normal, 3:1 pour le grand texte (18 pt et
/// plus, ou 14 pt gras et plus) et pour les icônes.
const double kMinTextContrast = 4.5;
const double kMinLargeTextContrast = 3;

double requiredContrast(TextStyle? style, {required bool isIcon}) {
  if (isIcon) return kMinLargeTextContrast;
  final size = style?.fontSize ?? 14;
  final bold = (style?.fontWeight?.value ?? 400) >= 700;
  final large = size >= 24 || (bold && size >= 18.67);
  return large ? kMinLargeTextContrast : kMinTextContrast;
}

/// Surfaces dont le contraste n'est pas celui du thème, par construction :
/// les teintes pastel des photos de remplacement (icône décorative) et
/// l'orange des boutons de débogage, qui n'existent pas en production.
final Set<int> kIgnoredSurfaces = {
  for (final tint in AppColors.photoTints) tint.toARGB32(),
  Colors.orange.toARGB32(),
  const Color(0xFFFFF5E6).toARGB32(),
};

/// Le menu de débogage orange (visible seulement en développement).
final Set<int> kIgnoredForegrounds = {Colors.orange.toARGB32()};

/// Une clé à poser autour de l'application (`MaterialApp.builder`) pour
/// pouvoir la photographier avec [captureDarkPng].
final GlobalKey darkCaptureKey = GlobalKey();

Widget darkCaptureBuilder(BuildContext context, Widget? child) =>
    RepaintBoundary(key: darkCaptureKey, child: child);

/// Rapport lisible des textes dont le contraste avec leur surface est
/// insuffisant, calculé sur ce qui est RÉELLEMENT rendu à l'écran : la
/// couleur du texte résolue par le thème, et la première surface opaque
/// (conteneur, carte, feuille, page) qui se trouve derrière.
List<String> lowContrastTexts(WidgetTester tester) {
  final problems = <String>[];
  void visit(Element element) {
    final widget = element.widget;
    if (widget is RichText) {
      final text = widget.text.toPlainText().trim();
      final color = widget.text.style?.color;
      if (text.isNotEmpty && color != null && _isVisible(element)) {
        final background = surfaceBehind(element);
        if (background != null &&
            !kIgnoredSurfaces.contains(background.toARGB32()) &&
            !kIgnoredForegrounds.contains(color.toARGB32())) {
          final foreground = Color.alphaBlend(color, background);
          final ratio = contrastRatio(foreground, background);
          final isIcon = text.runes.every((r) => r >= 0xE000 && r <= 0xF8FF);
          if (ratio < requiredContrast(widget.text.style, isIcon: isIcon)) {
            problems.add(
              '${isIcon ? 'icône ${text.runes.first.toRadixString(16)}' : '"$text"'} : texte ${_hex(foreground)} sur ${_hex(background)} '
              '(contraste ${ratio.toStringAsFixed(2)}:1)',
            );
          }
        }
      }
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement!.visitChildren(visit);
  return problems;
}

bool _isVisible(Element element) {
  var visible = true;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Offstage && widget.offstage) visible = false;
    if (widget is Visibility && !widget.visible) visible = false;
    return visible;
  });
  return visible;
}

/// La couleur opaque qui s'affiche derrière [element] : les calques
/// translucides sont composés sur la première surface opaque rencontrée en
/// remontant. `null` quand une image (photo) est derrière : le contraste ne
/// se calcule pas sur une photo.
Color? surfaceBehind(Element element) {
  final layers = <Color>[];
  Color? opaque;
  var onImage = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    final color = _paintedColor(ancestor, widget);
    if (widget is Image || widget is DecorationImage) onImage = true;
    if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      final decoration = widget.decoration as BoxDecoration;
      if (decoration.image != null || decoration.gradient != null) {
        onImage = true;
      }
    }
    if (color == null) return true;
    if (color.a >= 0.99) {
      opaque = color;
      return false;
    }
    layers.add(color);
    return true;
  });
  if (onImage || opaque == null) return null;
  var result = opaque!;
  for (final layer in layers) {
    result = Color.alphaBlend(layer, result);
  }
  return result;
}

Color? _paintedColor(Element element, Widget widget) {
  if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
    return (widget.decoration as BoxDecoration).color;
  }
  if (widget is ColoredBox) return widget.color;
  if (widget is Material) {
    final theme = Theme.of(element);
    return switch (widget.type) {
      MaterialType.transparency => null,
      MaterialType.canvas => widget.color ?? theme.canvasColor,
      MaterialType.card => widget.color ?? theme.cardColor,
      MaterialType.circle || MaterialType.button => widget.color,
    };
  }
  if (widget is PhysicalModel) return widget.color;
  return null;
}

/// Rapport de contraste WCAG entre deux couleurs opaques.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Photographie l'application (posée sous [darkCaptureBuilder]) dans
/// `build/dark-captures/<name>.png`.
Future<void> captureDarkPng(WidgetTester tester, String name) async {
  final boundary =
      darkCaptureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/dark-captures/$name.png')
      ..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
