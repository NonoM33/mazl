import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/duo_tutorial/duo_tutorial_layout.dart';

import '../../helpers/duo_poses.dart';

/// Où se posent la scène et le texte dans chacune des 7 poses mesurées. La page
/// est la fenêtre moins ses marges de sécurité ; le pli est ramené dans ses
/// coordonnées.
void main() {
  DuoTutorialLayout layoutFor(DuoPose pose, {bool rtl = false}) {
    final page = pose.safeRect;
    return DuoTutorialLayout.resolve(
      size: page.size,
      fold: pose.fold?.shift(-page.topLeft),
      rtl: rtl,
    );
  }

  Rect inPage(DuoPose pose, Rect rect) => rect.shift(pose.safeRect.topLeft);

  group('livre : le pli vertical sépare la scène du texte', () {
    test('en français, la scène à gauche et le texte à droite du pli', () {
      final layout = layoutFor(DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        inPage(DuoPose.halfOpenBook, layout.scene).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        inPage(DuoPose.halfOpenBook, layout.text).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(layout.stacked, isFalse);
    });

    test(
      'en hébreu, c\'est l\'inverse : le texte se lit de droite à gauche',
      () {
        final layout = layoutFor(DuoPose.halfOpenBook, rtl: true);
        final fold = DuoPose.halfOpenBook.fold!;
        expect(
          inPage(DuoPose.halfOpenBook, layout.scene).left,
          greaterThanOrEqualTo(fold.right),
        );
        expect(
          inPage(DuoPose.halfOpenBook, layout.text).right,
          lessThanOrEqualTo(fold.left),
        );
      },
    );
  });

  test('portable : la scène au-dessus du pli, le texte en dessous', () {
    final layout = layoutFor(DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    expect(
      inPage(DuoPose.halfOpenLaptop, layout.scene).bottom,
      lessThanOrEqualTo(fold.top),
    );
    expect(
      inPage(DuoPose.halfOpenLaptop, layout.text).top,
      greaterThanOrEqualTo(fold.bottom),
    );
    expect(layout.stacked, isTrue);
  });

  group('à plat', () {
    test('en paysage (ouvert, tente) : côte à côte', () {
      for (final pose in [DuoPose.openLandscape, DuoPose.tent]) {
        final layout = layoutFor(pose);
        expect(layout.stacked, isFalse, reason: pose.name);
        expect(
          layout.scene.right,
          lessThan(layout.text.left),
          reason: pose.name,
        );
      }
    });

    test(
      'en portrait (fermé, ouvert, Split View) : la scène au-dessus du texte',
      () {
        for (final pose in [
          DuoPose.closed,
          DuoPose.openPortrait,
          DuoPose.splitView,
        ]) {
          final layout = layoutFor(pose);
          expect(layout.stacked, isTrue, reason: pose.name);
          expect(
            layout.scene.bottom,
            lessThanOrEqualTo(layout.text.top),
            reason: pose.name,
          );
          expect(
            layout.text.height,
            inInclusiveRange(240, 330),
            reason: pose.name,
          );
        }
      },
    );

    test('en hébreu, côte à côte inverse la scène et le texte', () {
      final ltr = layoutFor(DuoPose.openLandscape);
      final rtl = layoutFor(DuoPose.openLandscape, rtl: true);
      expect(rtl.scene.left, greaterThan(rtl.text.left));
      expect(ltr.scene.left, lessThan(ltr.text.left));
    });
  });

  test('chaque volet reste dans la page, et la scène garde de la place', () {
    for (final pose in DuoPose.values) {
      final page = Offset.zero & pose.safeRect.size;
      final layout = layoutFor(pose);
      expect(page.contains(layout.scene.topLeft), isTrue, reason: pose.name);
      expect(
        page.inflate(0.5).contains(layout.scene.bottomRight),
        isTrue,
        reason: pose.name,
      );
      expect(
        page.inflate(0.5).contains(layout.text.bottomRight),
        isTrue,
        reason: pose.name,
      );
      expect(layout.scene.shortestSide, greaterThan(150), reason: pose.name);
    }
  });

  test('un pli qui laisse un volet trop étroit ne coupe pas la page', () {
    final layout = DuoTutorialLayout.resolve(
      size: const Size(300, 600),
      fold: const Rect.fromLTWH(60, 0, 40, 600),
      rtl: false,
    );
    expect(layout.stacked, isTrue);
  });

  test('un pli hors de la page est ignoré', () {
    final layout = DuoTutorialLayout.resolve(
      size: const Size(400, 600),
      fold: const Rect.fromLTWH(900, 0, 40, 600),
      rtl: false,
    );
    expect(layout.stacked, isTrue);
  });
}
