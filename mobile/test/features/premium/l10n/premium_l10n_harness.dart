import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/subscription_models.dart';
import 'package:mazl/core/theme/app_theme.dart';

import '../../../helpers/l10n_helpers.dart';

export '../../../helpers/l10n_helpers.dart';
export '../../matching/l10n/l10n_harness.dart';

/// Renders [home] like `pumpLocalized`, but on iOS: the offer and the
/// subscription screen write « App Store » there and « Google Play » on
/// Android, and the test engine defaults to Android.
Future<void> pumpPlus(
  WidgetTester tester,
  Widget home, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
  Size size = kSmallPhone,
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A test that renders twice gets a fresh screen, not the old state.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(platform: platform),
      darkTheme: AppTheme.darkTheme.copyWith(platform: platform),
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// A store plan in [currency], with the duration read from [months].
SubscriptionPlan storePlan({
  required int months,
  required double price,
  String currency = 'USD',
}) => SubscriptionPlan(
  productId: 'com.mazl.app.plus.${months}m',
  months: months,
  price: price,
  currencyCode: currency,
  priceLabel: price.toStringAsFixed(2),
  title: 'mazl+',
  product: ProductDetails(
    id: 'com.mazl.app.plus.${months}m',
    title: 'mazl+',
    description: 'mazl+',
    price: price.toStringAsFixed(2),
    rawPrice: price,
    currencyCode: currency,
  ),
);

/// The visual boxes of characters [start, end) of the paragraph at [finder].
List<Rect> glyphBoxes(WidgetTester tester, Finder finder, int start, int end) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
      .map((box) => box.toRect())
      .toList();
}

/// Spaces that only exist in the number formats (no-break, narrow no-break,
/// right-to-left and left-to-right marks), folded away to compare prices.
String plain(String s) => s
    .replaceAll(' ', ' ')
    .replaceAll(' ', ' ')
    .replaceAll('‏', '')
    .replaceAll('‎', '');

/// The [Text] whose content, once the number-format spaces and direction
/// marks are folded away by [plain], is [expected].
Finder findPlain(String expected) => find.byWidgetPredicate(
  (widget) => widget is Text && plain(widget.data ?? '') == expected,
  description: 'Text « $expected »',
);
