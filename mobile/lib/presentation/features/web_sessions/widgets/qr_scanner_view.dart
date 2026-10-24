import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../l10n/l10n.dart';

/// Builds the live camera view that reports every QR code it reads.
/// Overridden in tests so a reading can be simulated without a camera.
typedef QrScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) =>
      (context, onCode) => CameraQrScanner(onCode: onCode),
);

/// Back camera, QR codes only.
class CameraQrScanner extends StatefulWidget {
  const CameraQrScanner({super.key, required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<CameraQrScanner> createState() => _CameraQrScannerState();
}

class _CameraQrScannerState extends State<CameraQrScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw != null) widget.onCode(raw);
        }
      },
      errorBuilder: (context, error) => const _CameraUnavailable(),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          context.l10n.webSessionsCameraUnavailable,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
