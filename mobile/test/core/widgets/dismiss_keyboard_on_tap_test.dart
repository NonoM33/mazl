import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/widgets/dismiss_keyboard_on_tap.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      builder: (context, child) => DismissKeyboardOnTap(child: child!),
      home: const Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: TextField(key: Key('champ')),
            ),
            Expanded(child: SizedBox.expand(key: Key('zone-vide'))),
          ],
        ),
      ),
    );
  }

  bool champFocalise(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('un tap en dehors du champ retire le focus', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();
    expect(champFocalise(tester), isTrue);

    await tester.tap(find.byKey(const Key('zone-vide')), warnIfMissed: false);
    await tester.pump();

    expect(champFocalise(tester), isFalse);
  });

  testWidgets('un tap sur le champ conserve le focus', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();

    expect(champFocalise(tester), isTrue);
  });
}
