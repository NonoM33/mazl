import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/mazel_tov_screen.dart';

/// Dialog shown when user receives a couple mode request
class CoupleRequestDialog extends StatefulWidget {
  const CoupleRequestDialog({
    super.key,
    required this.request,
    required this.onAccepted,
    required this.onRejected,
  });

  final CoupleRequest request;
  final VoidCallback onAccepted;
  final VoidCallback onRejected;

  static Future<void> show(
    BuildContext context,
    CoupleRequest request, {
    required VoidCallback onAccepted,
    required VoidCallback onRejected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CoupleRequestDialog(
        request: request,
        onAccepted: onAccepted,
        onRejected: onRejected,
      ),
    );
  }

  @override
  State<CoupleRequestDialog> createState() => _CoupleRequestDialogState();
}

class _CoupleRequestDialogState extends State<CoupleRequestDialog> {
  final CoupleService _coupleService = CoupleService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _coupleService.acceptCoupleRequest(widget.request);

    if (mounted) {
      if (success) {
        // Archive all other conversations with a goodbye message
        await _coupleService.archiveOtherConversations();

        setState(() => _isLoading = false);
        Navigator.of(context).pop();

        // Show Mazel Tov celebration screen
        if (mounted) {
          await MazelTovScreen.show(
            context,
            partnerName: widget.request.requesterName,
            partnerPicture: widget.request.requesterPicture,
            onContinue: widget.onAccepted,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors de l\'acceptation';
        });
      }
    }
  }

  Future<void> _handleReject() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _coupleService.rejectCoupleRequest(widget.request);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        widget.onRejected();
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du refus';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti/Heart animation would go here
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                LucideIcons.heartHandshake,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Mode Couple',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Requester info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.request.requesterPicture != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(
                      widget.request.requesterPicture!,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      widget.request.requesterName.isNotEmpty
                          ? widget.request.requesterName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  widget.request.requesterName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              '${widget.request.requesterName} souhaite activer le mode couple avec toi !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(LucideIcons.messageCircle, 'Questions quotidiennes'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(LucideIcons.trophy, 'Milestones de couple'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(LucideIcons.calendar, 'Calendrier juif partage'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error message
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],

            // Buttons
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleAccept,
                  icon: const Icon(LucideIcons.heart, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _handleReject,
                child: Text(
                  'Non merci',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
