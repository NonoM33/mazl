import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers/web_sessions_providers.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/web_sessions/web_login_qr.dart';
import '../../../../core/web_sessions/web_sessions_api.dart';
import '../widgets/confirm_pairing_sheet.dart';
import '../widgets/qr_scanner_view.dart';

/// Reads the QR code shown by app.mazl.app and approves the login.
/// Pops with true once the computer is connected.
class WebScanScreen extends ConsumerStatefulWidget {
  const WebScanScreen({super.key});

  @override
  ConsumerState<WebScanScreen> createState() => _WebScanScreenState();
}

class _WebScanScreenState extends ConsumerState<WebScanScreen> {
  /// The camera reports the same code many times a second.
  static const _repeatDelay = Duration(seconds: 3);

  bool _busy = false;
  bool _waiting = false;
  String? _message;
  String? _lastRaw;
  DateTime? _lastAt;

  WebSessionsApi get _api => ref.read(webSessionsApiProvider);

  Future<void> _onCode(String raw) async {
    if (_busy || _isRepeat(raw)) return;
    _lastRaw = raw;
    _lastAt = clock.now();
    final code = parseWebLoginQr(raw);
    if (code == null) {
      setState(() => _message = 'Ce QR code n\'est pas un code MAZL.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    await _pair(code);
    if (mounted) setState(() => _busy = false);
  }

  bool _isRepeat(String raw) =>
      raw == _lastRaw &&
      _lastAt != null &&
      clock.now().difference(_lastAt!) < _repeatDelay;

  Future<void> _pair(String code) async {
    setState(() => _waiting = true);
    final scanned = await _api.scan(code);
    final pairing = scanned.data;
    if (!mounted) return;
    setState(() => _waiting = false);
    if (!scanned.success || pairing == null) {
      setState(() => _message = _scanProblem(scanned));
      return;
    }
    final approved = await confirmPairing(context, pairing);
    if (!mounted) return;
    if (!approved) {
      await _api.deny(pairing.id);
      return;
    }
    setState(() => _waiting = true);
    final result = await _api.approve(pairing.id);
    if (!mounted) return;
    setState(() => _waiting = false);
    if (result.success) {
      context.pop(true);
    } else {
      setState(() => _message = _approveProblem(result));
    }
  }

  static String _scanProblem(ApiResponse<Object?> response) =>
      switch (response.error) {
        WebSessionsError.pairingNotFound =>
          'Ce code a expiré. Affichez un nouveau code sur l\'ordinateur.',
        WebSessionsError.rateLimited =>
          'Trop de tentatives. Patientez un instant avant de réessayer.',
        _ => _connectionProblem(response),
      };

  static String _approveProblem(
    ApiResponse<Object?> response,
  ) => switch (response.error) {
    WebSessionsError.pairingNotFound || WebSessionsError.pairingNotPending =>
      'Cette demande n\'est plus valide. Affichez un nouveau code sur l\'ordinateur.',
    _ => _connectionProblem(response),
  };

  static String _connectionProblem(ApiResponse<Object?> response) =>
      response.errorKind == ApiErrorKind.network ||
          response.errorKind == ApiErrorKind.timeout
      ? 'Connexion impossible. Vérifiez votre réseau, puis réessayez.'
      : 'Une erreur est survenue. Réessayez dans un instant.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: 'Caméra de lecture du QR code',
            child: ref.watch(qrScannerBuilderProvider)(context, _onCode),
          ),
          const IgnorePointer(child: Center(child: _Frame())),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Fermer',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                const Spacer(),
                _Instructions(message: _message, busy: _waiting),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tekheletLight, width: 3),
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.message, required this.busy});

  final String? message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Text(
            'Scannez le QR code affiché sur app.mazl.app',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (busy) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.white),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
