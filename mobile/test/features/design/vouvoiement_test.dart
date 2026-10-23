import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le chapitre « voix » du design system impose le vouvoiement partout :
/// titres, aides, erreurs, messages, dialogues, états vides.
///
/// Ce test lit les SOURCES (littéraux de chaîne uniquement) : il échoue dès
/// qu'un texte de l'application s'adresse à l'utilisateur avec « tu ».

/// Dossiers scannés.
const _scannedRoots = ['lib/presentation', 'lib/core/services'];

/// Formes de tutoiement, mot entier, sans tenir compte de la casse.
final _tuForms = RegExp(
  r"(?<![\wÀ-ÿ])(tu|toi|ton|ta|tes|te)(?![\wÀ-ÿ])"
  r"|(?<![\wÀ-ÿ])t['’](?=[a-zà-ÿ])"
  r'|-(tu|toi)(?![\wÀ-ÿ])',
  caseSensitive: false,
);

/// Impératifs de tutoiement en tête de phrase (le « tu » est sous-entendu).
final _tuImperatives = RegExp(
  r'^(Ajoute|Complète|Découvre|Indique|Fais|Envoie|Annule|Sache|Obtiens|'
  r'Sois|Clique|Vérifie|Parle|Réponds|Montre|Choisis|Prends|Reviens|'
  r'Rejoins|Apprends|Tape|Décris|Maintiens|Connecte|Inscris|Swipe|'
  r'Verifie|Complete|Decouvre|Reponds)(?![\wÀ-ÿ])',
);

final _stringLiteral = RegExp(r"""('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""");
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');

/// Fichiers dont le tutoiement est LEGITIME, avec la raison.
const _allowedFiles = <String, String>{
  // Ces phrases ne sont pas la voix de l'application : ce sont des brouillons
  // de premier message que le membre envoie à un autre membre (« Tu as voyagé
  // où récemment ? »). Entre deux membres d'une application de rencontres,
  // le tutoiement est le registre naturel ; le vouvoiement ferait fausse note
  // dans la bouche de l'utilisateur. L'application, elle, vouvoie le membre
  // partout ailleurs.
  'lib/core/services/icebreaker_service.dart':
      'messages d\'accroche écrits au nom du membre pour un autre membre',
};

/// Littéraux précis tolérés pour l'instant.
const _allowedLiterals = <String, String>{
  // discover_screen.dart est en cours de modification par une autre
  // personne : ces deux messages seront vouvoyés dans sa livraison. Retirer
  // ces entrées dès que c'est fait (le test les signalera alors comme
  // périmées).
  'Boost activé ! Tu seras visible en priorité pendant 30 minutes.':
      'discover_screen.dart, à vouvoyer par l\'autre chantier',
  'Tu as matché avec ':
      'discover_screen.dart, à vouvoyer par l\'autre chantier',
};

/// Violations d'un texte : liste des fragments fautifs.
List<String> tutoiementsDans(String literal) {
  final text = literal.replaceAll(_interpolation, ' ');
  final found = <String>[];
  for (final match in _tuForms.allMatches(text)) {
    found.add(match.group(0)!);
  }
  final imperative = _tuImperatives.firstMatch(text.trimLeft());
  if (imperative != null) {
    found.add(imperative.group(0)!);
  }
  return found;
}

class _Violation {
  _Violation(this.file, this.line, this.literal, this.fragments);

  final String file;
  final int line;
  final String literal;
  final List<String> fragments;

  @override
  String toString() => '$file:$line  ${fragments.join(', ')}  ->  "$literal"';
}

List<_Violation> _scan(List<String> allowedUsed) {
  final violations = <_Violation>[];
  for (final root in _scannedRoots) {
    final files =
        Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final path = file.path;
      if (_allowedFiles.containsKey(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('import ')) continue;
        for (final m in _stringLiteral.allMatches(line)) {
          final body = m.group(1)!.substring(1, m.group(1)!.length - 1);
          final fragments = tutoiementsDans(body);
          if (fragments.isEmpty) continue;
          final allowed = _allowedLiterals.keys
              .where((known) => body.startsWith(known))
              .toList();
          if (allowed.isNotEmpty) {
            allowedUsed.addAll(allowed);
            continue;
          }
          violations.add(_Violation(path, i + 1, body, fragments));
        }
      }
    }
  }
  return violations;
}

void main() {
  group('Détecteur de tutoiement', () {
    test('repère les formes de tutoiement dans un texte', () {
      for (final texte in const [
        'Complète ton profil',
        'Indique ta ville',
        'Inscris-toi',
        'Connecte-toi',
        'Parle de toi...',
        'Tu as matché avec Léa',
        'Swipe autant que tu veux',
        'Es-tu sûr de vouloir te déconnecter ?',
        "Qu'est-ce qui t'a fait sourire ?",
        'Ajoute au moins 2 photos',
        'Vérifie ta connexion',
      ]) {
        expect(tutoiementsDans(texte), isNotEmpty, reason: texte);
      }
    });

    test('laisse passer le vouvoiement et les mots qui contiennent « ta »', () {
      for (final texte in const [
        'Complétez votre profil',
        'Indiquez votre ville',
        'Créer un compte',
        'Se connecter',
        'Parlez de vous…',
        'Vous avez matché avec Léa',
        'Likez autant que vous voulez',
        'Cette action est irréversible.',
        'Détails',
        'Statut de vérification : \$label',
        'Content-Type',
        'Bienvenue sur MAZL',
      ]) {
        expect(tutoiementsDans(texte), isEmpty, reason: texte);
      }
    });

    test('ignore les interpolations de code', () {
      expect(tutoiementsDans(r'${user.ta} a répondu'), isEmpty);
    });
  });

  group('Vouvoiement dans l\'application', () {
    test('aucun texte de lib/presentation ni lib/core/services ne tutoie', () {
      final allowedUsed = <String>[];
      final violations = _scan(allowedUsed);

      expect(
        violations,
        isEmpty,
        reason:
            'Textes à vouvoyer (« vous », « votre ») :\n'
            '${violations.join('\n')}',
      );
    });

    test('les dérogations temporaires sont encore nécessaires', () {
      final allowedUsed = <String>[];
      _scan(allowedUsed);

      final stale = _allowedLiterals.keys
          .where((known) => !allowedUsed.contains(known))
          .toList();
      expect(
        stale,
        isEmpty,
        reason:
            'Ces dérogations ne servent plus, les retirer de '
            '_allowedLiterals : $stale',
      );
    });

    test('les fichiers autorisés existent encore', () {
      for (final path in _allowedFiles.keys) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}
