import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/navigation/widgets/adaptive_shell.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// The invitation of the empty detail pane ("Pick a conversation") on the
// foldable iPhone set down like a laptop: above the fold, never on it.

Future<void> _pump(WidgetTester tester, DuoPose pose) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: duoAppBuilder(DuoPoseController(pose)),
      home: const Scaffold(
        body: EmptyDetailPane(
          title: 'Choisissez une conversation',
          message: 'Elle s ouvre ici.',
        ),
      ),
    ),
  );
  await settleFold(tester);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('laptop: title and message are above the fold, centred there', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    final title = tester.getRect(find.text('Choisissez une conversation'));
    final message = tester.getRect(find.text('Elle s ouvre ici.'));
    expect(message.bottom, lessThanOrEqualTo(fold.top));
    final middle = (title.top + message.bottom) / 2;
    expect(middle, closeTo(fold.top / 2, 2));
  });

  testWidgets('flat: still centred in the pane', (tester) async {
    await _pump(tester, DuoPose.openPortrait);
    final title = tester.getRect(find.text('Choisissez une conversation'));
    final message = tester.getRect(find.text('Elle s ouvre ici.'));
    expect(
      (title.top + message.bottom) / 2,
      closeTo(DuoPose.openPortrait.size.height / 2, 2),
    );
  });
}
