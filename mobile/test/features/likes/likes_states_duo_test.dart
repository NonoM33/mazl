import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/likes/screens/likes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// Every state of the received-likes screen in the seven poses of the foldable
// iPhone (iPhone Duo), light and dark: a member without mazl+ with N likes
// (the blurred photo present, absent, or both), a subscriber with a Super Like
// and its word. Nothing crosses the fold, nothing tappable leaves the safe
// area or goes under the system, the way out (back) is in the vertical bar.

class _Api implements ApiService {
  _Api(this.data);

  final LikesData data;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      ApiResponse.success(data);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Api: ${invocation.memberName}');
}

LikesData _free(int count, {required bool photo, bool mixed = false}) =>
    LikesData(
      count: count,
      isPremium: false,
      likes: [
        for (var i = 0; i < count && i < 8; i++)
          LikeProfile(
            userId: 0,
            displayName: 'Jeanne $i',
            isVerified: i.isEven,
            likedAt: DateTime.now().subtract(Duration(hours: 2 + i * 9)),
            blurredPhotoUrl: (photo && (!mixed || i.isEven))
                ? 'https://example.com/b$i'
                : null,
            isSuperLike: i == 1,
          ),
      ],
    );

LikesData _subscriber() => LikesData(
  count: 3,
  isPremium: true,
  likes: [
    LikeProfile(
      userId: 1,
      displayName: 'Léa Exemple',
      age: 27,
      isVerified: true,
      likedAt: DateTime.now().subtract(const Duration(hours: 3)),
      isSuperLike: true,
      note: 'Ton profil m\'a fait sourire, et ta photo à Jérusalem aussi.',
    ),
    for (var i = 2; i <= 3; i++)
      LikeProfile(
        userId: i,
        displayName: 'Membre $i',
        age: 25 + i,
        likedAt: DateTime.now().subtract(Duration(hours: 5 * i)),
      ),
  ],
);

final Map<String, LikesData> _states = {
  'free, 14 likes, blurred photos': _free(14, photo: true),
  'free, 5 likes, no usable photo': _free(5, photo: false),
  'free, 6 likes, photos for some': _free(6, photo: true, mixed: true),
  'free, 1 like': _free(1, photo: true),
  'subscriber, Super Like with a word': _subscriber(),
};

Future<void> _open(
  WidgetTester tester,
  DuoPose pose,
  LikesData data,
  Locale locale,
  Brightness brightness,
) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(DuoPoseController(pose)),
      home: LikesScreen(apiService: _Api(data)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    // The offer of the third like has been made: it does not cover the grid
    // (its own sweep is purchase_moment_duo_test.dart).
    SharedPreferences.setMockInitialValues({
      'purchase_moment.third_like_done': true,
    });
    PurchaseMoments.resetForTest();
    PremiumGate.resetForTest();
  });

  for (final pose in DuoPose.values) {
    for (final brightness in Brightness.values) {
      for (final locale in const [Locale('fr'), Locale('he'), Locale('ru')]) {
        for (final state in _states.entries) {
          testWidgets('${state.key} in ${pose.name} ${locale.languageCode} '
              '${brightness.name}', (tester) async {
            await _open(tester, pose, state.value, locale, brightness);
            final reason = '${state.key} in ${pose.name}';

            expect(tester.takeException(), isNull, reason: reason);
            expect(tappableProblems(tester, pose), isEmpty, reason: reason);
            expect(foldCrossingProblems(tester, pose), isEmpty, reason: reason);
            if (locale.languageCode == 'fr') {
              expect(
                navigationOutsideColumnProblems(tester, pose),
                isEmpty,
                reason: reason,
              );
            }
            // Without mazl+ the first name never reaches the screen.
            if (!state.value.isPremium) {
              expect(find.textContaining('Jeanne'), findsNothing);
            }
          });
        }
      }
    }
  }
}
