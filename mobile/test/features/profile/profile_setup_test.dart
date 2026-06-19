import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mazl/presentation/features/profile/screens/profile_setup_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ProfileSetupScreen', () {
    testWidgets('renders the basic info step with controllers', (tester) async {
      await tester.pumpWidget(
        createSimpleTestableWidget(const ProfileSetupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parle-nous de toi'), findsOneWidget);
      // Both name and city fields are now backed by controllers.
      expect(find.widgetWithText(TextFormField, 'Prenom'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ville'), findsOneWidget);
      expect(find.text('Etape 1/4'), findsOneWidget);
    });

    testWidgets('blocks advancing when required fields are empty',
        (tester) async {
      await tester.pumpWidget(
        createSimpleTestableWidget(const ProfileSetupScreen()),
      );
      await tester.pumpAndSettle();

      // Tap "Suivant" with no name/date/gender -> validation snackbar, stay put.
      await tester.tap(find.text('Suivant'));
      await tester.pump();

      expect(find.text('Indique ton prenom pour continuer'), findsOneWidget);
      // Still on step 1.
      expect(find.text('Parle-nous de toi'), findsOneWidget);
    });

    testWidgets('gender selection is functional and not hard-coded',
        (tester) async {
      await tester.pumpWidget(
        createSimpleTestableWidget(const ProfileSetupScreen()),
      );
      await tester.pumpAndSettle();

      // No gender chip is selected initially (no hard-coded selected: true).
      Container chipContainer(String label) => tester.widget<Container>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(Container),
            ),
          );

      final initialDecoration =
          chipContainer('Un homme').decoration! as BoxDecoration;
      expect(initialDecoration.color, Colors.transparent);

      // Tapping selects it.
      await tester.tap(find.text('Un homme'));
      await tester.pump();

      final selectedDecoration =
          chipContainer('Un homme').decoration! as BoxDecoration;
      expect(selectedDecoration.color, isNot(Colors.transparent));
    });

    testWidgets('birthdate field opens a date picker on tap', (tester) async {
      await tester.pumpWidget(
        createSimpleTestableWidget(const ProfileSetupScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.calendar));
      await tester.pumpAndSettle();

      // The Material date picker dialog is shown.
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}
