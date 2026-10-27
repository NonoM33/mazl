import 'package:mazl/core/images/mazl_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/likes.dart';
import 'package:mazl/presentation/features/likes/widgets/blurred_like_tile.dart';

import '../../helpers/l10n_helpers.dart';

// The tile of a like for a member without mazl+: the first name never shows,
// whatever the server sent (contract of docs/premium/MONETISATION.md §1).

final _now = DateTime.utc(2026, 10, 27, 12);

LikeProfile _like({
  bool verified = true,
  bool superLike = false,
  String? blurred = 'https://example.com/blur.jpg',
  Duration ago = const Duration(hours: 2, minutes: 10),
}) => LikeProfile(
  userId: 0,
  displayName: 'Jeanne Exemple',
  isVerified: verified,
  likedAt: _now.subtract(ago),
  blurredPhotoUrl: blurred,
  isSuperLike: superLike,
);

Future<void> _pump(
  WidgetTester tester,
  LikeProfile like, {
  VoidCallback? onTap,
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
  double width = 160,
}) => pumpLocalized(
  tester,
  Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: 200,
        child: BlurredLikeTile(
          like: like,
          onTap: onTap ?? () {},
          now: () => _now,
        ),
      ),
    ),
  ),
  locale: locale,
  brightness: brightness,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows « Quelqu\'un », never the first name sent by the server', (
    tester,
  ) async {
    await _pump(tester, _like());

    expect(find.text('Quelqu\'un'), findsOneWidget);
    expect(find.textContaining('Jeanne'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Jeanne')), findsNothing);
  });

  testWidgets('shows the verified badge, the age of the like, the lock', (
    tester,
  ) async {
    await _pump(tester, _like());

    expect(find.byIcon(LucideIcons.badgeCheck), findsOneWidget);
    expect(find.text('il y a 2 h'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.text('Super Like'), findsNothing);
  });

  testWidgets('no badge when the member is not verified', (tester) async {
    await _pump(tester, _like(verified: false));

    expect(find.byIcon(LucideIcons.badgeCheck), findsNothing);
  });

  testWidgets('marks a Super Like', (tester) async {
    await _pump(tester, _like(superLike: true));

    expect(find.text('Super Like'), findsOneWidget);
  });

  testWidgets('draws the blurred photo enlarged with a good filter', (
    tester,
  ) async {
    await _pump(tester, _like());

    final photo = tester.widget<MazlNetworkImage>(
      find.byType(MazlNetworkImage),
    );
    expect(photo.url, 'https://example.com/blur.jpg');
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(MazlNetworkImage),
        matching: find.byType(Image),
      ),
    );
    expect(image.filterQuality, FilterQuality.high);
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('without a usable photo: a gradient, no image request', (
    tester,
  ) async {
    await _pump(tester, _like(blurred: null));

    expect(find.byType(MazlNetworkImage), findsNothing);
    expect(find.byKey(BlurredLikeTile.fallbackKey), findsOneWidget);
    expect(find.text('Quelqu\'un'), findsOneWidget);
  });

  testWidgets('a tap anywhere on the tile, near its edge, calls onTap', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, _like(), onTap: () => taps++);

    final box = tester.getRect(find.byType(BlurredLikeTile));
    expect(box.width, greaterThanOrEqualTo(44));
    expect(box.height, greaterThanOrEqualTo(44));
    await tester.tapAt(box.topLeft + const Offset(2, 2));
    await tester.tapAt(box.bottomRight - const Offset(2, 2));

    expect(taps, 2);
  });

  testWidgets('is announced as a button without the name', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _like());

    expect(
      tester.getSemantics(find.byType(BlurredLikeTile)),
      matchesSemantics(
        label: 'Quelqu\'un vous a aimé, il y a 2 h',
        hint: 'Touchez pour découvrir mazl+',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      testWidgets('${locale.languageCode} ${brightness.name}: fits 150 pt', (
        tester,
      ) async {
        await _pump(
          tester,
          _like(superLike: true),
          locale: locale,
          brightness: brightness,
          width: 150,
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Jeanne'), findsNothing);
      });
    }
  }
}
