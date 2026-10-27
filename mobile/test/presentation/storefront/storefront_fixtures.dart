import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:mazl/core/storefront/storefront_models.dart';
import 'package:mazl/core/storefront/storefront_themes.dart';

/// A campaign for [themeId], as the server would send it, decoded by the real
/// decoder.
Storefront storefrontWithCampaign(
  String themeId, {
  List<Map<String, Object?>>? targets,
  List<Map<String, Object?>>? products,
  String title = 'La Saint-Valentin approche',
  String subtitle = 'Offrez-vous mazl+ avec 30 % de réduction.',
  String cta = 'Profiter de -30 %',
}) {
  final theme = storefrontThemeById(themeId)!;
  final hex = theme.accent.toARGB32().toRadixString(16).substring(2);
  return Storefront.tryParseBody(
    jsonEncode({
      'success': true,
      'data': {
        'serverTime': '2027-02-10T09:00:00Z',
        'products': products ?? <Object?>[],
        'campaign': {
          'id': 12,
          'themeId': themeId,
          'accent': '#$hex',
          'glyph': theme.glyph,
          'startsAt': '2020-01-01T00:00:00+01:00',
          'endsAt': '2099-02-15T00:00:00+01:00',
          'title': title,
          'subtitle': subtitle,
          'cta': cta,
          'targets':
              targets ??
              [
                {
                  'productId': 'com.mazl.app.plus.3m',
                  'discountPercent': 30,
                  'iosOfferCode': 'VALENTIN27',
                },
              ],
        },
        'appIcon': 'AppIcon-$themeId',
        'nextChangeAt': null,
      },
    }),
  )!;
}

/// An asset bundle that has the 24 x 24 line drawings of [glyphs] and nothing
/// else (the real ones are produced apart from this code).
class GlyphBundle extends CachingAssetBundle {
  GlyphBundle(this.glyphs);

  final Set<String> glyphs;
  final List<String> asked = [];

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="currentColor" stroke-width="1.75">'
      '<path d="M12 21C5 15 3 11 3 8a4.5 4.5 0 0 1 9-1 4.5 4.5 0 0 1 9 1c0 3-2 7-9 13z"/>'
      '</svg>';

  @override
  Future<ByteData> load(String key) async {
    asked.add(key);
    final name = RegExp(
      r'^assets/storefront/glyphs/(\w+)\.svg$',
    ).firstMatch(key)?.group(1);
    if (name == null || !glyphs.contains(name)) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(_svg)));
  }
}
