import 'package:flutter/material.dart';

enum DocumentKind { passport, idCard }

/// Where the chip sits on each document, drawn as two small sketches.
class ChipLocationIllustration extends StatelessWidget {
  const ChipLocationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Sketch(kind: DocumentKind.passport, size: const Size(110, 150), caption: 'Passeport\nPage de la photo', theme: theme),
        _Sketch(kind: DocumentKind.idCard, size: const Size(150, 100), caption: 'Carte d\'identité\nAu dos', theme: theme),
      ],
    );
  }
}

class _Sketch extends StatelessWidget {
  const _Sketch({required this.kind, required this.size, required this.caption, required this.theme});

  final DocumentKind kind;
  final Size size;
  final String caption;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: size,
            painter: DocumentSketchPainter(kind: kind, ink: theme.colorScheme.onSurfaceVariant, accent: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(caption, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      );
}

class DocumentSketchPainter extends CustomPainter {
  const DocumentSketchPainter({required this.kind, required this.ink, required this.accent});

  final DocumentKind kind;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final faint = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mark = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), line);

    final Offset chip;
    switch (kind) {
      case DocumentKind.passport:
        // Photo and text lines of the data page, chip under them.
        canvas.drawRect(Rect.fromLTWH(size.width * 0.12, size.height * 0.1, size.width * 0.32, size.height * 0.28), faint);
        for (var i = 0; i < 3; i++) {
          final y = size.height * (0.14 + i * 0.08);
          canvas.drawLine(Offset(size.width * 0.52, y), Offset(size.width * 0.88, y), faint);
        }
        chip = Offset(size.width * 0.5, size.height * 0.68);
      case DocumentKind.idCard:
        // Back of the card: text lines at the bottom, chip on the left.
        for (var i = 0; i < 2; i++) {
          final y = size.height * (0.76 + i * 0.1);
          canvas.drawLine(Offset(size.width * 0.1, y), Offset(size.width * 0.9, y), faint);
        }
        chip = Offset(size.width * 0.28, size.height * 0.36);
    }

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: chip, width: 22, height: 17), const Radius.circular(3)), mark);
    for (var i = 1; i <= 2; i++) {
      final r = 14.0 + i * 7;
      canvas.drawArc(Rect.fromCenter(center: chip, width: r * 2, height: r * 2), -0.7, 1.4, false, mark..color = accent.withValues(alpha: 1 - i * 0.3));
    }
  }

  @override
  bool shouldRepaint(DocumentSketchPainter old) => old.kind != kind || old.ink != ink || old.accent != accent;
}
