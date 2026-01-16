import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fais-toi vérifier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les profils vérifiés reçoivent 3x plus de matchs !',
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
            'Niveaux de vérification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _VerificationLevel(
            level: 'Email',
            description: 'Vérifie ton adresse email',
            icon: LucideIcons.mail,
            isCompleted: true,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Complété',
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
            isCompleted: false,
            badge: ElevatedButton(
              onPressed: () {
                _showPhotoVerificationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 36),
              ),
              child: const Text('Vérifier'),
            ),
          ),
          _VerificationLevel(
            level: 'Téléphone',
            description: 'Vérifie ton numéro de téléphone',
            icon: LucideIcons.phone,
            isCompleted: false,
            badge: OutlinedButton(
              onPressed: () {
                // TODO: Phone verification
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 36),
              ),
              child: const Text('Vérifier'),
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
                        'Avantages du badge vérifié',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BenefitRow(
                    icon: LucideIcons.eye,
                    text: 'Plus de visibilité dans les recherches',
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
                    'Tes documents de vérification sont sécurisés et ne seront jamais partagés.',
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

  void _showPhotoVerificationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
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
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérification photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prends un selfie en imitant la pose ci-dessous pour prouver que c\'est bien toi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 60,
                    color: AppColors.primary,
                  ),
                  Text(
                    '✌️',
                    style: TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Open camera
              },
              icon: const Icon(LucideIcons.camera),
              label: const Text('Ouvrir la caméra'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
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
