import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';

import '../../../helpers/l10n_helpers.dart';

/// The chips of the Discover card (denomination, kashrut, Shabbat,
/// intention) come from the member's stored answers, which the server keeps
/// in French: the card writes them in the language of the interface.
final _lea = Profile(
  id: 7,
  userId: 7,
  displayName: 'Léa',
  age: 28,
  location: 'Paris',
  distance: 4.2,
  denomination: 'orthodoxe_moderne',
  kashrut: 'kasher_a_la_maison',
  shabbatObservance: 'observant',
  relationshipIntention: 'mariage',
);

Future<void> _pump(WidgetTester tester, Locale locale) => pumpLocalized(
  tester,
  Scaffold(
    body: Center(
      child: SizedBox(
        width: 358,
        height: 640,
        child: DiscoverCard(profile: _lea, onPass: () {}, onLike: () {}),
      ),
    ),
  ),
  locale: locale,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('les puces sont en anglais sur un téléphone en anglais', (
    tester,
  ) async {
    await _pump(tester, const Locale('en'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(find.text(en.profileDenominationModernOrthodox), findsOneWidget);
    expect(find.text(en.profileKashrutHome), findsOneWidget);
    expect(find.text('Orthodoxe moderne'), findsNothing);
    expect(find.text('Cacher à la maison'), findsNothing);
  });

  testWidgets('les puces restent en français sur un téléphone en français', (
    tester,
  ) async {
    await _pump(tester, kTestLocale);

    expect(find.text('Orthodoxe moderne'), findsOneWidget);
    expect(find.text('Cacher à la maison'), findsOneWidget);
  });

  testWidgets('en hébreu, les puces sont en hébreu', (tester) async {
    await _pump(tester, const Locale('he'));
    final he = lookupAppLocalizations(const Locale('he'));

    expect(find.text(he.profileDenominationModernOrthodox), findsOneWidget);
    expect(
      textDirectionAt(tester, find.text(he.profileKashrutHome)),
      TextDirection.rtl,
    );
  });
}
