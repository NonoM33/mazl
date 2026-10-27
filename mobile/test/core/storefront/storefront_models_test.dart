import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/storefront/storefront_models.dart';
import 'package:mazl/core/storefront/storefront_themes.dart';

// The decoding of `GET /api/storefront`, written from the contract
// (docs/storefront/CONTRACT.md §4), not from the decoder.

String _body(Map<String, Object?> data) =>
    jsonEncode({'success': true, 'data': data});

/// The answer of the contract's example, in February.
Map<String, Object?> _valentine() => {
  'serverTime': '2027-02-10T09:00:00Z',
  'products': <Object?>[
    {
      'productId': 'com.mazl.app.plus.3m',
      'visible': true,
      'sortOrder': 0,
      'featured': true,
      'highlight': 'Le plus choisi',
    },
    {
      'productId': 'com.mazl.app.plus.1m',
      'visible': false,
      'sortOrder': 1,
      'featured': false,
      'highlight': null,
    },
  ],
  'campaign': {
    'id': 12,
    'themeId': 'valentine',
    'accent': '#E5484D',
    'glyph': 'heart',
    'startsAt': '2027-02-07T00:00:00+01:00',
    'endsAt': '2027-02-15T00:00:00+01:00',
    'title': 'La Saint-Valentin approche',
    'subtitle': 'Offrez-vous mazl+ avec 30 % de réduction.',
    'cta': 'Profiter de -30 %',
    'targets': <Object?>[
      {
        'productId': 'com.mazl.app.plus.3m',
        'discountPercent': 30,
        'iosOfferCode': 'VALENTIN27',
        'webPromotion': true,
      },
      {
        'productId': 'com.mazl.app.plus.12m',
        'discountPercent': 20,
        'webPromotion': true,
      },
    ],
  },
  'appIcon': 'AppIcon-valentine',
  'nextChangeAt': '2027-02-15T00:00:00+01:00',
};

void main() {
  group('a campaign in progress', () {
    final storefront = Storefront.tryParseBody(_body(_valentine()))!;

    test('products keep the order, visibility, hook and featuring', () {
      expect(storefront.products, hasLength(2));
      final three = storefront.productFor('com.mazl.app.plus.3m')!;
      expect(three.featured, isTrue);
      expect(three.highlight, 'Le plus choisi');
      expect(three.sortOrder, 0);
      final one = storefront.productFor('com.mazl.app.plus.1m')!;
      expect(one.visible, isFalse);
      expect(one.highlight, isNull);
    });

    test('the campaign carries its texts, accent, glyph and targets', () {
      final campaign = storefront.campaign!;
      expect(campaign.id, 12);
      expect(campaign.theme.id, 'valentine');
      expect(campaign.accent, const Color(0xFFE5484D));
      expect(campaign.glyph, 'heart');
      expect(campaign.title, 'La Saint-Valentin approche');
      expect(campaign.cta, 'Profiter de -30 %');
      expect(campaign.targets, hasLength(2));
      expect(campaign.targetFor('com.mazl.app.plus.3m')!.discountPercent, 30);
      expect(campaign.targetFor('com.mazl.app.plus.6m'), isNull);
    });

    test(
      'the offer code opens the Apple redeem page with the code filled in',
      () {
        final target = storefront.campaign!.targetFor('com.mazl.app.plus.3m')!;
        expect(
          target.redeemUri.toString(),
          'https://apps.apple.com/redeem?ctx=offercodes&id=6758543555'
          '&code=VALENTIN27',
        );
        expect(
          storefront.campaign!.targetFor('com.mazl.app.plus.12m')!.redeemUri,
          isNull,
          reason: 'no iosOfferCode: Apple never got the code',
        );
      },
    );

    test('the offer of a plan without a code falls back on the first code', () {
      final campaign = storefront.campaign!;
      expect(
        campaign.offerFor('com.mazl.app.plus.3m')!.iosOfferCode,
        'VALENTIN27',
      );
      expect(
        campaign.offerFor('com.mazl.app.plus.12m')!.iosOfferCode,
        'VALENTIN27',
      );
      expect(campaign.offerFor(null)!.iosOfferCode, 'VALENTIN27');
    });

    test('the icon and the next change are read', () {
      expect(storefront.appIcon, 'AppIcon-valentine');
      expect(storefront.nextChangeAt, DateTime.utc(2027, 2, 14, 23));
      expect(storefront.serverTime, DateTime.utc(2027, 2, 10, 9));
    });

    test('the last day is the day before the midnight that ends it', () {
      // endsAt is 15 February 00:00 in Paris: the offer runs until the 14th,
      // whatever the zone of the phone.
      expect(storefront.campaign!.lastDay, DateTime(2027, 2, 14));
    });
  });

  group('no campaign', () {
    test('the contract answer outside a campaign', () {
      final storefront = Storefront.tryParseBody(
        _body({
          'serverTime': '2027-03-01T09:00:00Z',
          'products': <Object?>[
            {
              'productId': 'com.mazl.app.plus.3m',
              'visible': true,
              'sortOrder': 0,
              'featured': false,
              'highlight': null,
            },
          ],
          'campaign': null,
          'appIcon': null,
          'nextChangeAt': null,
        }),
      )!;
      expect(storefront.campaign, isNull);
      expect(storefront.appIcon, isNull);
      expect(storefront.nextChangeAt, isNull);
      expect(storefront.products, hasLength(1));
    });
  });

  group('an answer that is not what the contract says', () {
    test('a theme this build does not know is ignored, with its icon', () {
      final data = _valentine();
      (data['campaign']! as Map<String, Object?>)['themeId'] = 'diwali';
      data['appIcon'] = 'AppIcon-diwali';
      final storefront = Storefront.tryParseBody(_body(data))!;
      expect(storefront.campaign, isNull);
      expect(storefront.appIcon, isNull);
      expect(storefront.products, hasLength(2), reason: 'the rest still shows');
    });

    test('an icon that is not a bundled one is never asked for', () {
      final data = _valentine()..['appIcon'] = 'AppIcon-secret';
      expect(Storefront.tryParseBody(_body(data))!.appIcon, isNull);
    });

    test('a campaign without title or end date is left out', () {
      for (final key in ['title', 'endsAt', 'id']) {
        final data = _valentine();
        (data['campaign']! as Map<String, Object?>).remove(key);
        expect(
          Storefront.tryParseBody(_body(data))!.campaign,
          isNull,
          reason: 'without $key',
        );
      }
    });

    test('missing optional fields fall back on the theme', () {
      final data = _valentine();
      (data['campaign']! as Map<String, Object?>)
        ..remove('accent')
        ..remove('glyph')
        ..remove('subtitle')
        ..remove('cta')
        ..remove('startsAt')
        ..remove('targets');
      final campaign = Storefront.tryParseBody(_body(data))!.campaign!;
      expect(campaign.accent, kStorefrontThemes.first.accent);
      expect(campaign.glyph, 'heart');
      expect(campaign.subtitle, isEmpty);
      expect(campaign.cta, isEmpty);
      expect(campaign.startsAt, isNull);
      expect(campaign.targets, isEmpty);
    });

    test(
      'a glyph name that is not a plain name never reaches the asset path',
      () {
        final data = _valentine();
        (data['campaign']! as Map<String, Object?>)['glyph'] = '../../secret';
        expect(Storefront.tryParseBody(_body(data))!.campaign!.glyph, 'heart');
      },
    );

    test('a malformed accent keeps the theme accent', () {
      final data = _valentine();
      (data['campaign']! as Map<String, Object?>)['accent'] = 'red';
      expect(
        Storefront.tryParseBody(_body(data))!.campaign!.accent,
        const Color(0xFFE5484D),
      );
    });

    test('broken products and targets are dropped one by one', () {
      final data = _valentine();
      (data['products']! as List<Object?>).addAll([
        {'visible': true},
        'oops',
        {'productId': 42},
      ]);
      ((data['campaign']! as Map<String, Object?>)['targets']! as List<Object?>)
          .addAll([
            {'productId': 'com.mazl.app.plus.6m', 'discountPercent': 0},
            {'productId': 'com.mazl.app.plus.6m', 'discountPercent': 100},
            {'productId': 'com.mazl.app.plus.6m'},
            null,
          ]);
      final storefront = Storefront.tryParseBody(_body(data))!;
      expect(storefront.products, hasLength(2));
      expect(storefront.campaign!.targets, hasLength(2));
    });

    test('not the envelope: null, never an exception', () {
      for (final body in [
        '',
        'not json',
        '[]',
        '{}',
        '{"success":false,"error":"boom"}',
        '{"success":true}',
        '{"success":true,"data":[]}',
      ]) {
        expect(Storefront.tryParseBody(body), isNull, reason: body);
      }
    });

    test('an empty data object is an empty storefront', () {
      final storefront = Storefront.tryParseBody(_body({}))!;
      expect(storefront.products, isEmpty);
      expect(storefront.campaign, isNull);
    });
  });

  group('time passes on an answer kept on the phone', () {
    final storefront = Storefront.tryParseBody(_body(_valentine()))!;

    test('before the end the campaign and its icon stay', () {
      final seen = storefront.at(DateTime.utc(2027, 2, 12));
      expect(seen.campaign, isNotNull);
      expect(seen.appIcon, 'AppIcon-valentine');
    });

    test('after the end both are gone, the catalogue stays', () {
      final seen = storefront.at(DateTime.utc(2027, 2, 15));
      expect(seen.campaign, isNull);
      expect(seen.appIcon, isNull);
      expect(seen.products, hasLength(2));
    });

    test('before the start the campaign is not shown yet', () {
      expect(storefront.at(DateTime.utc(2027, 2, 6)).campaign, isNull);
    });
  });

  group('the bundled themes', () {
    test('are the themes of docs/storefront/themes.json', () {
      final json =
          jsonDecode(File('../docs/storefront/themes.json').readAsStringSync())
              as Map<String, Object?>;
      final themes = (json['themes']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(
        [for (final t in kStorefrontThemes) t.id],
        [for (final t in themes) t['id']],
      );
      for (final theme in themes) {
        final known = storefrontThemeById(theme['id']! as String)!;
        expect(known.glyph, theme['glyph'], reason: known.id);
        final hex = (theme['accent']! as String).substring(1);
        expect(
          known.accent,
          Color(0xFF000000 | int.parse(hex, radix: 16)),
          reason: known.id,
        );
        expect(known.appIconName, 'AppIcon-${known.id}');
      }
    });
  });
}
