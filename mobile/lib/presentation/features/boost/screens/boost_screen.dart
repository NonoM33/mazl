import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen to manage and activate profile boost
class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  final ApiService _apiService = ApiService();

  BoostStatus? _boostStatus;
  bool _isLoading = true;
  bool _isActivating = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBoostStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoostStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getBoostStatus();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _boostStatus = result.data;
          if (_boostStatus!.isActive) {
            _startTimer();
          }
        } else {
          _error = result.error;
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {}); // Refresh remaining time display
        if (_boostStatus?.minutesRemaining == 0) {
          _timer?.cancel();
          _loadBoostStatus(); // Reload to get final stats
        }
      }
    });
  }

  Future<void> _activateBoost() async {
    setState(() => _isActivating = true);

    final result = await _apiService.activateBoost();

    if (mounted) {
      setState(() => _isActivating = false);

      if (result.success && result.data != null) {
        setState(() {
          _boostStatus = result.data;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boost active ! Ton profil est maintenant en avant.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors de l\'activation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBoostStatus,
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isActive = _boostStatus?.isActive ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        _buildHeaderCard(isActive),

        const SizedBox(height: 24),

        // Stats or benefits
        if (isActive)
          _buildActiveStats()
        else
          _buildBenefits(),

        const SizedBox(height: 24),

        // Action button
        if (!isActive)
          _buildActivateButton(),

        const SizedBox(height: 16),

        // Premium upsell if not premium
        if (_boostStatus?.remainingBoosts != null &&
            _boostStatus!.remainingBoosts! <= 1)
          _buildPremiumUpsell(),
      ],
    );
  }

  Widget _buildHeaderCard(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.success, AppColors.success.withOpacity(0.7)]
              : [const Color(0xFF6C5CE7), const Color(0xFFa29bfe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.success : const Color(0xFF6C5CE7))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated rocket icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? LucideIcons.zap : LucideIcons.rocket,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isActive ? 'Boost Actif !' : 'Boost ton Profil',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (isActive) ...[
            Text(
              '${_boostStatus!.minutesRemaining} min restantes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _boostStatus!.minutesRemaining / 30,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 6,
              ),
            ),
          ] else
            Text(
              'Sois vu par 10x plus de personnes !',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.barChart2, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Pendant ce boost',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.eye,
                    value: '${_boostStatus?.viewsDuringBoost ?? 0}',
                    label: 'Vues',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.heart,
                    value: '${_boostStatus?.likesDuringBoost ?? 0}',
                    label: 'Likes',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avantages du Boost',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _BenefitRow(
              icon: LucideIcons.trendingUp,
              text: 'Apparais en premier dans les suggestions',
              color: Colors.purple,
            ),
            _BenefitRow(
              icon: LucideIcons.eye,
              text: '10x plus de visibilite pendant 30 min',
              color: Colors.blue,
            ),
            _BenefitRow(
              icon: LucideIcons.heart,
              text: 'Plus de chances de matcher',
              color: AppColors.secondary,
            ),
            _BenefitRow(
              icon: LucideIcons.barChart2,
              text: 'Stats en temps reel pendant le boost',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivateButton() {
    final remaining = _boostStatus?.remainingBoosts;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActivating ? null : _activateBoost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isActivating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.rocket, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Activer le Boost',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (remaining != null) ...[
          const SizedBox(height: 8),
          Text(
            '$remaining boost${remaining > 1 ? 's' : ''} restant${remaining > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumUpsell() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.crown, color: AppColors.accentGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boosts illimites',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Passe Premium pour booster sans limite',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.premium),
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
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
