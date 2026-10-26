import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou du mode sombre : aucune couleur de clair fixée en dur dans les
/// widgets. Une surface en `Colors.white` ou un texte en `Colors.grey[600]`
/// reste clair quand le thème passe en sombre, et le texte du thème, lui,
/// devient clair : du gris clair sur du blanc, illisible (vu sur iPhone).
///
/// Ce test refuse toute nouvelle ligne qui emploie `Colors.white`,
/// `Colors.black`, `Colors.grey…`, `Colors.blueGrey…`, une constante
/// `AppColors` propre au thème clair (paper, mist, ink, muted, hairline,
/// dividerLight, …) ou un `Color(0x…)` littéral dans `lib/presentation` et
/// `lib/core/widgets`, sauf si elle figure dans [_allowed] avec sa raison.
///
/// Les exceptions ne peuvent que RETRÉCIR : une entrée devenue inutile fait
/// échouer le test, il faut alors la retirer.
final _fixedColor = RegExp(
  r'Colors\.(white|black|grey|blueGrey)|'
  r'AppColors\.(paper|mist|ink|muted|hairline|dividerLight|cardLight|'
  r'surfaceLight|backgroundLight|textPrimaryLight|textSecondaryLight|'
  r'textTertiaryLight)\b|Color\(0x',
);

const _roots = ['lib/presentation', 'lib/core/widgets'];

class _Allowed {
  const _Allowed(this.reason, this.lines);

  final String reason;
  final List<(String, int)> lines;
}

/// Fichier -> raison et lignes autorisées (texte de la ligne, occurrences).
const _allowed = <String, _Allowed>{
  'lib/presentation/common/widgets/block_report_dialog.dart':
      _Allowed('texte blanc sur boutons rouges et indicateurs de chargement', [
        ('foregroundColor: Colors.white,', 2),
        ('valueColor: AlwaysStoppedAnimation(Colors.white),', 2),
      ]),
  'lib/presentation/common/widgets/mazl_components.dart': _Allowed(
    'puce « onDark » posee sur un fond sombre ou une photo (fond blanc voulu)',
    [
      ('color: AppColors.textTertiaryLight,', 1),
      ('? Colors.white', 1),
      ('final foreground = onDark ? AppColors.ink : scheme.onSurface;', 1),
    ],
  ),
  'lib/presentation/common/widgets/swipe_deck/swipe_intent_discs.dart':
      _Allowed(
        'disque papier du geste de la pioche, identique en clair et en sombre',
        [('color: AppColors.paper,', 1)],
      ),
  'lib/presentation/features/boost/screens/boost_screen.dart':
      _Allowed('carte degrade violet/vert : texte blanc sur fond colore', [
        (': [const Color(0xFF6C5CE7), const Color(0xFFa29bfe)],', 1),
        ('color: (isActive ? AppColors.success : const Color(0xFF6C5CE7))', 1),
        ('color: Colors.white.withValues(alpha: 0.2),', 1),
        ('color: Colors.white,', 2),
        ('color: Colors.white.withValues(alpha: 0.9),', 2),
        ('backgroundColor: Colors.white.withValues(alpha: 0.3),', 1),
        ('valueColor: const AlwaysStoppedAnimation(Colors.white),', 1),
        ('backgroundColor: const Color(0xFF6C5CE7),', 1),
        ('foregroundColor: Colors.white,', 1),
        ('valueColor: AlwaysStoppedAnimation(Colors.white),', 1),
      ]),
  'lib/presentation/features/chat/widgets/message_actions_overlay.dart':
      _Allowed(
        'voile noir derriere le menu contextuel et branche sombre/clair',
        [
          ('color: Colors.black.withValues(', 1),
          ('color: dark ? AppColors.dividerDark : AppColors.hairline,', 1),
        ],
      ),
  'lib/presentation/features/chat/widgets/photo_grid.dart':
      _Allowed('voile noir et texte blanc sur photo floutee', [
        ('color: Colors.black.withValues(alpha: 0.45),', 2),
        ('color: Colors.white,', 2),
        ('const Icon(LucideIcons.eye, size: 16, color: Colors.white),', 1),
      ]),
  'lib/presentation/features/chat/widgets/photo_viewer.dart':
      _Allowed('visionneuse plein ecran noire, controles blancs sur photo', [
        ('backgroundColor: Colors.black.withValues(', 1),
        ('color: Colors.white,', 1),
        ('color: Colors.white.withValues(', 1),
      ]),
  'lib/presentation/features/chat/widgets/reaction_bar.dart': _Allowed(
    'branche explicite sombre/clair du trait de separation',
    [('color: dark ? AppColors.dividerDark : AppColors.hairline,', 1)],
  ),
  'lib/presentation/features/couple/screens/couple_activities_feed_screen.dart':
      _Allowed(
        'icone du geste « passer » posee sur un disque papier de la pioche',
        [('color: AppColors.muted,', 1)],
      ),
  'lib/presentation/features/couple/screens/couple_events_screen.dart':
      _Allowed('texte blanc sur bouton d erreur', [
        ('foregroundColor: Colors.white,', 1),
      ]),
  'lib/presentation/features/couple/screens/couple_mode_setup_screen.dart':
      _Allowed('trait de separation avec branche explicite sombre/clair', [
        (': AppColors.hairline;', 1),
      ]),
  'lib/presentation/features/couple/screens/couple_space_screen.dart': _Allowed(
    'souvenirs sur teinte pastel de photo avec texte encre (paire fixe), texte blanc sur photo',
    [
      ('Icon(_icon, size: 28, color: AppColors.textTertiaryLight),', 1),
      ('color: AppColors.ink,', 1),
      ('color: Colors.white,', 1),
    ],
  ),
  'lib/presentation/features/couple/screens/mazel_tov_screen.dart': _Allowed(
    'ecran de celebration volontairement sombre (encre), texte blanc',
    [
      ('barrierColor: AppColors.ink,', 1),
      ('backgroundColor: AppColors.ink,', 1),
      ('color: Colors.white,', 3),
      (
        'child: const Icon(LucideIcons.heart, color: Colors.white, size: 22),',
        1,
      ),
      ('border: Border.all(color: Colors.white.withValues(alpha: 0.2)),', 1),
      ('backgroundColor: Colors.white,', 1),
      ('foregroundColor: AppColors.ink,', 1),
    ],
  ),
  'lib/presentation/features/couple/widgets/activity_visual.dart': _Allowed(
    'icone sur teinte pastel de photo (paire fixe)',
    [('color: AppColors.textTertiaryLight,', 1)],
  ),
  'lib/presentation/features/couple/widgets/couple_request_dialog.dart':
      _Allowed('branche explicite sombre/clair du trait', [
        (
          'Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.hairline;',
          1,
        ),
      ]),
  'lib/presentation/features/couple/widgets/event_category.dart': _Allowed(
    'icone sur teinte pastel de photo (paire fixe)',
    [('color: AppColors.textTertiaryLight,', 1)],
  ),
  'lib/presentation/features/duo_tutorial/screens/duo_tutorial_screen.dart':
      _Allowed('tutoriel toujours sur papier blanc (theme clair force)', [
        ('backgroundColor: AppColors.paper,', 1),
        ('color: AppColors.muted,', 1),
        ('style: TextButton.styleFrom(foregroundColor: AppColors.muted),', 1),
      ]),
  'lib/presentation/features/duo_tutorial/widgets/duo_check.dart': _Allowed(
    'tutoriel toujours sur papier blanc (theme clair force)',
    [('..color = AppColors.paper', 1)],
  ),
  'lib/presentation/features/duo_tutorial/widgets/duo_step_indicator.dart':
      _Allowed('tutoriel toujours sur papier blanc (theme clair force)', [
        ('color: i <= index ? AppColors.tekhelet : AppColors.hairline,', 1),
      ]),
  'lib/presentation/features/events/screens/event_detail_screen.dart': _Allowed(
    'boutons ronds et icones blancs sur photo, ombre sous la barre du bas',
    [
      (
        'child: Center(child: Icon(typeIcon, size: 80, color: Colors.white54)),',
        1,
      ),
      ('backgroundColor: Colors.black26,', 2),
      (
        'child: DirectionalIcon(LucideIcons.arrowLeft, color: Colors.white),',
        1,
      ),
      ('child: Icon(LucideIcons.share2, color: Colors.white),', 1),
      ('color: Colors.white,', 1),
      ('color: Colors.black.withValues(alpha: 0.05),', 1),
    ],
  ),
  'lib/presentation/features/events/screens/events_list_screen.dart': _Allowed(
    'texte blanc sur puce de type selectionnee et sur photo d evenement, ombres',
    [
      ('color: Colors.black.withValues(alpha: 0.03),', 1),
      ('? Colors.white', 2),
      ('valueColor: AlwaysStoppedAnimation<Color>(Colors.white),', 1),
      ('style: const TextStyle(color: Colors.white, fontSize: 12),', 1),
      ('Colors.white.withValues(alpha: 0.5),', 1),
      ('color: Colors.white54,', 2),
      ('Colors.black.withValues(alpha: 0.4),', 1),
      ('Icon(typeIcon, size: 14, color: Colors.white),', 1),
      ('color: Colors.white,', 3),
      ('color: event.price > 0 ? Colors.white : AppColors.success,', 1),
      ('color: Colors.black.withValues(alpha: 0.15),', 1),
      (': Colors.white,', 1),
    ],
  ),
  'lib/presentation/features/matching/screens/daily_picks_screen.dart': _Allowed(
    'cartes posees sur des photos : voile noir, pastilles blanches, texte blanc sur photo',
    [
      ('color: Colors.black.withValues(alpha: 0.1),', 1),
      ('child: CircularProgressIndicator(color: Colors.white),', 1),
      ('color: Colors.white.withValues(alpha: 0.3),', 1),
      ('Colors.black.withValues(alpha: 0.7),', 1),
      ('color: Colors.white,', 5),
      ('color: Colors.white70,', 2),
    ],
  ),
  'lib/presentation/features/matching/screens/discover_screen.dart': _Allowed(
    'icone du geste « passer » posee sur un disque papier de la pioche',
    [('color: AppColors.muted,', 1)],
  ),
  'lib/presentation/features/matching/screens/filters_screen.dart': _Allowed(
    'texte blanc sur bouton ou bandeau tekhelet/degrade premium, bordure de section deja thematisee',
    [
      ('foregroundColor: Colors.white,', 1),
      ('color: Colors.white,', 2),
      ('const Icon(LucideIcons.plus, color: Colors.white),', 1),
      ('style: const TextStyle(color: Colors.white70, fontSize: 12),', 1),
      ('backgroundColor: Colors.white,', 1),
    ],
  ),
  'lib/presentation/features/matching/widgets/discover_card.dart':
      _Allowed('pastille et ombre posees sur la photo du profil', [
        ('color: AppColors.ink.withValues(alpha: 0.18),', 1),
        ('color: AppColors.ink,', 2),
        ('color: Colors.white,', 1),
      ]),
  'lib/presentation/features/navigation/widgets/mazl_nav_bar.dart': _Allowed(
    'barre encre flottante identique en clair et en sombre (cardDark en sombre)',
    [
      ('color: isDark ? AppColors.cardDark : AppColors.ink,', 3),
      ('child: Icon(item.icon, size: 22, color: Colors.white),', 1),
      ('final color = selected ? Colors.white : AppColors.iconOnInk;', 1),
      ('color: selected ? Colors.white : Colors.transparent,', 1),
    ],
  ),
  'lib/presentation/features/privacy/widgets/analytics_consent_sheet.dart':
      _Allowed(
        'branche explicite : surfaceContainerHighest en sombre, brume en clair',
        [(': AppColors.mist,', 1)],
      ),
  'lib/presentation/features/privacy/widgets/religious_consent_sheet.dart':
      _Allowed(
        'branche explicite : surfaceContainerHighest en sombre, brume en clair',
        [(': AppColors.mist,', 1)],
      ),
  'lib/presentation/features/profile/screens/edit_profile_screen.dart': _Allowed(
    'texte blanc sur boutons colores et sur photo (voile), badges sur photo',
    [
      ('foregroundColor: Colors.white,', 2),
      ('color: Colors.white,', 3),
      ('child: CircularProgressIndicator(color: Colors.white),', 1),
      ('color: Colors.white54,', 1),
      ('color: Colors.black54,', 1),
    ],
  ),
  'lib/presentation/features/profile/screens/profile_setup_screen.dart': _Allowed(
    'texte blanc sur puce selectionnee, badges et bandeau colores, sur photo',
    [
      ('color: Colors.white,', 1),
      ('const Icon(LucideIcons.compass, color: Colors.white),', 1),
      ('style: const TextStyle(color: Colors.white, fontSize: 13),', 1),
      ('color: selected ? Colors.white : null,', 1),
      ('color: Colors.white54,', 1),
    ],
  ),
  'lib/presentation/features/profile/widgets/profile_prompts_section.dart':
      _Allowed('texte blanc sur bouton rouge, ombre 5 % noir sous une carte', [
        ('foregroundColor: Colors.white,', 1),
        ('color: Colors.black.withValues(alpha: 0.05),', 1),
      ]),
  'lib/presentation/features/profile/widgets/profile_view/profile_photo_gallery.dart':
      _Allowed('compteur encre/blanc pose sur la photo', [
        ('color: AppColors.ink,', 1),
        (
          'child: Text(\'\$current/\$total\', style: AppTypography.eyebrow(Colors.white)),',
          1,
        ),
      ]),
  'lib/presentation/features/profile/widgets/relationship_intention_selector.dart':
      _Allowed('texte et icone blancs sur puce selectionnee tekhelet', [
        ('color: isSelected ? Colors.white : AppColors.primary,', 1),
        ('? Colors.white', 1),
      ]),
  'lib/presentation/features/settings/screens/blocked_users_screen.dart':
      _Allowed('texte blanc sur bouton tekhelet', [
        ('foregroundColor: Colors.white,', 1),
      ]),
  'lib/presentation/features/settings/screens/settings_screen.dart': _Allowed(
    'texte blanc sur boutons colores (tekhelet, erreur, orange), voile noir de chargement',
    [('foregroundColor: Colors.white,', 5), ('color: Colors.black26,', 1)],
  ),
  'lib/presentation/features/settings/widgets/shabbat_hero.dart': _Allowed(
    'page volontairement sombre (bougies de shabbat), identique en clair et en sombre',
    [
      ('static const _eyebrowColor = Color(0xFF8E8B84);', 1),
      ('static const _hairline = Color(0xFF26262C);', 1),
      (
        'child: DirectionalIcon(LucideIcons.chevronLeft, size: 26, color: Colors.white),',
        1,
      ),
      ('color: Color(0xFF3A3A42),', 1),
    ],
  ),
  'lib/presentation/features/verification/identity/identity_parts.dart':
      _Allowed('icone blanche sur pastille pleine tekhelet', [
        (
          'child: Icon(icon, size: size * 0.46, color: filled ? Colors.white : scheme.onSurface),',
          1,
        ),
      ]),
  'lib/presentation/features/web_sessions/screens/web_scan_screen.dart':
      _Allowed('page camera volontairement noire (scan de QR)', [
        ('icon: const Icon(Icons.close, color: Colors.white),', 1),
        ('backgroundColor: Colors.black,', 1),
        ('color: Colors.white,', 1),
        ('const CircularProgressIndicator(color: Colors.white),', 1),
        ('color: Colors.white70,', 1),
      ]),
  'lib/presentation/features/web_sessions/widgets/qr_scanner_view.dart':
      _Allowed('cadre blanc de visee sur le flux camera', [
        ('color: Colors.white,', 1),
      ]),
  'lib/presentation/widgets/skeletons.dart': _Allowed(
    'masque du shimmer : seule la forme compte, les couleurs de base et de reflet viennent du theme',
    [
      ('baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,', 1),
      ('highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,', 1),
      ('color: Colors.white,', 4),
      ('color: Colors.grey[300],', 3),
    ],
  ),
};

Map<String, Map<String, int>> _scan() {
  final found = <String, Map<String, int>>{};
  for (final root in _roots) {
    for (final entity in Directory(root).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final raw in entity.readAsLinesSync()) {
        final line = raw.trim();
        if (line.startsWith('//')) continue;
        if (!_fixedColor.hasMatch(line)) continue;
        final perFile = found.putIfAbsent(entity.path, () => {});
        perFile[line] = (perFile[line] ?? 0) + 1;
      }
    }
  }
  return found;
}

void main() {
  test('aucune couleur de thème clair fixée en dur hors exceptions', () {
    final found = _scan();
    final violations = <String>[];
    found.forEach((file, lines) {
      final allowed = {
        for (final (text, count) in _allowed[file]?.lines ?? <(String, int)>[])
          text: count,
      };
      lines.forEach((text, count) {
        if (count > (allowed[text] ?? 0)) {
          violations.add('$file : $text');
        }
      });
    });
    expect(
      violations,
      isEmpty,
      reason:
          'Utiliser Theme.of(context).colorScheme (surface, onSurface, '
          'onSurfaceVariant, outlineVariant…) au lieu d une couleur de clair.',
    );
  });

  test('les exceptions ne font que rétrécir', () {
    final found = _scan();
    final stale = <String>[];
    _allowed.forEach((file, entry) {
      for (final (text, count) in entry.lines) {
        if ((found[file]?[text] ?? 0) < count) {
          stale.add('$file : $text');
        }
      }
    });
    expect(
      stale,
      isEmpty,
      reason: 'Exception devenue inutile : la retirer de _allowed.',
    );
  });

  test('chaque exception a une raison', () {
    for (final entry in _allowed.entries) {
      expect(entry.value.reason.length, greaterThan(15), reason: entry.key);
    }
  });
}
