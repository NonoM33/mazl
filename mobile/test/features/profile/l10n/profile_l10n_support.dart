import 'dart:io';

import 'package:flutter/services.dart';

/// Les vraies polices, pour que le texte se mesure comme sur un téléphone :
/// sans elles, le moteur de test dessine chaque lettre en grand carré et
/// « Serious relationship » déborde à 360 px alors qu'il tient très bien.
Future<void> loadAppFonts() async {
  final geist = FontLoader('Geist');
  for (final weight in ['400', '500', '600', '700']) {
    geist.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Geist-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await geist.load();
  final mono = FontLoader('GeistMono');
  for (final weight in ['400', '500']) {
    mono.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/GeistMono-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await mono.load();
}
