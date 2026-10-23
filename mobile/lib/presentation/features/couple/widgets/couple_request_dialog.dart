import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/couple_service.dart';

/// Shown to the member who receives a couple request. Accepting hands the rest
/// (celebration, navigation) to the couple flow host, which hears the
/// `CoupleFormed` event.
class CoupleRequestDialog extends StatefulWidget {
  const CoupleRequestDialog({
    super.key,
    required this.request,
    required this.service,
  });

  final CoupleRequest request;
  final CoupleService service;

  static Future<void> show(
    BuildContext context, {
    required CoupleRequest request,
    required CoupleService service,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CoupleRequestDialog(request: request, service: service),
    );
  }

  @override
  State<CoupleRequestDialog> createState() => _CoupleRequestDialogState();
}

class _CoupleRequestDialogState extends State<CoupleRequestDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  String get _name =>
      widget.request.requesterName.isEmpty ? 'Cette personne' : widget.request.requesterName;

  Future<void> _answer({required bool accept}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = accept
        ? await widget.service.acceptCoupleRequest(widget.request)
        : await widget.service.rejectCoupleRequest(widget.request);
    if (!mounted) return;

    if (result.ok) {
      Navigator.of(context).pop();
      return;
    }

    // The request may be gone (cancelled meanwhile): nothing left to answer.
    final stillThere = widget.service.receivedRequest?.id == widget.request.id;
    if (!stillThere) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      messenger?.showSnackBar(SnackBar(content: Text(result.message ?? '')));
      return;
    }
    setState(() {
      _isLoading = false;
      _errorMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picture = widget.request.requesterPicture;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.surfaceContainerHigh,
              backgroundImage: picture != null ? CachedNetworkImageProvider(picture) : null,
              child: picture == null
                  ? Text(_name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '$_name souhaite activer le mode couple avec vous',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.3),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _answer(accept: true),
                  child: const Text('Accepter'),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _answer(accept: false),
                  child: const Text('Non merci'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
