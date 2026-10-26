import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import '../../helpers/l10n_helpers.dart';

Profile _profile({bool verified = true, List<String> photos = const []}) => Profile(
      id: 7,
      userId: 7,
      displayName: 'Léa',
      age: 28,
      location: 'Paris',
      distance: 4.2,
      denomination: 'massorti',
      kashrut: 'kasher_a_la_maison',
      shabbatObservance: 'shabbat_en_famille',
      relationshipIntention: 'mariage',
      isVerified: verified,
      photos: photos,
    );

Future<void> _pump(
  WidgetTester tester,
  Profile profile, {
  VoidCallback? onPass,
  VoidCallback? onLike,
  VoidCallback? onTapProfile,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 358,
            height: 640,
            child: DiscoverCard(
              profile: profile,
              onPass: onPass ?? () {},
              onLike: onLike ?? () {},
              onTapProfile: onTapProfile,
            ),
          ),
        ),
      ),
    ),
  );
}

bool _hasGradient(Widget w) {
  if (w is DecoratedBox) {
    final d = w.decoration;
    return d is BoxDecoration && d.gradient != null;
  }
  if (w is Container) {
    final d = w.decoration;
    return d is BoxDecoration && d.gradient != null;
  }
  return false;
}

void main() {
  // Seen on 2026-10-26: the full profile opened only by touching the name,
  // which nothing showed. A visible « Voir le profil » button opens it.
  testWidgets('a visible « Voir le profil » button opens the profile', (
    tester,
  ) async {
    var opened = 0;
    await _pump(tester, _profile(), onTapProfile: () => opened++);
    final button = find.byKey(const ValueKey('discover-view-profile'));
    expect(button, findsOneWidget);
    expect(find.text('Voir le profil'), findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    await tester.tap(button);
    expect(opened, 1);
  });


  testWidgets('affiche nom, âge, ville, distance et puces', (tester) async {
    await _pump(tester, _profile());

    expect(find.textContaining('Léa'), findsOneWidget);
    expect(find.textContaining('28'), findsOneWidget);
    expect(find.text('Paris · à 4 km'), findsOneWidget);
    for (final tag in ['Massorti', 'Cacher à la maison', 'Shabbat en famille', 'Mariage']) {
      expect(find.text(tag), findsOneWidget);
    }
  });

  testWidgets('omet la ligne de contexte quand rien n\'est connu', (tester) async {
    await _pump(
      tester,
      Profile(id: 1, userId: 1, displayName: 'Noa', age: 31),
    );
    expect(find.textContaining('·'), findsNothing);
    expect(find.textContaining('km'), findsNothing);
  });

  testWidgets('« Vérifiée » seulement pour un profil vérifié', (tester) async {
    await _pump(tester, _profile());
    expect(find.text('Vérifiée'), findsOneWidget);

    await _pump(tester, _profile(verified: false));
    expect(find.text('Vérifiée'), findsNothing);
  });

  testWidgets('passer et aimer ont un libellé et appellent leur rappel', (tester) async {
    var passed = 0;
    var liked = 0;
    await _pump(tester, _profile(), onPass: () => passed++, onLike: () => liked++);

    final pass = find.bySemanticsLabel('Passer');
    final like = find.bySemanticsLabel("J'aime");
    expect(pass, findsOneWidget);
    expect(like, findsOneWidget);
    expect(tester.getSize(pass).shortestSide, greaterThanOrEqualTo(44));

    await tester.tap(pass);
    await tester.tap(like);
    expect(passed, 1);
    expect(liked, 1);
  });

  testWidgets('toucher le nom ouvre le profil', (tester) async {
    var opened = 0;
    await _pump(tester, _profile(), onTapProfile: () => opened++);
    await tester.tap(find.textContaining('Léa'));
    expect(opened, 1);
  });

  testWidgets('les barres de photo n\'existent qu\'avec plusieurs photos', (tester) async {
    await _pump(tester, _profile());
    expect(find.byKey(const Key('photo-bar-0')), findsNothing);

    await _pump(tester, _profile(photos: ['', '', '']));
    expect(find.byKey(const Key('photo-bar-0')), findsOneWidget);
    expect(find.byKey(const Key('photo-bar-2')), findsOneWidget);
  });

  testWidgets('aucun dégradé dans l\'arbre', (tester) async {
    await _pump(tester, _profile(photos: ['', '']));
    final gradients = find.byWidgetPredicate(_hasGradient);
    expect(gradients, findsNothing);
  });
}
