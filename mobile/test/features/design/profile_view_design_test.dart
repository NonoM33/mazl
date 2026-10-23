import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_action_bar.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_compatibility_section.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_completion_card.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_couple_section.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_match_dialog.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_sections.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_top_bar.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_view_content.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_view_data.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

/// Aucune décoration de l'arbre ne doit porter de dégradé.
void _expectNoGradient(WidgetTester tester) {
  final gradients = <Widget>[];
  for (final element in find.byType(Container).evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      gradients.add(element.widget);
    }
  }
  for (final element in find.byType(DecoratedBox).evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      gradients.add(element.widget);
    }
  }
  expect(gradients, isEmpty, reason: 'le design Encre & Tekhelet interdit les dégradés');
}

const _full = ProfileViewData(
  name: 'Sarah Cohen',
  age: 29,
  location: 'Paris',
  distance: 4.2,
  bio: 'Je cherche quelqu\'un avec qui partager un vendredi soir.',
  lookingFor: 'Une relation sérieuse.',
  gender: 'female',
  denomination: 'Massorti',
  kashrut: 'Casher à la maison',
  shabbatObservance: 'Shabbat en famille',
  isVerified: true,
);

void main() {
  group('ProfileViewData', () {
    test('prénom, ligne meta et distance', () {
      expect(_full.firstName, 'Sarah');
      expect(_full.metaLine, 'Paris · à 4 km');
      const near = ProfileViewData(name: 'Noa', location: 'Lyon', distance: 0.3);
      expect(near.metaLine, 'Lyon · à moins de 1 km');
      const far = ProfileViewData(name: 'Noa', location: 'Lyon');
      expect(far.metaLine, 'Lyon');
    });

    test("L'essentiel ne garde que les champs renseignés", () {
      expect(_full.facts.map((f) => f.label), ['Pratique', 'Cacherout', 'Shabbat', 'Genre']);
      const partial = ProfileViewData(
        name: 'Noa',
        location: 'Lyon',
        kashrut: 'Casher',
        denomination: '  ',
      );
      expect(partial.facts.map((f) => f.label), ['Cacherout']);
      expect(const ProfileViewData(name: 'Noa', location: 'Lyon').facts, isEmpty);
    });

    test('la photo SSO sert de repli à la galerie', () {
      const sso = ProfileViewData(name: 'Noa', location: 'Lyon', fallbackPicture: 'https://x/y.jpg');
      expect(sso.galleryPhotos, ['https://x/y.jpg']);
      expect(sso.hasNoUploadedPhoto, isTrue);
    });
  });

  group("L'essentiel", () {
    testWidgets('affiche un libellé et sa valeur par champ, sans filet sur la dernière', (tester) async {
      await _pump(tester, ProfileFactsSection(facts: _full.facts));

      expect(find.text("L'ESSENTIEL"), findsOneWidget);
      for (final fact in _full.facts) {
        expect(find.text(fact.label), findsOneWidget);
        expect(find.text(fact.value), findsOneWidget);
      }
      final rows = tester.widgetList<FactRow>(find.byType(FactRow)).toList();
      expect(rows, hasLength(4));
      expect(rows.take(3).every((r) => !r.last), isTrue);
      expect(rows.last.last, isTrue);
      _expectNoGradient(tester);
    });

    testWidgets('disparaît sans aucun champ', (tester) async {
      await _pump(tester, const ProfileFactsSection(facts: []));
      expect(find.byType(FactRow), findsNothing);
      expect(find.text("L'ESSENTIEL"), findsNothing);
    });
  });

  group('prompts', () {
    testWidgets('carte brume de rayon 28 avec question et réponse', (tester) async {
      await _pump(
        tester,
        const ProfilePromptCard(question: 'Mon Shabbat idéal...', answer: 'Une longue table et des amis.'),
      );
      expect(find.text('Mon Shabbat idéal...'), findsOneWidget);
      expect(find.text('Une longue table et des amis.'), findsOneWidget);

      final box = tester.widget<Container>(find.byType(Container).first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(28));
      expect(decoration.color, AppTheme.lightTheme.colorScheme.surfaceContainer);
      expect(decoration.boxShadow, isNull);
      _expectNoGradient(tester);
    });
  });

  group("barre d'actions", () {
    testWidgets("« J'aime <Prénom> » déclenche l'action, la croix passe", (tester) async {
      var liked = 0;
      var passed = 0;
      await _pump(
        tester,
        ProfileActionBar(firstName: 'Sarah', onPass: () => passed++, onLike: () => liked++),
      );

      expect(find.text("J'aime Sarah"), findsOneWidget);
      await tester.tap(find.text("J'aime Sarah"));
      expect(liked, 1);
      expect(passed, 0);

      await tester.tap(find.byIcon(LucideIcons.x));
      expect(passed, 1);
    });

    testWidgets('64 de haut, bouton de passage rond de 64', (tester) async {
      await _pump(tester, ProfileActionBar(firstName: 'Sarah', onPass: () {}, onLike: () {}));
      final pill = find.descendant(of: find.byType(Expanded), matching: find.byType(Material)).first;
      expect(tester.getSize(pill).height, 64);
      expect(tester.getSize(find.byType(RoundIconButton)), const Size(64, 64));
      _expectNoGradient(tester);
    });

    testWidgets('un long prénom ne déborde pas', (tester) async {
      await _pump(
        tester,
        ProfileActionBar(firstName: 'Marie-Antoinette-Élisabeth', onPass: () {}, onLike: () {}),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('rangée du haut', () {
    testWidgets('autre profil : retour et options étiquetés, 44 minimum', (tester) async {
      final semantics = tester.ensureSemantics();
      var back = 0;
      var options = 0;
      await _pump(tester, ProfileTopBar.other(onBack: () => back++, onOptions: () => options++));

      expect(find.bySemanticsLabel('Retour'), findsOneWidget);
      expect(find.bySemanticsLabel("Plus d'options"), findsOneWidget);
      for (final size in tester.widgetList<RoundIconButton>(find.byType(RoundIconButton)).map(
            (b) => tester.getSize(find.byWidget(b)),
          )) {
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }

      await tester.tap(find.bySemanticsLabel('Retour'));
      await tester.tap(find.bySemanticsLabel("Plus d'options"));
      expect(back, 1);
      expect(options, 1);
      semantics.dispose();
    });

    testWidgets('son profil : « Modifier » et réglages', (tester) async {
      final semantics = tester.ensureSemantics();
      var edit = 0;
      var settings = 0;
      await _pump(tester, ProfileTopBar.own(onEdit: () => edit++, onSettings: () => settings++));

      expect(find.bySemanticsLabel('Réglages'), findsOneWidget);
      expect(find.bySemanticsLabel('Retour'), findsNothing);
      expect(tester.getSize(find.widgetWithText(OutlinedButton, 'Modifier')).height, greaterThanOrEqualTo(44));

      await tester.tap(find.text('Modifier'));
      await tester.tap(find.bySemanticsLabel('Réglages'));
      expect(edit, 1);
      expect(settings, 1);
      semantics.dispose();
    });
  });

  group('contenu composé', () {
    testWidgets("autre profil : nom, âge, ligne meta et sections renseignées", (tester) async {
      await _pump(
        tester,
        ProfileViewContent(
          data: _full,
          isOwnProfile: false,
          bottomPadding: 120,
          topBar: ProfileTopBar.other(onBack: () {}, onOptions: () {}),
        ),
      );

      expect(find.textContaining('Sarah Cohen'), findsOneWidget);
      expect(find.text('Paris · à 4 km'), findsOneWidget);
      expect(find.text('À PROPOS'), findsOneWidget);
      expect(find.text("L'ESSENTIEL"), findsOneWidget);
      expect(find.text('CE QUE JE RECHERCHE'), findsOneWidget);
      expect(find.text('Vérifié'), findsOneWidget);
      expect(find.byType(FactRow), findsNWidgets(4));
      expect(find.text('Ajouter des photos'), findsNothing);
      _expectNoGradient(tester);
    });

    testWidgets('son profil : pastille de vérification touchable, ajout de photos, prompts', (tester) async {
      var verification = 0;
      var addPhotos = 0;
      await _pump(
        tester,
        ProfileViewContent(
          data: const ProfileViewData(name: 'Sarah', location: 'France'),
          isOwnProfile: true,
          bottomPadding: 120,
          topBar: ProfileTopBar.own(onEdit: () {}, onSettings: () {}),
          prompts: const [(question: 'Ma fête préférée...', answer: 'Souccot.')],
          onVerificationTap: () => verification++,
          onAddPhotos: () => addPhotos++,
        ),
      );

      expect(find.text('Vérifier mon profil'), findsOneWidget);
      await tester.tap(find.text('Vérifier mon profil'));
      expect(verification, 1);

      await tester.tap(find.text('Ajouter des photos'));
      expect(addPhotos, 1);

      expect(find.text('Ma fête préférée...'), findsOneWidget);
      expect(find.text('Souccot.'), findsOneWidget);
      _expectNoGradient(tester);
    });

    testWidgets('mode sombre : aucun dégradé non plus', (tester) async {
      await _pump(
        tester,
        ProfileViewContent(
          data: _full,
          isOwnProfile: false,
          bottomPadding: 120,
          topBar: ProfileTopBar.other(onBack: () {}, onOptions: () {}),
        ),
        theme: AppTheme.darkTheme,
      );
      expect(tester.takeException(), isNull);
      _expectNoGradient(tester);
    });
  });

  group('complétion', () {
    List<CompletionStep> steps({bool photos = false, bool bio = false, bool city = false, bool verified = false}) =>
        buildCompletionSteps(
          photos: photos ? ['a', 'b'] : const [],
          bio: bio ? 'Salut' : null,
          isVerified: verified,
          location: city ? 'Paris' : 'France',
        );

    testWidgets('mène à la première étape incomplète', (tester) async {
      CompletionTarget? opened;
      await _pump(
        tester,
        SingleChildScrollView(
          child: ProfileCompletionCard(
            steps: steps(photos: true, bio: true),
            onStep: (t) => opened = t,
          ),
        ),
      );
      expect(find.text('PROFIL · 2/4'), findsOneWidget);
      await tester.tap(find.text('Compléter maintenant'));
      expect(opened, CompletionTarget.settings);
      _expectNoGradient(tester);
    });

    testWidgets('disparaît quand tout est fait', (tester) async {
      await _pump(
        tester,
        ProfileCompletionCard(
          steps: steps(photos: true, bio: true, city: true, verified: true),
          onStep: (_) {},
        ),
      );
      expect(find.text('Complète ton profil'), findsNothing);
    });
  });

  group('compatibilité et mode couple', () {
    testWidgets("sans Premium : invitation, et le bouton ouvre l'abonnement", (tester) async {
      var unlock = 0;
      await _pump(
        tester,
        SingleChildScrollView(
          child: ProfileCompatibilitySection(
            firstName: 'Sarah',
            hasPremium: false,
            score: null,
            onUnlock: () => unlock++,
          ),
        ),
      );
      expect(find.text('COMPATIBILITÉ'), findsOneWidget);
      expect(find.textContaining('avec Sarah'), findsOneWidget);
      await tester.tap(find.text('Débloquer avec mazl+'));
      expect(unlock, 1);
      _expectNoGradient(tester);
    });

    testWidgets('avec Premium et sans score : message neutre', (tester) async {
      await _pump(
        tester,
        ProfileCompatibilitySection(firstName: 'Sarah', hasPremium: true, score: null, onUnlock: () {}),
      );
      expect(find.text('Compatibilité indisponible pour le moment.'), findsOneWidget);
    });

    testWidgets('mode couple : cinq états, activation, annulation et réponse', (tester) async {
      var activated = 0;
      var cancelled = 0;
      var responded = 0;
      Future<void> show(CoupleEntryState state) => _pump(
            tester,
            SingleChildScrollView(
              child: ProfileCoupleSection(
                state: state,
                userName: 'Sarah',
                onActivate: () => activated++,
                onCancel: () => cancelled++,
                onRespond: () => responded++,
              ),
            ),
          );

      await show(CoupleEntryState.available);
      await tester.tap(find.text('Activer avec Sarah'));
      expect(activated, 1);

      await show(CoupleEntryState.pending);
      await tester.tap(find.text('Annuler la demande'));
      expect(cancelled, 1);

      await show(CoupleEntryState.received);
      await tester.tap(find.text('Répondre'));
      expect(responded, 1);

      // En couple AVEC cette personne, et non « déjà en couple » partout.
      await show(CoupleEntryState.inCouple);
      expect(find.text('Vous êtes en mode couple avec Sarah.'), findsOneWidget);
      await show(CoupleEntryState.coupleWithSomeoneElse);
      expect(find.textContaining('Sarah'), findsNothing);
      expect(find.text('Déjà en mode couple'), findsOneWidget);
      _expectNoGradient(tester);
    });

    testWidgets("fenêtre de match : deux issues, sans dégradé", (tester) async {
      var cont = 0;
      var message = 0;
      await _pump(
        tester,
        ProfileMatchDialog(name: 'Sarah', onContinue: () => cont++, onMessage: () => message++),
      );
      await tester.tap(find.text('Envoyer un message'));
      await tester.tap(find.text('Continuer'));
      expect((cont, message), (1, 1));
      _expectNoGradient(tester);
    });
  });
}
