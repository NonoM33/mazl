import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_photo_gallery.dart';

import '../../support/reduce_motion_support.dart';

// Profile photo gallery: a tap on a half of the photo turns the page. Under
// « Réduire les animations » it jumps instead of sliding.

void main() {
  group('profile photo gallery', () {
    Future<void> openGallery(WidgetTester tester) async {
      await tester.pumpWidget(
        reduceMotionApp(
          home: const Scaffold(
            body: ProfilePhotoGallery(photos: ['', '', ''], height: 400),
          ),
        ),
      );
    }

    testWidgets('Reduce Motion on: a tap turns the page in one frame', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await openGallery(tester);
      expect(find.text('1/3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Photo suivante'));
      await tester.pump();

      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('Reduce Motion off: the page slides, it does not jump', (
      tester,
    ) async {
      await openGallery(tester);

      await tester.tap(find.bySemanticsLabel('Photo suivante'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('1/3'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
    });
  });
}
