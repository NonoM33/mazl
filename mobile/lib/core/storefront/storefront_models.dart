import 'dart:convert';

import 'package:flutter/painting.dart';

import 'storefront_themes.dart';

/// The Apple page that redeems an offer code, with the code filled in.
Uri appleRedeemUri(String code) => Uri.parse(
  'https://apps.apple.com/redeem?ctx=offercodes&id=6758543555'
  '&code=${Uri.encodeQueryComponent(code)}',
);

/// How the server wants one subscription shown (`GET /api/storefront`,
/// docs/storefront/CONTRACT.md §4). The price is never here: it always comes
/// from StoreKit.
class StorefrontProduct {
  const StorefrontProduct({
    required this.productId,
    required this.visible,
    required this.sortOrder,
    required this.featured,
    this.highlight,
  });

  final String productId;
  final bool visible;
  final int sortOrder;
  final bool featured;

  /// The short hook under the plan (« Le plus choisi »), already in the
  /// language of the request.
  final String? highlight;

  static StorefrontProduct? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['productId'];
    if (id is! String || id.isEmpty) return null;
    final highlight = json['highlight'];
    return StorefrontProduct(
      productId: id,
      visible: json['visible'] is bool ? json['visible']! as bool : true,
      sortOrder: json['sortOrder'] is num
          ? (json['sortOrder']! as num).toInt()
          : 0,
      featured: json['featured'] == true,
      highlight: highlight is String && highlight.trim().isNotEmpty
          ? highlight.trim()
          : null,
    );
  }
}

/// A product the campaign discounts.
class CampaignTarget {
  const CampaignTarget({
    required this.productId,
    required this.discountPercent,
    this.iosOfferCode,
  });

  final String productId;
  final int discountPercent;

  /// The Apple offer code, only when the server created it at Apple.
  final String? iosOfferCode;

  Uri? get redeemUri {
    final code = iosOfferCode;
    return code == null ? null : appleRedeemUri(code);
  }

  static CampaignTarget? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['productId'];
    final percent = json['discountPercent'];
    if (id is! String || id.isEmpty || percent is! num) return null;
    final value = percent.toInt();
    if (value <= 0 || value >= 100) return null;
    final code = json['iosOfferCode'];
    return CampaignTarget(
      productId: id,
      discountPercent: value,
      iosOfferCode: code is String && code.trim().isNotEmpty
          ? code.trim()
          : null,
    );
  }
}

/// The campaign running now: one of the themes bundled in the app.
class StorefrontCampaign {
  const StorefrontCampaign({
    required this.id,
    required this.theme,
    required this.accent,
    required this.glyph,
    required this.startsAt,
    required this.endsAt,
    required this.lastDay,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.targets,
  });

  final int id;
  final StorefrontTheme theme;
  final Color accent;

  /// Name of `assets/storefront/glyphs/<glyph>.svg`.
  final String glyph;
  final DateTime? startsAt;
  final DateTime endsAt;

  /// The last day of the campaign as the server's calendar counts it (the
  /// midnight that ends the campaign belongs to the next day), as a date at
  /// 00:00. This is the day « jusqu'au » shows, whatever the phone's zone.
  final DateTime lastDay;
  final String title;
  final String subtitle;

  /// The button text; empty when the server sent none.
  final String cta;
  final List<CampaignTarget> targets;

  CampaignTarget? targetFor(String productId) {
    for (final target in targets) {
      if (target.productId == productId) return target;
    }
    return null;
  }

  /// The Apple offer to open for [productId] when the member taps the button:
  /// the one of that plan, else the first offer the campaign has.
  CampaignTarget? offerFor(String? productId) {
    final own = productId == null ? null : targetFor(productId);
    if (own?.iosOfferCode != null) return own;
    for (final target in targets) {
      if (target.iosOfferCode != null) return target;
    }
    return null;
  }

  bool isLiveAt(DateTime now) =>
      !now.isBefore(startsAt ?? DateTime.fromMillisecondsSinceEpoch(0)) &&
      now.isBefore(endsAt);

  static final RegExp _glyphName = RegExp(r'^[a-z][a-z0-9_]{0,31}$');
  static final RegExp _hexColor = RegExp(r'^#([0-9a-fA-F]{6})$');
  static final RegExp _wallClock = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?(?:[+-]\d{2}:?\d{2})$',
  );

  /// `null` when the campaign cannot be shown: unknown theme (its icon is not
  /// in this build), no title, no valid end date.
  static StorefrontCampaign? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final themeId = json['themeId'];
    final title = json['title'];
    final endsRaw = json['endsAt'];
    if (id is! num || themeId is! String) return null;
    final theme = storefrontThemeById(themeId);
    if (theme == null) return null;
    if (title is! String || title.trim().isEmpty) return null;
    final endsAt = endsRaw is String ? DateTime.tryParse(endsRaw) : null;
    if (endsAt == null) return null;
    final startsRaw = json['startsAt'];
    final accentRaw = json['accent'];
    final accentMatch = accentRaw is String
        ? _hexColor.firstMatch(accentRaw)
        : null;
    final glyphRaw = json['glyph'];
    final targets = json['targets'];
    final subtitle = json['subtitle'];
    final cta = json['cta'];
    return StorefrontCampaign(
      id: id.toInt(),
      theme: theme,
      accent: accentMatch == null
          ? theme.accent
          : Color(0xFF000000 | int.parse(accentMatch.group(1)!, radix: 16)),
      glyph: glyphRaw is String && _glyphName.hasMatch(glyphRaw)
          ? glyphRaw
          : theme.glyph,
      startsAt: startsRaw is String ? DateTime.tryParse(startsRaw) : null,
      endsAt: endsAt,
      lastDay: _lastDay(endsRaw! as String, endsAt),
      title: title.trim(),
      subtitle: subtitle is String ? subtitle.trim() : '',
      cta: cta is String ? cta.trim() : '',
      targets: [
        if (targets is List)
          for (final raw in targets)
            if (CampaignTarget.tryParse(raw) case final target?) target,
      ],
    );
  }

  static DateTime _lastDay(String raw, DateTime parsed) {
    final wall = _wallClock.firstMatch(raw);
    final DateTime end = wall == null
        ? parsed.toLocal()
        : DateTime.utc(
            int.parse(wall.group(1)!),
            int.parse(wall.group(2)!),
            int.parse(wall.group(3)!),
            int.parse(wall.group(4)!),
            int.parse(wall.group(5)!),
            int.parse(wall.group(6) ?? '0'),
          );
    final last = end.subtract(const Duration(seconds: 1));
    return DateTime(last.year, last.month, last.day);
  }
}

/// The whole answer of `GET /api/storefront`.
class Storefront {
  const Storefront({
    required this.products,
    required this.campaign,
    required this.appIcon,
    required this.nextChangeAt,
    this.serverTime,
  });

  /// Nothing from the server: the current behaviour of the app.
  static const Storefront empty = Storefront(
    products: [],
    campaign: null,
    appIcon: null,
    nextChangeAt: null,
  );

  final List<StorefrontProduct> products;
  final StorefrontCampaign? campaign;

  /// The alternate icon to show (`AppIcon-<themeId>`), null for the normal one.
  final String? appIcon;
  final DateTime? nextChangeAt;
  final DateTime? serverTime;

  StorefrontProduct? productFor(String productId) {
    for (final product in products) {
      if (product.productId == productId) return product;
    }
    return null;
  }

  /// What is still true at [now]: an answer kept on the phone does not keep a
  /// campaign alive past its end, nor show one before it starts.
  Storefront at(DateTime now) {
    final running = campaign;
    if (running == null || running.isLiveAt(now)) return this;
    return Storefront(
      products: products,
      campaign: null,
      appIcon: null,
      nextChangeAt: nextChangeAt,
      serverTime: serverTime,
    );
  }

  /// Decodes a response body. `null` when it is not the documented envelope.
  /// A part that does not decode is left out, never a crash: a product
  /// without an id, a campaign of an unknown theme.
  static Storefront? tryParseBody(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    return tryParse(json);
  }

  static Storefront? tryParse(Object? json) {
    if (json is! Map<String, Object?> || json['success'] != true) return null;
    final data = json['data'];
    if (data is! Map<String, Object?>) return null;
    final products = data['products'];
    final campaign = StorefrontCampaign.tryParse(data['campaign']);
    final icon = data['appIcon'];
    final next = data['nextChangeAt'];
    final serverTime = data['serverTime'];
    return Storefront(
      products: [
        if (products is List)
          for (final raw in products)
            if (StorefrontProduct.tryParse(raw) case final product?) product,
      ],
      campaign: campaign,
      // An icon of a theme this build does not carry cannot be set.
      appIcon: campaign != null && icon is String && _isBundledIcon(icon)
          ? icon
          : null,
      nextChangeAt: next is String ? DateTime.tryParse(next) : null,
      serverTime: serverTime is String ? DateTime.tryParse(serverTime) : null,
    );
  }

  static bool _isBundledIcon(String name) {
    for (final theme in kStorefrontThemes) {
      if (theme.appIconName == name) return true;
    }
    return false;
  }
}
