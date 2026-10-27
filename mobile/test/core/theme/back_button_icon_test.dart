import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';

void main() {
  // The passport showed iOS's chevron while every other screen shows the
  // app's arrow (2026-10-27): the implied back button of a bar takes the
  // app's arrow from the theme, pointing the way the language reads.
  for (final (direction, icon) in [
    (TextDirection.ltr, LucideIcons.arrowLeft),
    (TextDirection.rtl, LucideIcons.arrowRight),
  ]) {
    testWidgets('a back button shows the app arrow ($direction)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.iOS),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: BackButton(onPressed: () {})),
          ),
        ),
      );
      expect(find.byIcon(icon), findsOneWidget);
    });
  }
}
