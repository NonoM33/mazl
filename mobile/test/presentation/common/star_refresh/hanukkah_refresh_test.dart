import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/hanukkah_night.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/hanukkiah_frame.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/hanukkiah_painter.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_frame.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_painter.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_refresh.dart';

// docs/design/MOUVEMENT.md §7bis: during the eight nights of Hanukkah, a
// hanukkiah lit for the night stands in for the star. Dates from the Hebrew
// calendar: in 2025 the first candle is lit on the evening of 14 December, the
// eighth on the evening of 21 December; in 2026, from the evening of 4 December.

void main() {
  group('hanukkahNight', () {
    test('no candle the rest of the year', () {
      expect(hanukkahNight(DateTime(2026, 10, 27, 12)), 0);
      expect(hanukkahNight(DateTime(2025, 12, 14, 12)), 0);
    });

    test('the first candle from the evening before the 25th of Kislev', () {
      expect(hanukkahNight(DateTime(2025, 12, 14, 20)), 1);
      expect(hanukkahNight(DateTime(2025, 12, 15, 10)), 1);
      expect(hanukkahNight(DateTime(2026, 12, 4, 21)), 1);
    });

    test('the eighth night, then nothing', () {
      expect(hanukkahNight(DateTime(2025, 12, 21, 19)), 8);
      expect(hanukkahNight(DateTime(2025, 12, 22, 12)), 8);
      expect(hanukkahNight(DateTime(2025, 12, 22, 19)), 0);
    });
  });

  group('HanukkiahFrame', () {
    test('candles are set from the right, one more each night', () {
      expect(HanukkiahFrame.litSlots(1), [8]);
      expect(HanukkiahFrame.litSlots(3), [6, 7, 8]);
      expect(HanukkiahFrame.litSlots(8), [0, 1, 2, 3, 5, 6, 7, 8]);
    });

    test('the shamash first, then the newest candle towards the right', () {
      expect(HanukkiahFrame.lightingOrder(3), [
        HanukkiahFrame.shamash,
        6,
        7,
        8,
      ]);
    });

    test('pulled to the threshold: every flame of the night burns, the other '
        'places stay dark', () {
      final frame = HanukkiahFrame.of(const StarPulled(1), 3);
      expect(frame.body, 1);
      for (var slot = 0; slot < HanukkiahFrame.slots; slot++) {
        final lit = slot == HanukkiahFrame.shamash || slot >= 6;
        expect(frame.flames[slot], lit ? 1 : 0, reason: 'slot $slot');
      }
    });

    test('half way through the lighting, the shamash burns before the '
        'others', () {
      final frame = HanukkiahFrame.of(const StarPulled(0.7), 8);
      expect(frame.flames[HanukkiahFrame.shamash], 1);
      expect(frame.flames[8], 0);
    });

    test('the flames rest at full size on every whole loading turn', () {
      final frame = HanukkiahFrame.of(
        StarLoading(MazlMotion.refreshCycle * 2),
        5,
      );
      for (final slot in HanukkiahFrame.lightingOrder(5)) {
        expect(frame.flames[slot], closeTo(1, 1e-9));
      }
    });

    test('reduced motion: flames burn still while loading', () {
      final frame = HanukkiahFrame.of(
        StarLoading(MazlMotion.refreshCycle * 0.4, reduced: true),
        5,
      );
      for (final slot in HanukkiahFrame.lightingOrder(5)) {
        expect(frame.flames[slot], 1);
      }
    });
  });

  testWidgets('a pull during Hanukkah shows the hanukkiah, the rest of the '
      'year the star', (tester) async {
    Future<CustomPainter?> painterAt(DateTime now) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRefresh(
              key: UniqueKey(),
              clock: () => now,
              onRefresh: () async {},
              child: ListView(
                children: [for (var i = 0; i < 30; i++) Text('row $i')],
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(const Offset(100, 100));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<CustomPainter>()
          .where((p) => p is StarPainter || p is HanukkiahPainter)
          .toList();
      await gesture.up();
      await tester.pumpAndSettle();
      return painters.isEmpty ? null : painters.first;
    }

    expect(
      await painterAt(DateTime(2025, 12, 17, 20)),
      isA<HanukkiahPainter>(),
    );
    expect(await painterAt(DateTime(2026, 6, 1, 20)), isA<StarPainter>());
  });
}
