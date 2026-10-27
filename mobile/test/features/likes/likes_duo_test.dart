import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:mazl/presentation/features/likes/widgets/blurred_like_tile.dart';
import 'package:mazl/presentation/features/likes/widgets/like_widgets.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// The received-likes grid on the foldable iPhone (iPhone Duo). Held like a
// book, the columns of tiles fall on either side of the fold and the title
// and sentences stay on the reading-start page; anywhere else it is the usual
// two columns.

class _LikesApi implements ApiService {
  _LikesApi({required this.premium});

  final bool premium;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      ApiResponse.success(
        LikesData(
          count: 6,
          isPremium: premium,
          likes: [
            for (var i = 1; i <= 6; i++)
              LikeProfile(
                userId: i,
                displayName: 'Jeanne$i',
                age: premium ? 20 + i : null,
                likedAt: DateTime(2026, 10, 1),
                // One in two has a blurred photo, the others the gradient.
                blurredPhotoUrl: !premium && i.isOdd
                    ? 'https://example.com/blur$i.jpg'
                    : null,
                isSuperLike: i == 2,
              ),
          ],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_LikesApi: ${invocation.memberName}');
}

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  bool premium = true,
  Locale locale = const Locale('fr'),
}) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(DuoPoseController(pose)),
      home: LikesScreen(apiService: _LikesApi(premium: premium)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

List<Rect> _tiles(WidgetTester tester, [Type type = LikeCard]) => [
  for (final tile in find.byType(type).evaluate())
    tester.getRect(find.byWidget(tile.widget)),
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('book: no tile touches the fold, both pages hold tiles', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final tiles = _tiles(tester);
    expect(tiles, isNotEmpty);
    for (final tile in tiles) {
      expect(tile.overlaps(fold), isFalse, reason: '$tile crosses $fold');
    }
    expect(tiles.any((t) => t.right <= fold.left), isTrue);
    expect(tiles.any((t) => t.left >= fold.right), isTrue);
  });

  testWidgets('book: the title is on the left page, away from the fold', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final title = tester.getRect(find.text('Likes'));
    expect(title.right, lessThanOrEqualTo(DuoPose.halfOpenBook.fold!.left));
  });

  testWidgets('book in Hebrew: the title is on the right page', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook, locale: const Locale('he'));
    final title = tester.getRect(
      find.text(lookupAppLocalizations(const Locale('he')).likesTitle),
    );
    expect(title.left, greaterThanOrEqualTo(DuoPose.halfOpenBook.fold!.right));
  });

  testWidgets('book, free member: the mazl+ button sits on the left page', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook, premium: false);
    await tester.dragUntilVisible(
      find.byType(MazlPlusPill),
      find.byType(ListView),
      const Offset(0, -150),
    );
    final pill = tester.getRect(find.byType(MazlPlusPill).first);
    expect(pill.right, lessThanOrEqualTo(DuoPose.halfOpenBook.fold!.left));
  });

  testWidgets('open landscape: still two columns', (tester) async {
    await _pump(tester, DuoPose.openLandscape);
    final columns = _tiles(tester).map((t) => t.left.round()).toSet();
    expect(columns.length, 2);
  });

  testWidgets(
    'book, free member: blurred tiles on both pages, none on the fold',
    (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, premium: false);
      final fold = DuoPose.halfOpenBook.fold!;
      final tiles = _tiles(tester, BlurredLikeTile);
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.overlaps(fold), isFalse, reason: '$tile crosses $fold');
      }
      expect(tiles.any((t) => t.right <= fold.left), isTrue);
      expect(tiles.any((t) => t.left >= fold.right), isTrue);
    },
  );

  testWidgets(
    'book, free member: the real count heads the page, not on the fold',
    (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, premium: false);
      final headline = tester.getRect(find.text('6 personnes vous ont aimé'));
      expect(
        headline.right,
        lessThanOrEqualTo(DuoPose.halfOpenBook.fold!.left),
      );
    },
  );

  testWidgets('free member: the first name never reaches the screen', (
    tester,
  ) async {
    await _pump(tester, DuoPose.openLandscape, premium: false);
    expect(find.textContaining('Jeanne'), findsNothing);
    expect(find.text('Quelqu\'un'), findsWidgets);
  });
}
