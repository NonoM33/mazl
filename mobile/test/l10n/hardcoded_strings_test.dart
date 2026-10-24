import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Aucun texte visible écrit en dur dans l'interface : tout passe par
/// `context.l10n` (fichiers ARB, français en référence).
///
/// Le test lit les SOURCES de [_scannedRoots] (hors [_skippedRoots]) et relève chaque littéral qui
/// ressemble à un texte pour l'utilisateur (une lettre accentuée, une espace
/// entre deux mots, ou une majuscule en tête de mot), dans un `Text(` comme
/// dans un `title:`, un ternaire ou une constante.
///
/// CLIQUET : les textes encore en dur sont listés dans [_baselinePath]. La
/// liste ne peut que rétrécir : un texte nouveau fait échouer le test, et un
/// texte traduit doit en sortir (le test échoue aussi). Pour la raccourcir
/// après une traduction :
///
///   UPDATE_L10N_BASELINE=1 flutter test test/l10n/hardcoded_strings_test.dart
///
/// (refusé si un texte nouveau est apparu : il faut le traduire).

const _scannedRoots = ['lib/presentation', 'lib/core'];

/// Pas de l'interface : les profils et conversations de démo sont du contenu
/// écrit par des membres fictifs, servi en debug seulement.
const _skippedRoots = ['lib/core/dev'];
const _baselinePath = 'test/l10n/hardcoded_strings_baseline.txt';

/// Littéraux qui ne sont pas du texte à traduire, avec la raison.
const _notTranslatable = <String, String>{
  'mazl': 'nom de la marque',
  'MAZL': 'nom de la marque',
  'Français': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
  'English': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
  'Español': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
};

/// Littéraux d'UN fichier qui ne s'affichent jamais (message de journal,
/// motif de détection, valeur envoyée à l'API), clé « chemin | texte »,
/// avec la raison. Un texte que le membre peut voir n'a rien à faire ici.
const _notUserFacing = <String, String>{
  r'lib/core/services/api_service.dart | $diagnostic (HTTP ${response.statusCode})':
      'diagnostic de journal ; l\'écran affiche apiErrorText',
};

final _stringLiteral = RegExp(r"""('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""");
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _word = RegExp(r'[A-Za-zÀ-ÿ]{2,}');
final _accent = RegExp(r'[À-ÿ]');
final _capitalized = RegExp(r'^[A-ZÀ-Ý][a-zà-ÿ]');

/// Lignes qui ne portent pas de texte visible.
final _technicalLine = RegExp(
  r'^\s*(import|export|part|//)'
  r"|Key\(|debugPrint\(|\bprint\(|\blog\(|assert\(|RegExp\(|'assets/"
  r'|fontFamily|@visibleForTesting|semanticsIdentifier',
);

/// Vrai si [literal] (sans ses guillemets) se lit comme un texte humain.
bool looksVisible(String literal) {
  // A placeholder counts as a word-free token: « $count profils » is text.
  final text = literal.replaceAll(_interpolation, '0');
  if (!_word.hasMatch(text)) return false;
  return _accent.hasMatch(text) ||
      text.trim().contains(' ') ||
      _capitalized.hasMatch(text);
}

/// Les textes en dur d'une source, un par occurrence.
List<String> hardcodedTextsIn(String source) {
  final found = <String>[];
  for (final line in source.split('\n')) {
    if (_technicalLine.hasMatch(line)) continue;
    final code = line.split(RegExp(r'\s//')).first;
    for (final match in _stringLiteral.allMatches(code)) {
      final literal = match.group(0)!;
      final body = literal.substring(1, literal.length - 1);
      if (_notTranslatable.containsKey(body)) continue;
      if (looksVisible(body)) found.add(body);
    }
  }
  return found;
}

List<String> _scanSources() {
  final entries = <String>[];
  for (final root in _scannedRoots) {
    final files = Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !_skippedRoots.any(f.path.startsWith))
        .toList();
    for (final file in files) {
      for (final text in hardcodedTextsIn(file.readAsStringSync())) {
        final entry = '${file.path} | $text';
        if (!_notUserFacing.containsKey(entry)) entries.add(entry);
      }
    }
  }
  return entries..sort();
}

Map<String, int> _count(Iterable<String> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    counts[entry] = (counts[entry] ?? 0) + 1;
  }
  return counts;
}

void main() {
  group('hardcodedTextsIn', () {
    test('relève un texte français dans un Text(', () {
      expect(hardcodedTextsIn("Text('Mot de passe')"), ['Mot de passe']);
    });

    test('relève un texte dans un ternaire ou un argument nommé', () {
      expect(hardcodedTextsIn("subtitle: ok ? 'Vérifié' : 'Non vérifié',"), [
        'Vérifié',
        'Non vérifié',
      ]);
    });

    test('un texte interpolé reste un texte', () {
      expect(hardcodedTextsIn(r"Text('$count profils')"), [r'$count profils']);
    });

    test('ignore les clés, les routes, les imports et les commentaires', () {
      const source = '''
import 'package:mazl/core/theme/app_colors.dart';
// Texte d'exemple dans un commentaire
final key = ValueKey('Bouton envoyer');
context.push('/profile/edit');
final id = json['first_name'];
Text(context.l10n.chatTitle)
''';
      expect(hardcodedTextsIn(source), isEmpty);
    });

    test('ignore le nom de la marque', () {
      expect(hardcodedTextsIn("Text('MAZL')"), isEmpty);
    });
  });

  test('aucun texte nouveau en dur dans l\'interface (cliquet)', () {
    final current = _scanSources();
    final baselineFile = File(_baselinePath);
    final update = Platform.environment['UPDATE_L10N_BASELINE'] == '1';
    void writeBaseline() => baselineFile.writeAsStringSync(
      '# Textes encore en dur (cliquet : cette liste ne peut que rétrécir).\n'
      '# Voir test/l10n/hardcoded_strings_test.dart.\n'
      '${current.join('\n')}\n',
    );
    if (!baselineFile.existsSync() && update) {
      writeBaseline();
      return;
    }
    final baseline = baselineFile.existsSync()
        ? baselineFile
              .readAsLinesSync()
              .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
              .toList()
        : <String>[];

    final now = _count(current);
    final before = _count(baseline);
    final added = <String>[
      for (final entry in now.entries)
        if (entry.value > (before[entry.key] ?? 0)) entry.key,
    ];
    final gone = <String>[
      for (final entry in before.entries)
        if (entry.value > (now[entry.key] ?? 0)) entry.key,
    ];

    expect(
      added,
      isEmpty,
      reason:
          'Textes en dur NOUVEAUX : passez-les par context.l10n '
          '(lib/l10n/fragments/<feature>/app_fr.arb).\n${added.join('\n')}',
    );

    if (gone.isNotEmpty && update) {
      writeBaseline();
      return;
    }
    expect(
      gone,
      isEmpty,
      reason:
          'Textes traduits encore listés : relancez avec '
          'UPDATE_L10N_BASELINE=1 pour raccourcir la liste.\n${gone.join('\n')}',
    );
  });
}
