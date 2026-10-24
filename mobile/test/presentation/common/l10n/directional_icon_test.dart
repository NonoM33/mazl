import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/presentation/common/widgets/directional_icon.dart';

Widget _in(TextDirection direction) => Directionality(
  textDirection: direction,
  child: const Center(child: DirectionalIcon(LucideIcons.chevronRight)),
);

bool _isMirrored(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byType(Icon), matching: find.byType(Transform)),
  );
  return transforms.any((t) => t.transform.storage[0] == -1);
}

void main() {
  testWidgets('de gauche à droite, l\'icône garde son sens', (tester) async {
    await tester.pumpWidget(_in(TextDirection.ltr));
    expect(_isMirrored(tester), isFalse);
  });

  testWidgets('de droite à gauche, l\'icône est retournée', (tester) async {
    await tester.pumpWidget(_in(TextDirection.rtl));
    expect(_isMirrored(tester), isTrue);
  });
}
