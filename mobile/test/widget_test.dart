import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Basic smoke tests that don't require network calls
void main() {
  group('App Smoke Tests', () {
    testWidgets('MaterialApp can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('MAZL'),
            ),
          ),
        ),
      );

      expect(find.text('MAZL'), findsOneWidget);
    });

    testWidgets('Basic widgets render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test'),
            ),
            body: const Column(
              children: [
                Text('Hello'),
                Text('World'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('World'), findsOneWidget);
    });

    testWidgets('Button tap works', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
