import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/likes/widgets/like_widgets.dart';
import 'package:mazl/presentation/features/matching/widgets/avatar_ring.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

BoxDecoration _ringDecoration(WidgetTester tester) {
  final ring = tester.widget<Container>(
    find.byKey(const ValueKey('avatar-ring')),
  );
  return ring.decoration! as BoxDecoration;
}

void main() {
  group('anneau des nouveaux matchs', () {
    testWidgets('un nouveau match a un anneau tekhelet de 2 pt et son prénom', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AvatarRing(name: 'Léa', isNew: true)),
      );

      expect(find.text('Léa'), findsOneWidget);
      final border = _ringDecoration(tester).border! as Border;
      expect(border.top.color, AppColors.tekhelet);
      expect(border.top.width, 2);
      expect(_ringDecoration(tester).shape, BoxShape.circle);
      expect(
        tester.getSize(find.byKey(const ValueKey('avatar-ring'))),
        const Size(68, 68),
      );
    });

    testWidgets('un match plus ancien a un filet gris, pas de tekhelet', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AvatarRing(name: 'Noé')));

      final border = _ringDecoration(tester).border! as Border;
      expect(border.top.color, AppColors.hairline);
      expect(border.top.color, isNot(AppColors.tekhelet));
    });

    testWidgets('toucher l’avatar déclenche l’ouverture du chat', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AvatarRing(name: 'Léa', isNew: true, onTap: () => taps++)),
      );

      await tester.tap(find.text('Léa'));
      expect(taps, 1);
    });
  });

  group('tuile verrouillée', () {
    testWidgets('cadenas, libellé « Profil masqué » et aucune photo', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(LockedLikeTile(onTap: () => taps++)));

      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.byType(ProfilePhoto), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.bySemanticsLabel('Profil masqué'), findsOneWidget);
      expect(tester.getSize(find.byType(LockedLikeTile)).height, 120);

      await tester.tap(find.byType(LockedLikeTile));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('la tuile est un aplat brume à coins de 24', (tester) async {
      await tester.pumpWidget(_host(LockedLikeTile(onTap: () {})));

      final tile = tester.widget<Container>(
        find.descendant(
          of: find.byType(LockedLikeTile),
          matching: find.byType(Container),
        ),
      );
      final decoration = tile.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.mist);
      expect(decoration.borderRadius, BorderRadius.circular(24));
    });
  });

  group('carte de like visible', () {
    testWidgets('affiche « Prénom, âge » et la photo de repli', (tester) async {
      await tester.pumpWidget(
        _host(LikeCard(name: 'Sarah', age: 29, onTap: () {})),
      );

      expect(find.text('Sarah, 29'), findsOneWidget);
      expect(find.byType(ProfilePhoto), findsOneWidget);
    });

    testWidgets('les actions passer et aimer ont un libellé et réagissent', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var liked = 0;
      var passed = 0;
      await tester.pumpWidget(
        _host(
          LikeCard(
            name: 'Sarah',
            onTap: () {},
            onLike: () => liked++,
            onPass: () => passed++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aimer Sarah'));
      await tester.tap(find.bySemanticsLabel('Passer Sarah'));
      expect(liked, 1);
      expect(passed, 1);
      semantics.dispose();
    });
  });

  group('pilule mazl+', () {
    testWidgets('présente, avec « + » en tekhelet, et touchable', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MazlPlusPill(
            prefix: 'Voir les 8 autres avec ',
            onPressed: () => taps++,
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Voir les 8 autres avec mazl+'),
        findsOneWidget,
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(MazlPlusPill),
          matching: find.byType(Text),
        ),
      );
      final span = text.textSpan! as TextSpan;
      final plus = span.children!.cast<TextSpan>().last;
      expect(plus.text, '+');
      expect(plus.style!.color, AppColors.tekhelet);
      expect(plus.style!.fontWeight, FontWeight.w700);

      await tester.tap(find.byType(MazlPlusPill));
      expect(taps, 1);
    });

    testWidgets('est un bouton en contour, haut de 56', (tester) async {
      await tester.pumpWidget(
        _host(MazlPlusPill(prefix: 'Voir avec ', onPressed: () {})),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(tester.getSize(find.byType(OutlinedButton)).height, 56);
    });
  });

  testWidgets('aucun dégradé dans l’arbre des widgets', (tester) async {
    await tester.pumpWidget(
      _host(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const AvatarRing(name: 'Léa', isNew: true),
              const AvatarRing(name: 'Noé'),
              LikeCard(
                name: 'Sarah',
                age: 29,
                onTap: () {},
                onLike: () {},
                onPass: () {},
              ),
              LockedLikeTile(onTap: () {}),
              MazlPlusPill(prefix: 'Voir les 8 autres avec ', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    final gradients = <Widget>[];
    for (final element in find.byType(DecoratedBox).evaluate()) {
      final box = element.widget as DecoratedBox;
      final decoration = box.decoration;
      if (decoration is BoxDecoration && decoration.gradient != null) {
        gradients.add(box);
      }
    }
    expect(gradients, isEmpty);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).gradient != null,
      ),
      findsNothing,
    );
  });
}
