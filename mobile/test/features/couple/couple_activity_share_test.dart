import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/share/share_sheet.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activity_detail_screen.dart';

import '../../helpers/l10n_helpers.dart';
import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

// The share button of an activity: on a large screen iOS refuses the share
// sheet without an origin (a popover), and the button did nothing.
void main() {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final args = call.arguments as Map<Object?, Object?>;
          final width = args['originWidth'] as double?;
          if (width == null || width <= 0) {
            throw PlatformException(
              code: 'error',
              message: 'sharePositionOrigin: argument must be set',
            );
          }
          return 'dev.fluttercommunity.plus/share/unavailable';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('sharing an activity sends text, link and a non-empty origin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final transport = FakeCoupleTransport()
      ..reply(
        'GET /api/couple/activities/4',
        ok({'activity': activityRow(id: 4, title: 'Atelier poterie')}),
      )
      ..reply('GET /api/couple/saved', ok({'activities': []}));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        home: CoupleActivityDetailScreen(
          activityId: '4',
          apiService: CoupleApiService(transport: transport),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final button = tester.getRect(find.byIcon(LucideIcons.share2));
    await tester.tap(find.byIcon(LucideIcons.share2));
    await tester.pump();

    expect(calls, hasLength(1));
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['text'], contains('Atelier poterie'));
    expect(args['text'], contains(kMazlSiteUrl));
    final origin = Rect.fromLTWH(
      args['originX']! as double,
      args['originY']! as double,
      args['originWidth']! as double,
      args['originHeight']! as double,
    );
    expect(origin.isEmpty, isFalse);
    expect(origin.contains(button.center), isTrue, reason: '$origin');
  });
}
