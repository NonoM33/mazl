import 'dart:convert';
import 'dart:io';

/// Les traductions vivent en fragments, un dossier par feature :
/// `lib/l10n/fragments/<feature>/app_<langue>.arb`. Chaque écran possède
/// ses clés ; deux chantiers parallèles ne touchent jamais le même fichier.
///
/// `flutter gen-l10n` ne lit qu'un fichier par langue : on les assemble dans
/// `lib/l10n/app_<langue>.arb`, features dans l'ordre alphabétique, clés dans
/// l'ordre du fragment.
const fragmentsDir = 'lib/l10n/fragments';
const assembledDir = 'lib/l10n';

final _fragmentName = RegExp(r'^app_([a-z]{2,3}(?:_[A-Z]{2})?)\.arb$');

class ArbMergeException implements Exception {
  ArbMergeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Langue → feature → contenu du fragment, lu sur le disque.
Map<String, Map<String, Map<String, Object?>>> readFragments(Directory root) {
  final byLocale = <String, Map<String, Map<String, Object?>>>{};
  final features = root.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final feature in features) {
    final name = feature.uri.pathSegments.where((s) => s.isNotEmpty).last;
    for (final file in feature.listSync().whereType<File>()) {
      final match = _fragmentName.firstMatch(file.uri.pathSegments.last);
      if (match == null) continue;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) {
        throw ArbMergeException('${file.path} : un objet JSON est attendu');
      }
      byLocale.putIfAbsent(match.group(1)!, () => {})[name] = decoded;
    }
  }
  return byLocale;
}

/// Assemble les fragments d'une langue. Une clé définie dans deux features
/// est une erreur : chaque texte a un seul propriétaire.
Map<String, Object?> mergeLocale(
  String locale,
  Map<String, Map<String, Object?>> fragments,
) {
  final merged = <String, Object?>{'@@locale': locale};
  final owner = <String, String>{};
  final features = fragments.keys.toList()..sort();
  for (final feature in features) {
    for (final entry in fragments[feature]!.entries) {
      if (entry.key == '@@locale') continue;
      final previous = owner[entry.key];
      if (previous != null) {
        throw ArbMergeException(
          '« ${entry.key} » ($locale) est défini dans $previous et $feature',
        );
      }
      owner[entry.key] = feature;
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

String encodeArb(Map<String, Object?> arb) =>
    '${const JsonEncoder.withIndent('  ').convert(arb)}\n';

/// Le contenu attendu de chaque `app_<langue>.arb`, nom de fichier → texte.
Map<String, String> expectedAssembledFiles(Directory root) => {
  for (final entry in readFragments(root).entries)
    'app_${entry.key}.arb': encodeArb(mergeLocale(entry.key, entry.value)),
};
