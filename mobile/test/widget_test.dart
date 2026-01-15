import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mazl/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MazlApp(),
      ),
    );

    // Verify that the app starts
    await tester.pumpAndSettle();

    // The app should show the splash screen or navigate to onboarding
    expect(find.text('MAZL'), findsOneWidget);
  });
}
