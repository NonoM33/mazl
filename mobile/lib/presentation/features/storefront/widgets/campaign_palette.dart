import 'package:flutter/material.dart';

/// The colours of a campaign on a given surface, readable (WCAG AA) in light
/// and dark. The server's accent is a brand colour, not a contrast guarantee:
/// `black_friday` is ink, invisible on a dark surface.
class CampaignPalette {
  const CampaignPalette._({
    required this.fill,
    required this.onFill,
    required this.mark,
  });

  /// Background of the button and of the discount badge: at least 3:1 against
  /// the surface (the boundary of a control).
  final Color fill;

  /// Text on [fill]: at least 4.5:1.
  final Color onFill;

  /// The glyph drawn straight on the surface: at least 3:1.
  final Color mark;

  factory CampaignPalette.resolve(Color accent, Color surface) {
    final fill = _withContrast(accent, surface, 3);
    return CampaignPalette._(fill: fill, onFill: _readableOn(fill), mark: fill);
  }

  // The two ends of the lightness scale, for contrast arithmetic only: they
  // are not a theme colour and never drawn as a surface.
  static final Color _white = const HSLColor.fromAHSL(1, 0, 0, 1).toColor();
  static final Color _black = const HSLColor.fromAHSL(1, 0, 0, 0).toColor();

  /// Black or white, whichever reads better on [background]: at least 4.58:1
  /// for any background.
  static Color _readableOn(Color background) =>
      contrastRatio(_white, background) >= contrastRatio(_black, background)
      ? _white
      : _black;

  /// [color] moved toward black or white, away from [surface], until it stands
  /// [ratio]:1 from it. Unchanged when it already does.
  static Color _withContrast(Color color, Color surface, double ratio) {
    if (contrastRatio(color, surface) >= ratio) return color;
    final toward = surface.computeLuminance() > 0.5 ? _black : _white;
    for (var step = 1; step <= 20; step++) {
      final candidate = Color.lerp(color, toward, step / 20)!;
      if (contrastRatio(candidate, surface) >= ratio) return candidate;
    }
    return toward;
  }
}

/// WCAG 2 contrast ratio of two opaque colours, 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
