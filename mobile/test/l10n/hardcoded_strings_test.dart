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

/// Littéraux qui ne sont pas du texte à traduire, où qu'ils soient.
const _notTranslatable = <String, String>{
  'mazl': 'nom de la marque',
  'MAZL': 'nom de la marque',
  'Français': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
  'English': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
  'Español': 'nom de la langue écrit dans sa langue (AppLanguage.autonym)',
  'Authorization': 'en-tête HTTP',
  'Content-Type': 'en-tête HTTP',
  'Geist': 'nom de la police',
  'GeistMono': 'nom de la police',
};

/// Fichiers entiers dont les littéraux ne s'affichent jamais, avec la raison.
const _notUserFacingFiles = <String, String>{
  'lib/core/services/api_service.dart':
      'ApiResponse.error est un diagnostic de journal ; l\'écran affiche '
      'apiErrorText selon errorKind',
  'lib/core/chat/scam_rules.dart':
      'motifs de détection d\'arnaque appliqués aux messages reçus',
  'lib/core/services/websocket_service.dart': 'messages de journal',
};

/// Littéraux d'UN fichier qui ne s'affichent jamais (journal, valeur envoyée
/// à l'API, donnée fictive d'un écran maquette, menu de debug), avec la
/// raison. Un texte que le membre peut voir n'a rien à faire ici ; un texte
/// qui a disparu du fichier doit en sortir (un test le vérifie).
const _notUserFacing = <String, (String, List<String>)>{
  'lib/core/services/store/subscription_api.dart': (
    'en-tête HTTP',
    [r'Bearer $token'],
  ),
  'lib/core/services/store/credit_models.dart': (
    'messages de FormatException (credits du serveur illisible), journal',
    [
      r'credits.$kind.$key: entier attendu',
      r'credits.$name: objet attendu',
      'credits.resets_at: texte attendu',
      'credits: objet attendu',
    ],
  ),
  'lib/core/services/store/subscription_models.dart': (
    'messages de FormatException (réponse de vérification illisible), journal',
    [
      r'subscription.$key: texte attendu',
      'subscription.expires_at: texte attendu',
      'subscription: objet attendu',
    ],
  ),
  'lib/core/services/couple_service.dart': (
    'contenu fixe du tableau de bord, texte de repli : l\'écran traduit chaque '
        'élément par identifiant (dashboard_content_coverage_test)',
    [
      '3 mois de bonheur',
      r"30 jours d\'amour",
      '365 jours de Mazl',
      '6 mois main dans la main',
      '7 jours ensemble',
      'Action caritative en couple',
      'Apprenez la Paracha ensemble',
      'Appréciation',
      'Aventure',
      'Bien-être',
      'Comment aimeriez-vous célébrer votre prochain Shabbat ?',
      'Communauté',
      'Connexion',
      'Course, yoga, randonnée…',
      'Cuisine Shabbat',
      'Date night',
      'Dîner romantique à la maison',
      'Hesed ensemble',
      'Invitation chez des amis',
      'Judaïsme',
      'Maison',
      'Mi-année',
      'Planifiez votre prochaine escapade',
      'Premier mois',
      'Première année',
      'Première semaine',
      'Préparez le repas de Shabbat ensemble',
      r"Qu\'est-ce qui vous a fait sourire aujourd\'hui ?",
      'Quel est votre moment préféré de la semaine ensemble ?',
      'Quel trait de caractère admirez-vous le plus chez votre partenaire ?',
      'Quotidien',
      'Restaurant casher',
      'Romance',
      'Rêves',
      'Shabbaton communautaire',
      r"Si vous pouviez voyager n\'importe où, où iriez-vous ?",
      'Sortie restaurant ou cinéma',
      'Spirituel',
      'Sport ensemble',
      'Trimestre',
      'Voyage',
      'Étude Torah',
    ],
  ),
  'lib/core/services/couple_api_service.dart': (
    'messages de FormatException (réponse inattendue), journal',
    [
      r'$key holds a non-object item',
      r'$key is not a list',
      r'$key is not an object',
      'stats is not an object',
    ],
  ),
  'lib/core/chat/chat_api.dart': (
    'journal et en-tête HTTP',
    [r'Bearer $jwt', r'ChatApiException($status)'],
  ),
  'lib/core/likes/like_allowance_api.dart': (
    'en-tête HTTP',
    [r'Bearer $jwt'],
  ),
  'lib/core/chat/chat_providers.dart': (
    'journal',
    ['current user unavailable'],
  ),
  'lib/core/chat/chat_realtime.dart': (
    'mots écrits par le serveur dans lastMessage, comparés pour être traduits',
    ['Message retiré', 'Message vocal', 'Photo'],
  ),
  'lib/core/chat/voice_impl.dart': (
    'journal',
    ['only http(s) and data: addresses can be played'],
  ),
  'lib/core/models/verification.dart': (
    'journal',
    [r'unknown challenge: $value'],
  ),
  'lib/core/services/auth_service.dart': (
    'en-tête HTTP, valeur envoyée à l\'API, connexion fictive de debug',
    [
      r'Bearer ${_currentUser!.jwtToken}',
      'La connexion fictive est réservée au mode debug.',
      'Léa (démo)',
      'Non spécifié',
    ],
  ),
  'lib/core/services/session_guard.dart': (
    'en-tête HTTP',
    ['Bearer '],
  ),
  'lib/core/privacy/privacy_consent_api.dart': (
    'en-tête HTTP et message de FormatException, journal',
    [r'Bearer $token', 'unexpected response body'],
  ),
  'lib/core/privacy/religious_data_consent.dart': (
    'messages de FormatException (réponse du serveur illisible), journal',
    [r'invalid $key', r'missing $key'],
  ),
  'lib/core/web_sessions/web_session_models.dart': (
    'message de FormatException (réponse du serveur illisible), journal',
    [r'missing $key'],
  ),
  'lib/core/web_sessions/web_sessions_api.dart': (
    'en-tête HTTP et message de FormatException, journal',
    [r'Bearer $token', 'unexpected response body'],
  ),
  'lib/core/services/http_verification_api.dart': (
    'en-tête HTTP et journal',
    [r'Bearer $token', 'unexpected response body'],
  ),
  'lib/core/services/jewish_calendar_service.dart': (
    'lieu passé au calcul des heures, jamais affiché',
    ['Paris'],
  ),
  'lib/presentation/features/chat/widgets/report_sheet.dart': (
    'motif envoyé tel quel à POST …/report (table reports) ; le libellé '
        'affiché est traduit',
    [
      "Arnaque ou demande d\\'argent",
      'Autre',
      'Contenu inapproprié',
      'Harcèlement ou propos déplacés',
    ],
  ),
  'lib/core/matching/discover_filters.dart': (
    'messages de FormatException (réponse du serveur illisible), journal',
    ['discover filters', r'invalid $key'],
  ),
  'lib/core/matching/discover_filters_api.dart': (
    'en-tête HTTP, diagnostics de journal et message de FormatException',
    [r'Bearer $token', 'Discover filters', 'unexpected response body'],
  ),
  'lib/presentation/features/matching/l10n/filter_options.dart': (
    'réponses de profil envoyées au serveur, qui les compare telles quelles '
        '(sans casse ni espaces) ; les libellés affichés sont traduits',
    [
      'A la maison',
      'Cacher a la maison',
      'Chabad',
      'Glatt',
      'Habad',
      'Home',
      'Kasher a la maison',
      'Kasher strict',
      'Laique',
      'Laïque',
      'Liberal',
      'Liberale',
      'Libéral',
      'Libérale',
      'Loubavitch',
      'Masorti',
      'Massorti',
      'Modern Orthodox',
      'No',
      'Non',
      'Non observant',
      'None',
      'Not observant',
      'Observant',
      'Orthodox',
      'Orthodoxe',
      'Orthodoxe moderne',
      'Partial',
      'Partially',
      'Partiellement',
      'Strict',
      'Traditionaliste',
      'Tres observant',
      'Très observant',
      'À la maison',
    ],
  ),
  'lib/presentation/features/profile/screens/edit_profile_screen.dart': (
    'valeurs envoyées à l\'API et comparées par le classement du serveur ; '
        'les libellés affichés sont traduits',
    [
      'A la maison',
      'Autre',
      'Glatt',
      'Habad',
      'Laique',
      'Massorti',
      'Modern Orthodox',
      'Non',
      'Non observant',
      'Observant',
      'Orthodox',
      'Partiellement',
      'Strict',
      'Traditionaliste',
      'Tres observant',
    ],
  ),
  'lib/presentation/features/settings/screens/settings_screen.dart': (
    'menu « Debug (Dev Only) », visible seulement en kDebugMode',
    [
      r'- ID ${c[',
      'Activer Couple',
      r'Couple ID: ${activeCouple[',
      'Debug (Dev Only)',
      'Désactiver Couple',
      r'Erreur: $e',
      'Fermer',
      r'Historique (${allCouples.length} couples):',
      'Menu Debug',
      r'Mode couple actif: ${activeCouple != null ? "OUI" : "NON"}',
      'Mode couple activé',
      'Mode couple désactivé',
      r'Partner: ${activeCouple[',
      'Refusé par le serveur',
      'Reset Swipes',
      'Status Couple',
      'Status Couple (Debug)',
      r'Status: ${activeCouple[',
      'Swipes reset',
      r'User ID: $userId',
      r']} (partner: ${c[',
    ],
  ),
  'lib/core/services/api_service.dart': (
    'diagnostic de journal ; l\'écran affiche apiErrorText',
    [r'$diagnostic (HTTP ${response.statusCode})'],
  ),
};

bool _isNotUserFacing(String path, String text) =>
    _notUserFacingFiles.containsKey(path) ||
    (_notUserFacing[path]?.$2.contains(text) ?? false);

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
        if (!_isNotUserFacing(file.path, text)) {
          entries.add('${file.path} | $text');
        }
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

  test('chaque exception sert encore (sinon, la retirer)', () {
    final stale = <String>[];
    for (final path in _notUserFacingFiles.keys) {
      if (!File(path).existsSync()) stale.add(path);
    }
    for (final entry in _notUserFacing.entries) {
      final file = File(entry.key);
      final found = file.existsSync()
          ? hardcodedTextsIn(file.readAsStringSync()).toSet()
          : <String>{};
      for (final text in entry.value.$2) {
        if (!found.contains(text)) stale.add('${entry.key} | $text');
      }
    }
    expect(stale, isEmpty, reason: stale.join('\n'));
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
