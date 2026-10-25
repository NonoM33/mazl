import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/l10n/arb_merge.dart';

/// Décision de Renaud du 2026-10-25 : MAZL n'a aucune fonction d'intelligence
/// artificielle en v1 (l'« AI Shadchan » a été supprimé). Aucun texte de l'app,
/// dans aucune des cinq langues, ne doit en promettre une.
void main() {
  final words = RegExp(
    r'shadchan|intelligence artificielle|artificial intelligence|'
    r'inteligencia artificial|искусственн|בינה מלאכותית|שדכן',
    caseSensitive: false,
  );
  // Les sigles en majuscules seulement : « J'ai » n'est pas une IA.
  final acronym = RegExp(r'\b(AI|IA)\b');

  test('aucun texte de l\'app ne promet une intelligence artificielle', () {
    final fragments = readFragments(Directory(fragmentsDir));
    final offenders = <String>[];
    for (final byLocale in fragments.entries) {
      for (final feature in byLocale.value.entries) {
        for (final entry in feature.value.entries) {
          final value = entry.value;
          if (entry.key.startsWith('@') || value is! String) continue;
          if (words.hasMatch(value) || acronym.hasMatch(value)) {
            offenders.add('${byLocale.key}/${feature.key} ${entry.key}');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
