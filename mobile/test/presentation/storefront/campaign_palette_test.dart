import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/storefront/storefront_themes.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/storefront/widgets/campaign_palette.dart';

// WCAG 2 values, computed from the definition (relative luminance of sRGB),
// not by the code under test: black on white is 21:1.

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : _pow((c + 0.055) / 1.055, 2.4);
double _pow(double x, double y) => x <= 0 ? 0 : _exp(y * _ln(x));
double _ln(double x) {
  // Newton on exp, enough for a test tolerance.
  var guess = 0.0;
  for (var i = 0; i < 60; i++) {
    final e = _exp(guess);
    guess -= (e - x) / e;
  }
  return guess;
}

double _exp(double x) {
  var sum = 1.0;
  var term = 1.0;
  for (var i = 1; i < 60; i++) {
    term *= x / i;
    sum += term;
  }
  return sum;
}

double _lum(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color a, Color b) {
  final l1 = _lum(a);
  final l2 = _lum(b);
  return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
}

void main() {
  test('the reference ratio is right (black on white is 21:1)', () {
    expect(_ratio(Colors.black, Colors.white), closeTo(21, 0.01));
  });

  for (final brightness in Brightness.values) {
    final scheme = brightness == Brightness.light
        ? AppTheme.lightTheme.colorScheme
        : AppTheme.darkTheme.colorScheme;
    for (final theme in kStorefrontThemes) {
      test('${theme.id} is readable in ${brightness.name}', () {
        for (final surface in [scheme.surface, scheme.surfaceContainer]) {
          final palette = CampaignPalette.resolve(theme.accent, surface);
          expect(
            _ratio(palette.onFill, palette.fill),
            greaterThanOrEqualTo(4.5),
            reason: 'text on the button',
          );
          expect(
            _ratio(palette.fill, surface),
            greaterThanOrEqualTo(3),
            reason: 'the button and the glyph stand out from the surface',
          );
          expect(_ratio(palette.mark, surface), greaterThanOrEqualTo(3));
        }
      });
    }
  }

  test('black Friday ink is turned light on a dark surface', () {
    final dark = AppTheme.darkTheme.colorScheme.surface;
    final ink = kStorefrontThemes.firstWhere((t) => t.id == 'black_friday');
    final palette = CampaignPalette.resolve(ink.accent, dark);
    expect(palette.fill.computeLuminance(), greaterThan(0.1));
  });

  test('an accent that already stands out is left as the server gave it', () {
    const accent = Color(0xFF0B0B0F);
    expect(CampaignPalette.resolve(accent, Colors.white).fill, accent);
  });
}
