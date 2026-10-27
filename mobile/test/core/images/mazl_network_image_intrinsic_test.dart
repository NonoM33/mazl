import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/images/mazl_network_image.dart';

void main() {
  // A card measured by IntrinsicHeight asks its photo for a natural height.
  // A photo not loaded yet has none: it must answer, not break the layout
  // (the couple's Today card on the closed Duo, 2026-10-27).
  testWidgets('a network photo inside an IntrinsicHeight row lays out', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 112,
                  child: MazlNetworkImage(url: 'https://example.com/p.jpg'),
                ),
                Expanded(child: Text('Cours de pâtisserie à deux')),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final photo = tester.getSize(find.byType(MazlNetworkImage));
    final text = tester.getSize(find.text('Cours de pâtisserie à deux'));
    expect(photo.width, 112);
    expect(photo.height, text.height);
  });
}
