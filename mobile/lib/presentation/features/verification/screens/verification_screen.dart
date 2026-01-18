import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Gesture data for verification
class VerificationGesture {
  final String id;
  final String instruction;
  final IconData icon;
  final String emoji;

  const VerificationGesture({
    required this.id,
    required this.instruction,
    required this.icon,
    required this.emoji,
  });

  static const List<VerificationGesture> gestures = [
    VerificationGesture(
      id: 'hand_up',
      instruction: 'Levez votre main droite',
      icon: LucideIcons.hand,
      emoji: '✋',
    ),
    VerificationGesture(
      id: 'smile',
      instruction: 'Souriez naturellement',
      icon: LucideIcons.smile,
      emoji: '😊',
    ),
    VerificationGesture(
      id: 'thumbs_up',
      instruction: 'Faites un pouce en l\'air',
      icon: LucideIcons.thumbsUp,
      emoji: '👍',
    ),
    VerificationGesture(
      id: 'peace',
      instruction: 'Faites le signe de paix',
      icon: LucideIcons.hand,
      emoji: '✌️',
    ),
  ];

  static VerificationGesture getById(String id) {
    return gestures.firstWhere(
      (g) => g.id == id,
      orElse: () => gestures.first,
    );
  }
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isVerified = false;
  int _attemptsToday = 0;
  DateTime? _nextAttemptTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getVerificationStatus();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _isVerified = result.data!['is_verified'] == true;
          _attemptsToday = result.data!['attempts_today'] ?? 0;
          if (result.data!['next_attempt_time'] != null) {
            _nextAttemptTime = DateTime.tryParse(result.data!['next_attempt_time']);
          }
        } else {
          _error = result.error;
        }
      });
    }
  }

  bool get _canAttemptVerification {
    if (_isVerified) return false;
    if (_attemptsToday >= 3) {
      if (_nextAttemptTime != null && DateTime.now().isBefore(_nextAttemptTime!)) {
        return false;
      }
    }
    return true;
  }

  String get _attemptButtonText {
    if (_isVerified) return 'Verifie';
    if (!_canAttemptVerification) {
      if (_nextAttemptTime != null) {
        final diff = _nextAttemptTime!.difference(DateTime.now());
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return 'Reessayer dans ${hours}h${minutes.toString().padLeft(2, '0')}';
      }
      return 'Limite atteinte (3/jour)';
    }
    return 'Verifier (${3 - _attemptsToday} essais restants)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _isVerified ? AppColors.success : AppColors.primary,
                        (_isVerified ? AppColors.success : AppColors.primary).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isVerified ? LucideIcons.badgeCheck : LucideIcons.shieldCheck,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isVerified ? 'Profil verifie !' : 'Fais-toi verifier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isVerified
                            ? 'Ton profil inspire confiance aux autres membres'
                            : 'Les profils verifies recoivent 3x plus de matchs !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Verification levels
                const Text(
                  'Niveaux de verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _VerificationLevel(
                  level: 'Email',
                  description: 'Verifie ton adresse email',
                  icon: LucideIcons.mail,
                  isCompleted: true,
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                _VerificationLevel(
                  level: 'Photo',
                  description: 'Prends un selfie pour prouver que c\'est bien toi',
                  icon: LucideIcons.camera,
                  isCompleted: _isVerified,
                  badge: _isVerified
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Verifie',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _canAttemptVerification
                              ? () => _startPhotoVerification(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                            backgroundColor: _canAttemptVerification ? AppColors.primary : Colors.grey,
                          ),
                          child: Text(
                            _attemptButtonText,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                ),
                _VerificationLevel(
                  level: 'Telephone',
                  description: 'Verifie ton numero de telephone',
                  icon: LucideIcons.phone,
                  isCompleted: false,
                  badge: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bientot disponible'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 36),
                    ),
                    child: const Text('Bientot'),
                  ),
                ),

                const SizedBox(height: 24),

                // Benefits
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.star, color: AppColors.accentGold),
                            SizedBox(width: 8),
                            Text(
                              'Avantages du badge verifie',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: LucideIcons.eye,
                          text: 'Plus de visibilite dans les recherches',
                        ),
                        _BenefitRow(
                          icon: LucideIcons.heart,
                          text: '3x plus de chances de matcher',
                        ),
                        _BenefitRow(
                          icon: LucideIcons.shield,
                          text: 'Inspire confiance aux autres membres',
                        ),
                        _BenefitRow(
                          icon: LucideIcons.badgeCheck,
                          text: 'Badge visible sur ton profil',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.lock, color: AppColors.info),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ton selfie de verification est securise et ne sera jamais partage ni ajoute a ton profil.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _startPhotoVerification(BuildContext context) async {
    // Start verification to get random gesture
    final startResult = await _apiService.startVerification();

    if (!mounted) return;

    if (!startResult.success || startResult.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(startResult.error ?? 'Erreur lors du demarrage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gestureId = startResult.data!['gesture_id'] as String? ?? 'smile';
    final gesture = VerificationGesture.getById(gestureId);

    // Show verification dialog with gesture
    _showPhotoVerificationDialog(context, gesture);
  }

  void _showPhotoVerificationDialog(BuildContext context, VerificationGesture gesture) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PhotoVerificationSheet(
        gesture: gesture,
        onTakeSelfie: () => _takeSelfieAndSubmit(context, gesture),
      ),
    );
  }

  Future<void> _takeSelfieAndSubmit(BuildContext context, VerificationGesture gesture) async {
    Navigator.pop(context); // Close bottom sheet

    // Open camera
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo annulee'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _VerificationLoadingDialog(),
      );
    }

    // Convert image to base64
    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Submit for verification
    final result = await _apiService.submitVerification(base64Image, gesture.id);

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (result.success && result.data != null) {
      final success = result.data!['verified'] == true;
      final message = result.data!['message'] as String?;

      if (success) {
        // Show success dialog
        _showSuccessDialog(context);
        setState(() {
          _isVerified = true;
        });
      } else {
        // Show failure with remaining attempts
        final attemptsRemaining = result.data!['attempts_remaining'] as int? ?? 0;
        _showFailureDialog(context, message ?? 'Verification echouee', attemptsRemaining);
        setState(() {
          _attemptsToday++;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Erreur lors de la verification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.badgeCheck,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification reussie !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ton profil affiche maintenant le badge verifie. Les autres membres peuvent te faire confiance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Super !'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog(BuildContext context, String message, int attemptsRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification echouee',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            if (attemptsRemaining > 0)
              Text(
                '$attemptsRemaining essai${attemptsRemaining > 1 ? 's' : ''} restant${attemptsRemaining > 1 ? 's' : ''} aujourd\'hui',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              )
            else
              Text(
                'Reessayez demain',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoVerificationSheet extends StatelessWidget {
  const _PhotoVerificationSheet({
    required this.gesture,
    required this.onTakeSelfie,
  });

  final VerificationGesture gesture;
  final VoidCallback onTakeSelfie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            LucideIcons.camera,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Verification photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prends un selfie en realisant le geste ci-dessous',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Gesture instruction card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  gesture.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  gesture.instruction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _TipRow(icon: LucideIcons.sun, text: 'Bonne luminosite'),
                _TipRow(icon: LucideIcons.user, text: 'Visage bien visible'),
                _TipRow(icon: LucideIcons.hand, text: 'Geste clair et visible'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTakeSelfie,
            icon: const Icon(LucideIcons.camera),
            label: const Text('Prendre le selfie'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _VerificationLoadingDialog extends StatelessWidget {
  const _VerificationLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Verification en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyse de ton selfie',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationLevel extends StatelessWidget {
  const _VerificationLevel({
    required this.level,
    required this.description,
    required this.icon,
    required this.isCompleted,
    required this.badge,
  });

  final String level;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isCompleted ? AppColors.success : AppColors.primary,
          ),
        ),
        title: Text(
          level,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: badge,
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
