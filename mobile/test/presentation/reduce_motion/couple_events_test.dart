import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_events_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../support/reduce_motion_support.dart';

// « Découvrir les événements » sends the user back to the first tab: no slide
// under « Réduire les animations ».

void main() {
  group('couple events: « Découvrir les événements »', () {
    const upcoming = 'GET /api/couple/events?limit=50&offset=0';
    const registered = 'GET /api/couple/events/registered';

    Future<void> openRegisteredTab(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final transport = FakeCoupleTransport()
        ..reply(upcoming, ok({'events': []}))
        ..reply(registered, ok({'events': []}));
      await tester.pumpWidget(
        reduceMotionApp(
          home: CoupleEventsScreen(
            apiService: CoupleApiService(transport: transport),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.textContaining('Inscrits'));
      await tester.pumpAndSettle();
    }

    TabBar tabBar(WidgetTester tester) => tester.widget(find.byType(TabBar));

    testWidgets('Reduce Motion on: back to the first tab in one frame', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await openRegisteredTab(tester);
      expect(tabBar(tester).controller!.index, 1);

      await tester.tap(find.text('Découvrir les événements'));
      await tester.pump();

      expect(tabBar(tester).controller!.index, 0);
      expect(tabBar(tester).controller!.indexIsChanging, isFalse);
      expect(tabBar(tester).controller!.animation!.value, 0);
    });

    testWidgets('Reduce Motion off: the tab slides back', (tester) async {
      await openRegisteredTab(tester);

      await tester.tap(find.text('Découvrir les événements'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tabBar(tester).controller!.indexIsChanging, isTrue);
      expect(
        tabBar(tester).controller!.animation!.value,
        inExclusiveRange(0, 1),
      );
    });
  });
}
