import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/couple_backend_shapes.dart';
import 'geist_font.dart';

/// What every test of the couple feed screens needs: the real app font (for
/// realistic text widths) and an empty preferences store.
void setUpCoupleFeedTests() {
  setUpAll(loadGeist);
  setUp(() => SharedPreferences.setMockInitialValues({}));
}

const kEn = Locale('en');
const kHe = Locale('he');
const kEs = Locale('es');
const kRu = Locale('ru');
const kLocales = [kEn, kHe, kEs, kRu];

const kFeedRoute = 'GET /api/couple/activities?limit=50&offset=0';
const kSavedRoute = 'GET /api/couple/saved';
const kEventsRoute = 'GET /api/couple/events?limit=50&offset=0';
const kRegisteredRoute = 'GET /api/couple/events/registered';

/// The activity of the backend shapes, made a partner with a promo code so
/// that every pill and the code card are on screen.
Map<String, dynamic> partnerActivity({int id = 4}) => {
  ...activityRow(id: id, title: 'Atelier poterie'),
  'is_partner': true,
  'discount_percent': 15,
  'discount_code': 'MAZL15',
  'phone': '+33100000000',
  'website': 'https://example.com',
  'booking_url': 'https://example.com/book',
};

Finder backArrow(IconData icon) =>
    find.byWidgetPredicate((w) => w is RoundIconButton && w.icon == icon);

/// Every text seen while a long list is scrolled to its end, a screenful at a
/// time: a lazy list only builds what is near the screen.
Future<Set<String>> textsWhileScrolling(
  WidgetTester tester,
  Finder list,
) async {
  final seen = <String>{};
  void collect() => seen.addAll(
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
  );
  collect();
  for (var i = 0; i < 12; i++) {
    await tester.drag(list, const Offset(0, -300));
    await tester.pump();
    collect();
  }
  return seen;
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Scrolls a long list to its end, a screenful at a time, so that every
/// lazily built row is laid out once (an overflow fails the test).
Future<void> scrollThrough(WidgetTester tester, Finder list) async {
  for (var i = 0; i < 12; i++) {
    await tester.drag(list, const Offset(0, -300));
    await tester.pump();
  }
}
