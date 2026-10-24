import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge la vraie police de l'app (Geist) : sans elle, les tests de widgets
/// dessinent avec « Ahem », où chaque lettre fait un em de large, ce qui
/// rend toute mesure de largeur de texte fausse.
Future<void> loadAppFont() async {
  final loader = FontLoader('Geist');
  for (final weight in ['400', '500', '600', '700']) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Geist-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await loader.load();
}

/// Les textes dont un mot est plus large que la place qu'on lui donne.
///
/// Flutter ne lève pas d'erreur quand un mot insécable dépasse (le texte
/// déborde en silence) : `RenderFlex` ne voit que les lignes de widgets. On
/// compare donc, pour chaque paragraphe rendu, la largeur de son plus grand
/// mot insécable à la largeur reçue. À appeler après [loadAppFont].
List<String> wordsTooWide(WidgetTester tester) {
  final problems = <String>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph && node.hasSize) {
      final widest = node.getMinIntrinsicWidth(double.infinity);
      if (widest > node.size.width + 0.5) {
        problems.add(
          '« ${node.text.toPlainText()} » : mot de ${widest.toStringAsFixed(1)} px '
          'dans ${node.size.width.toStringAsFixed(1)} px',
        );
      }
    }
    node.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  return problems;
}
