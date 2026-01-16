import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';

class CoupleModeSetupScreen extends StatefulWidget {
  const CoupleModeSetupScreen({super.key});

  @override
  State<CoupleModeSetupScreen> createState() => _CoupleModeSetupScreenState();
}

class _CoupleModeSetupScreenState extends State<CoupleModeSetupScreen> {
  final ApiService _apiService = ApiService();
  final CoupleService _coupleService = CoupleService();

  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedMatch;
  DateTime _relationshipDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final response = await _apiService.getMatches();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _matches = response.data!;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateCoupleMode() async {
    if (_selectedMatch == null) return;

    final profile = _selectedMatch!['profile'] as Map<String, dynamic>?;
    if (profile == null) return;

    await _coupleService.enableCoupleMode(
      partnerId: profile['user_id'] as int,
      partnerName: profile['display_name'] as String? ?? 'Partenaire',
      partnerPicture: profile['picture'] as String?,
      relationshipStartDate: _relationshipDate,
    );

    if (mounted) {
      // Show success and navigate to dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.heart, color: Colors.white),
              SizedBox(width: 12),
              Text('Mode Couple active ! Mazl Tov !'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Navigate back then push dashboard
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context.push('/couple/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Couple'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LucideIcons.heartHandshake,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Felicitations !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu as trouve quelqu\'un de special sur MAZL.\nActive le mode couple pour profiter de fonctionnalites exclusives.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Benefits
                  const Text(
                    'Avantages du mode couple',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefit(
                    icon: LucideIcons.messageCircle,
                    title: 'Questions quotidiennes',
                    description: 'Apprenez a mieux vous connaitre chaque jour',
                  ),
                  _buildBenefit(
                    icon: LucideIcons.trophy,
                    title: 'Milestones de couple',
                    description: 'Celebrez vos etapes importantes ensemble',
                  ),
                  _buildBenefit(
                    icon: LucideIcons.calendarHeart,
                    title: 'Evenements pour couples',
                    description: 'Acces aux events exclusifs de la communaute',
                  ),
                  _buildBenefit(
                    icon: LucideIcons.moonStar,
                    title: 'Calendrier juif partage',
                    description: 'Preparez les fetes et Shabbat ensemble',
                  ),

                  const SizedBox(height: 32),

                  // Select partner
                  const Text(
                    'Selectionne ton/ta partenaire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_matches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.userX,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun match pour l\'instant',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_matches.map((match) {
                      final profile = match['profile'] as Map<String, dynamic>?;
                      if (profile == null) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = _selectedMatch == match;
                      return _buildMatchOption(match, profile, isSelected);
                    })),

                  if (_selectedMatch != null) ...[
                    const SizedBox(height: 24),

                    // Relationship start date
                    const Text(
                      'Depuis quand etes-vous ensemble ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_relationshipDate.day}/${_relationshipDate.month}/${_relationshipDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Activate button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _selectedMatch != null
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            )
                          : null,
                      color: _selectedMatch == null ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: _selectedMatch != null
                          ? [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedMatch != null ? _activateCoupleMode : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Activer le mode couple',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip option
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Plus tard',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchOption(
    Map<String, dynamic> match,
    Map<String, dynamic> profile,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMatch = match);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: profile['picture'] != null
                  ? CachedNetworkImageProvider(profile['picture'])
                  : null,
              child: profile['picture'] == null
                  ? Text(
                      (profile['display_name'] as String? ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['display_name'] as String? ?? 'Inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (profile['location'] != null)
                    Text(
                      profile['location'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _relationshipDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _relationshipDate = date);
    }
  }
}
