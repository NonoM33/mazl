import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/l10n/arb_merge.dart';

/// Une clé de traduction que plus aucun écran ne lit est supprimée dans les
/// cinq langues (règle du lot : le texte d'une fonction retirée part avec
/// elle). Le français est la référence des clés.
void main() {
  test('chaque clé des fragments est lue par du code de l\'app', () {
    final source = StringBuffer();
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.startsWith('lib/l10n/generated/')) continue;
      source.writeln(entity.readAsStringSync());
    }
    final code = source.toString();

    final reference = readFragments(Directory(fragmentsDir))['fr'] ?? {};
    final unused = <String>[
      for (final feature in reference.entries)
        for (final key in feature.value.keys)
          if (!key.startsWith('@') && !RegExp('\\b$key\\b').hasMatch(code))
            '${feature.key}/$key',
    ];

    expect(unused, isEmpty, reason: unused.join('\n'));
  });
}
