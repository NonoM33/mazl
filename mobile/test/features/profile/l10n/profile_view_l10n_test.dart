import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/compatibility_score.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/presentation/features/matching/widgets/match_sheet.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_action_bar.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_compatibility_section.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_completion_card.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_couple_section.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_photo_gallery.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_top_bar.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_view_content.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_view_data.dart';

import '../../../helpers/l10n_helpers.dart';

const _en = Locale('en');
const _he = Locale('he');
const _ru = Locale('ru');
const _es = Locale('es');

final _jeanne = Profile(id: 7, userId: 42, displayName: 'Jeanne');

const _member = ProfileViewData(
  name: 'Jeanne Exemple',
  age: 29,
  location: 'Paris',
  distance: 4.2,
  bio: 'Friday dinners and long walks.',
  lookingFor: 'Something lasting.',
  gender: 'female',
  denomination: 'Massorti',
  kashrut: 'A la maison',
  shabbatObservance: 'Partiellement',
  isVerified: true,
  verificationLevel: 'verified_plus',
);

Widget _content({bool own = false}) => Scaffold(
  body: ProfileViewContent(
    data: _member,
    isOwnProfile: own,
    bottomPadding: 120,
    topBar: own
        ? ProfileTopBar.own(onEdit: () {}, onSettings: () {})
        : ProfileTopBar.other(onBack: () {}, onOptions: () {}),
    prompts: const [(question: 'My ideal Shabbat...', answer: 'A long table.')],
  ),
);

void main() {
  setUpAll(loadAppFonts);

  group('profil d\'un membre en anglais', () {
    testWidgets('sections, faits et pastille de vérification', (tester) async {
      await pumpLocalized(tester, _content(), locale: _en);

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('THE ESSENTIALS'), findsOneWidget);
      expect(find.text("WHAT I'M LOOKING FOR"), findsOneWidget);
      expect(find.text('IN A FEW WORDS'), findsOneWidget);
      expect(find.text('Paris · 4 km away'), findsOneWidget);
      expect(find.text('Verified+'), findsOneWidget);
      // « L'essentiel » : libellé et valeur, dans la langue du membre.
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Masorti'), findsOneWidget);
      expect(find.text('Kosher at home'), findsOneWidget);
      expect(find.text('Partial Shabbat'), findsOneWidget);
      expect(find.text('Woman'), findsOneWidget);
      // Aucun morceau de français ne reste.
      expect(find.text('À propos'), findsNothing);
      expect(find.text('Cacher à la maison'), findsNothing);
    });

    testWidgets(
      'son profil : barre du haut et invitation à ajouter des photos',
      (tester) async {
        await pumpLocalized(tester, _content(own: true), locale: _en);

        expect(find.text('MY PROFILE'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Add photos'), findsOneWidget);
        expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      },
    );

    testWidgets('barre d\'actions et fenêtre de match', (tester) async {
      await pumpLocalized(
        tester,
        ProfileActionBar(firstName: 'Jeanne', onPass: () {}, onLike: () {}),
        locale: _en,
      );
      expect(find.text('Like Jeanne'), findsOneWidget);

      await pumpLocalized(
        tester,
        MatchSheetContent(matched: _jeanne),
        locale: _en,
      );
      expect(find.text("It's a match!"), findsOneWidget);
      expect(find.text('You and Jeanne liked each other.'), findsOneWidget);
      expect(find.text('Send a message'), findsOneWidget);
      expect(find.text('Keep discovering'), findsOneWidget);
    });

    testWidgets(
      'sans prénom, la fenêtre de match parle de « cette personne »',
      (tester) async {
        await pumpLocalized(
          tester,
          MatchSheetContent(matched: Profile(id: 1, userId: 2)),
          locale: _ru,
        );
        expect(find.text('Вы понравились друг другу.'), findsOneWidget);
      },
    );

    testWidgets('mode couple : cinq états', (tester) async {
      Future<void> show(CoupleEntryState state) => pumpLocalized(
        tester,
        SingleChildScrollView(
          child: ProfileCoupleSection(state: state, userName: 'Jeanne'),
        ),
        locale: _en,
      );

      await show(CoupleEntryState.available);
      expect(find.text('Turn on with Jeanne'), findsOneWidget);
      await show(CoupleEntryState.pending);
      expect(find.text("Jeanne hasn't replied yet."), findsOneWidget);
      await show(CoupleEntryState.received);
      expect(find.text('Reply'), findsOneWidget);
      await show(CoupleEntryState.inCouple);
      expect(find.text("You're in couple mode with Jeanne."), findsOneWidget);
      await show(CoupleEntryState.coupleWithSomeoneElse);
      expect(find.text('Already in couple mode'), findsOneWidget);
    });
  });

  group('carte de complétion', () {
    List<CompletionStep> steps({bool photos = false, bool bio = false}) =>
        buildCompletionSteps(
          photos: photos ? ['a', 'b'] : const [],
          bio: bio ? 'Hello' : null,
          isVerified: false,
          location: null,
        );

    testWidgets('le pluriel suit la langue (russe : 4 formes)', (tester) async {
      final l10n = lookupAppLocalizations(_ru);
      expect(l10n.profileCompletionRemaining(1), 'Остался 1 шаг');
      expect(l10n.profileCompletionRemaining(2), 'Осталось 2 шага');
      expect(l10n.profileCompletionRemaining(5), 'Осталось 5 шагов');
      expect(l10n.profileCompletionRemaining(21), 'Остался 21 шаг');

      await pumpLocalized(
        tester,
        SingleChildScrollView(
          child: ProfileCompletionCard(
            steps: steps(photos: true),
            onStep: (_) {},
          ),
        ),
        locale: _ru,
      );
      expect(find.text('Осталось 3 шага'), findsOneWidget);
    });

    testWidgets('en anglais : titre, étapes faites et à faire', (tester) async {
      await pumpLocalized(
        tester,
        SingleChildScrollView(
          child: ProfileCompletionCard(
            steps: steps(photos: true),
            onStep: (_) {},
          ),
        ),
        locale: _en,
      );
      expect(find.text('PROFILE · 1/4'), findsOneWidget);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('3 steps left'), findsOneWidget);
      expect(find.text('Photos added'), findsOneWidget);
      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Complete it now'), findsOneWidget);
    });

    testWidgets("l'hébreu a une forme pour deux", (tester) async {
      final l10n = lookupAppLocalizations(_he);
      expect(l10n.profileCompletionRemaining(1), 'שלב אחד נותר');
      expect(l10n.profileCompletionRemaining(2), 'שני שלבים נותרו');
      expect(l10n.profileCompletionRemaining(3), '3 שלבים נותרו');
    });
  });

  group('compatibilité', () {
    final score = CompatibilityScore(
      score: 90,
      isSuperCompatible: true,
      factors: [
        CompatibilityFactor(verdict: CompatibilityVerdict.veryNear, score: 100),
        CompatibilityFactor(
          verdict: CompatibilityVerdict.sameIntention,
          score: 100,
        ),
        CompatibilityFactor(
          verdict: CompatibilityVerdict.largeAgeGap,
          score: 20,
        ),
      ],
    );

    testWidgets('le score d\'un abonné se lit en espagnol', (tester) async {
      await pumpLocalized(
        tester,
        SingleChildScrollView(
          child: ProfileCompatibilitySection(
            firstName: 'Jeanne',
            hasPremium: true,
            score: score,
            onUnlock: () {},
          ),
        ),
        locale: _es,
      );
      expect(find.text('COMPATIBILIDAD'), findsOneWidget);
      expect(find.text('Muy compatible'), findsOneWidget);
      expect(
        find.text(
          'Muy cerca (< 10 km) · Buscáis lo mismo · Gran diferencia de edad',
        ),
        findsOneWidget,
      );
    });

    testWidgets('l\'invitation (non abonné) cite le prénom', (tester) async {
      await pumpLocalized(
        tester,
        SingleChildScrollView(
          child: ProfileCompatibilitySection(
            firstName: 'Jeanne',
            hasPremium: false,
            score: null,
            onUnlock: () {},
          ),
        ),
        locale: _en,
      );
      expect(
        find.text('Find out your compatibility score with Jeanne.'),
        findsOneWidget,
      );
      expect(find.text('Unlock with mazl+'), findsOneWidget);
    });

    test('les paliers viennent du score, pas du texte', () {
      CompatibilityScore at(int s) => CompatibilityScore(
        score: s,
        isSuperCompatible: s >= 85,
        factors: const [],
      );
      expect(at(90).level, CompatibilityLevel.veryCompatible);
      expect(at(60).level, CompatibilityLevel.compatible);
      expect(at(40).level, CompatibilityLevel.average);
      expect(at(39).level, CompatibilityLevel.low);
    });
  });

  group('de droite à gauche (hébreu)', () {
    for (final brightness in Brightness.values) {
      testWidgets('profil complet, ${brightness.name}, à 360 px', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          _content(),
          locale: _he,
          brightness: brightness,
        );

        expect(
          textDirectionAt(tester, find.textContaining('Jeanne Exemple')),
          TextDirection.rtl,
        );
        expect(find.text('אודות'), findsOneWidget);
        expect(find.text('עיקרי הדברים'), findsOneWidget);
        expect(find.text('קונסרבטיבי (מסורטי)'), findsOneWidget);
        expect(find.text('Paris · במרחק 4 ק״מ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('« retour » pointe vers la droite et se range à droite', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        ProfileTopBar.other(onBack: () {}, onOptions: () {}),
        locale: _he,
      );
      final back = tester.getCenter(find.bySemanticsLabel('חזרה'));
      final options = tester.getCenter(
        find.bySemanticsLabel('אפשרויות נוספות'),
      );
      expect(back.dx, greaterThan(options.dx));
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronLeft), findsNothing);
    });

    testWidgets('en français, le retour pointe vers la gauche', (tester) async {
      await pumpLocalized(
        tester,
        ProfileTopBar.other(onBack: () {}, onOptions: () {}),
      );
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets(
      'galerie : « précédente » au début de la ligne, compteur à la fin',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpLocalized(
          tester,
          const ProfilePhotoGallery(
            photos: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
          ),
          locale: _he,
        );
        final previous = tester.getCenter(
          find.bySemanticsLabel('התמונה הקודמת'),
        );
        final next = tester.getCenter(find.bySemanticsLabel('התמונה הבאה'));
        expect(previous.dx, greaterThan(next.dx));
        expect(find.bySemanticsLabel('תמונה 1 מתוך 2'), findsOneWidget);
        final counter = tester.getCenter(find.text('1/2'));
        expect(
          counter.dx,
          lessThan(180),
          reason: 'le compteur est à la fin de la ligne : à gauche en hébreu',
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'la pastille de vérification se range au début de la ligne (à droite)',
      (tester) async {
        await pumpLocalized(tester, _content(), locale: _he);
        final tag = tester.getRect(find.text('פרופיל מאומת+'));
        final screen = tester.view.physicalSize.width;
        // La marge du profil fait 24 points ; la pastille a un peu de remplissage.
        expect(screen - tag.right, lessThan(60), reason: '$tag');
      },
    );

    testWidgets('barre d\'actions et fenêtre de match tiennent en hébreu', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        ProfileActionBar(firstName: 'Jeanne', onPass: () {}, onLike: () {}),
        locale: _he,
      );
      expect(find.text('אהבתי את Jeanne'), findsOneWidget);

      await pumpLocalized(
        tester,
        MatchSheetContent(matched: _jeanne),
        locale: _he,
        brightness: Brightness.dark,
      );
      expect(find.text("יש מאץ'!"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('russe : les textes les plus longs tiennent à 360 px', () {
    testWidgets('profil, carte de complétion et mode couple', (tester) async {
      await pumpLocalized(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ProfileCompletionCard(
                  steps: buildCompletionSteps(
                    photos: const [],
                    bio: null,
                    isVerified: false,
                    location: null,
                  ),
                  onStep: (_) {},
                ),
                ProfileCoupleSection(
                  state: CoupleEntryState.available,
                  userName: 'Jeanne',
                ),
                ProfileCompatibilitySection(
                  firstName: 'Jeanne',
                  hasPremium: false,
                  score: null,
                  onUnlock: () {},
                ),
              ],
            ),
          ),
        ),
        locale: _ru,
        brightness: Brightness.dark,
      );
      expect(find.text('Заполните профиль'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
