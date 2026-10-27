import 'package:flutter/painting.dart';

/// A seasonal theme bundled in the app: its glyph and its accent. Mirrors
/// `docs/storefront/themes.json` (a test keeps the two in step). A theme the
/// app does not know was added by the server after this build: its campaign is
/// ignored, because its icon is not in the bundle.
class StorefrontTheme {
  const StorefrontTheme(this.id, this.glyph, this.accent);

  final String id;
  final String glyph;
  final Color accent;

  /// The name of the alternate icon set of this theme in the bundle.
  String get appIconName => 'AppIcon-$id';
}

const List<StorefrontTheme> kStorefrontThemes = [
  StorefrontTheme('valentine', 'heart', Color(0xFFE5484D)),
  StorefrontTheme('tu_bav', 'two_hearts', Color(0xFFD6409F)),
  StorefrontTheme('rosh_hashana', 'pomegranate', Color(0xFFC2410C)),
  StorefrontTheme('hanukkah', 'flame', Color(0xFFE8A400)),
  StorefrontTheme('christmas', 'fir', Color(0xFF1F8A4C)),
  StorefrontTheme('new_year', 'sparkle', Color(0xFFE8A400)),
  StorefrontTheme('purim', 'mask', Color(0xFF8E4EC6)),
  StorefrontTheme('passover', 'matzah', Color(0xFF2747F5)),
  StorefrontTheme('mothers_day', 'flower', Color(0xFFD6409F)),
  StorefrontTheme('summer', 'sun', Color(0xFFE8A400)),
  StorefrontTheme('black_friday', 'bolt', Color(0xFF0B0B0F)),
];

StorefrontTheme? storefrontThemeById(String id) {
  for (final theme in kStorefrontThemes) {
    if (theme.id == id) return theme;
  }
  return null;
}
