import 'package:flutter/material.dart';

import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart' show ProfilePhoto;
import '../l10n/couple_failure_label.dart';

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
  CoupleActionFailure? _failure;

  String get _name => widget.request.requesterName;

  Future<void> _answer({required bool accept}) async {
    setState(() {
      _isLoading = true;
      _failure = null;
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
      final failure = result.failure;
      if (failure != null) {
        messenger?.showSnackBar(
          SnackBar(content: Text(failure.label(context.l10n))),
        );
      }
      return;
    }
    setState(() {
      _isLoading = false;
      _failure = result.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final picture = widget.request.requesterPicture;
    final hairline =
        Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.hairline;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainer,
                border: Border.all(color: hairline),
              ),
              child: ClipOval(
                child: picture != null && picture.isNotEmpty
                    ? ProfilePhoto(url: picture, seed: widget.request.requesterId, radius: 36)
                    : Center(
                        child: Text(
                          _name.isEmpty
                              ? '?'
                              : _name.characters.first.toUpperCase(),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name.isEmpty
                  ? l10n.coupleSpaceRequestTitleAnonymous
                  : l10n.coupleSpaceRequestTitle(_name),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Text(
                _failure!.label(l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
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
                  child: Text(l10n.coupleSpaceRequestAccept),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _answer(accept: false),
                  child: Text(l10n.coupleSpaceRequestDecline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
