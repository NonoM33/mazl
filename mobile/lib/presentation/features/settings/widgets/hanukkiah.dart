import 'package:flutter/material.dart';

/// The Hanukkah candles of one night, drawn plainly: eight places in a row
/// and the shamash, taller, in the middle. The first night lights the place
/// at the right end, each night lights one more towards the left; the shamash
/// is always lit. Nothing moves.
///
/// The drawing carries no words: the screen writes the number of the night.
class Hanukkiah extends StatelessWidget {
  const Hanukkiah({
    super.key,
    required this.night,
    required this.flame,
    required this.wax,
  });

  /// 1 to 8: the number of candles lit besides the shamash.
  final int night;
  final Color flame;
  final Color wax;

  static const places = 8;

  /// Nine slots from left to right: four places, the shamash, four places.
  static const slots = places + 1;
  static const shamashSlot = places ~/ 2;

  /// The slots lit on [night]: the shamash and, from the right end, as many
  /// places as the night has candles.
  static Set<int> litSlots(int night) => {
    shamashSlot,
    for (var place = 0; place < night; place++)
      place < places ~/ 2 ? slots - 1 - place : places - 1 - place,
  };
  static const _width = 280.0;
  static const _height = 96.0;

  @override
  Widget build(BuildContext context) {
    assert(night >= 1 && night <= places);
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(_width, _height),
        painter: _HanukkiahPainter(night: night, flame: flame, wax: wax),
      ),
    );
  }
}

class _HanukkiahPainter extends CustomPainter {
  _HanukkiahPainter({
    required this.night,
    required this.flame,
    required this.wax,
  });

  final int night;
  final Color flame;
  final Color wax;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / Hanukkiah.slots;
    final lit = Hanukkiah.litSlots(night);
    final waxPaint = Paint()..color = wax;
    final flamePaint = Paint()..color = flame;
    for (var slot = 0; slot < Hanukkiah.slots; slot++) {
      final isShamash = slot == Hanukkiah.shamashSlot;
      final x = step * (slot + 0.5);
      final stemHeight = isShamash ? 52.0 : 38.0;
      final base = size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, base - stemHeight / 2),
            width: 5,
            height: stemHeight,
          ),
          const Radius.circular(1),
        ),
        waxPaint,
      );
      if (lit.contains(slot)) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, base - stemHeight - 8),
            width: 7,
            height: 12,
          ),
          flamePaint,
        );
      }
    }
    // The foot: one line under the candles.
    canvas.drawRect(Rect.fromLTWH(0, size.height - 2, size.width, 2), waxPaint);
  }

  @override
  bool shouldRepaint(_HanukkiahPainter old) =>
      old.night != night || old.flame != flame || old.wax != wax;
}
