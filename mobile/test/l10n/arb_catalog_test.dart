import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/l10n/app_language.dart';

import '../../tool/l10n/arb_merge.dart';

/// Le catalogue des traductions : le français est la référence, chaque autre
/// langue doit en porter toutes les clés, avec les mêmes paramètres, et rien
/// d'autre.
void main() {
  final root = Directory(fragmentsDir);
  final fragments = readFragments(root);
  final reference = fragments['fr'] ?? {};

  test('chaque langue de l\'app a ses fragments', () {
    for (final language in AppLanguage.values) {
      expect(fragments.keys, contains(language.code), reason: language.name);
    }
    expect(
      fragments.keys.toSet(),
      AppLanguage.values.map((l) => l.code).toSet(),
      reason: 'un fragment pour une langue que l\'app ne propose pas',
    );
  });

  test('les fichiers assemblés sont à jour (dart run tool/l10n.dart)', () {
    final expected = expectedAssembledFiles(root);
    for (final entry in expected.entries) {
      final file = File('$assembledDir/${entry.key}');
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(
        file.readAsStringSync(),
        entry.value,
        reason: '${entry.key} ne correspond plus aux fragments',
      );
    }
  });

  test('aucune clé n\'a deux propriétaires', () {
    for (final entry in fragments.entries) {
      expect(() => mergeLocale(entry.key, entry.value), returnsNormally);
    }
  });

  group('chaque clé existe dans toutes les langues', () {
    for (final language in AppLanguage.values.where((l) => l.code != 'fr')) {
      test(language.autonym, () {
        final translated = fragments[language.code] ?? {};
        final problems = <String>[];
        for (final feature in {...reference.keys, ...translated.keys}) {
          final expected = _messageKeys(reference[feature]);
          final actual = _messageKeys(translated[feature]);
          for (final key in expected.difference(actual)) {
            problems.add('$feature : « $key » manque');
          }
          for (final key in actual.difference(expected)) {
            problems.add('$feature : « $key » n\'existe pas en français');
          }
          for (final key in expected.intersection(actual)) {
            final value = translated[feature]![key];
            if (value is! String || value.trim().isEmpty) {
              problems.add('$feature : « $key » est vide');
            }
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  test('chaque clé française explique son contexte au traducteur', () {
    final problems = <String>[];
    for (final entry in reference.entries) {
      for (final key in _messageKeys(entry.value)) {
        final meta = entry.value['@$key'];
        final description = meta is Map ? meta['description'] : null;
        if (description is! String || description.trim().isEmpty) {
          problems.add('${entry.key} : « @$key.description » manque');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('chaque traduction garde les paramètres du français', () {
    final problems = <String>[];
    for (final entry in reference.entries) {
      for (final key in _messageKeys(entry.value)) {
        final meta = entry.value['@$key'];
        final placeholders = meta is Map && meta['placeholders'] is Map
            ? (meta['placeholders'] as Map).keys.cast<String>()
            : const <String>[];
        for (final language in fragments.keys.where((c) => c != 'fr')) {
          final value = fragments[language]![entry.key]?[key];
          if (value is! String) continue;
          for (final name in placeholders) {
            if (!RegExp('\\{$name[},]').hasMatch(value)) {
              problems.add('$language/${entry.key} : « $key » perd {$name}');
            }
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('aucun compte de démo, adresse ou secret dans les traductions', () {
    final forbidden = <String, RegExp>{
      'adresse e-mail': RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'),
      'jeton ou clé': RegExp(
        r'(one_pat_|sk_live|sk_test|appl_|goog_|Bearer\s)|[A-Za-z0-9_-]{32,}',
      ),
      'compte de démo': RegExp(
        r'\bdemo\b|mot de passe\s*:',
        caseSensitive: false,
      ),
    };
    final problems = <String>[];
    for (final file
        in Directory(fragmentsDir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.arb'))) {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      for (final entry in arb.entries.where((e) => !e.key.startsWith('@'))) {
        for (final rule in forbidden.entries) {
          if (rule.value.hasMatch('${entry.value}')) {
            problems.add(
              '${file.path} : « ${entry.key} » contient un(e) ${rule.key}',
            );
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}

Set<String> _messageKeys(Map<String, Object?>? arb) =>
    (arb ?? const {}).keys.where((k) => !k.startsWith('@')).toSet();
