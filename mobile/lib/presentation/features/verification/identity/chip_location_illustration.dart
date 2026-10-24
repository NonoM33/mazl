import 'package:flutter/material.dart';

/// Un téléphone posé sur la couverture fermée d'un passeport : l'endroit où
/// la puce se lit. Dessin statique, sans animation.
class ChipLocationIllustration extends StatelessWidget {
  const ChipLocationIllustration({super.key});

  static const _width = 240.0;
  static const _height = 250.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Le haut du téléphone posé contre la couverture fermée du passeport',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            children: [
              Positioned(left: 40, top: 70, child: _Cover(scheme: scheme)),
              Positioned(left: 100, top: 18, child: _Phone(scheme: scheme)),
              Positioned(
                left: 144,
                top: 0,
                child: CustomPaint(size: const Size(28, 18), painter: _WavesPainter(scheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: 170,
    alignment: Alignment.bottomCenter,
    padding: const EdgeInsets.only(bottom: 26),
    decoration: BoxDecoration(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: scheme.outline),
    ),
    child: CustomPaint(size: const Size(38, 26), painter: _ChipPainter(scheme.onSurfaceVariant)),
  );
}

class _Phone extends StatelessWidget {
  const _Phone({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 196,
    alignment: Alignment.topCenter,
    padding: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: scheme.onSurface, width: 2),
    ),
    child: Container(
      // not a drag handle: the phone's earpiece in the drawing
      width: 34,
      height: 6,
      decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(3)),
    ),
  );
}

class _ChipPainter extends CustomPainter {
  const _ChipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), const Radius.circular(5)),
      line,
    );
    final middle = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(middle, 5, line);
    canvas.drawLine(Offset(1, middle.dy), Offset(middle.dx - 5, middle.dy), line);
    canvas.drawLine(Offset(middle.dx + 5, middle.dy), Offset(size.width - 1, middle.dy), line);
    canvas.drawLine(Offset(middle.dx, 1), Offset(middle.dx, middle.dy - 5), line);
    canvas.drawLine(Offset(middle.dx, middle.dy + 5), Offset(middle.dx, size.height - 1), line);
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(4, 14)
        ..quadraticBezierTo(14, 2, 24, 14),
      wave,
    );
    canvas.drawPath(
      Path()
        ..moveTo(9, 17)
        ..quadraticBezierTo(14, 11, 19, 17),
      wave,
    );
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.color != color;
}
