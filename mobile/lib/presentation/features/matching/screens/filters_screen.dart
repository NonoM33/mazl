import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';

/// Advanced filters for discovery (Premium feature)
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Filter values
  RangeValues _ageRange = const RangeValues(18, 45);
  double _distanceMax = 50;
  String? _selectedDenomination;
  Set<String> _selectedObservances = {};
  String? _selectedEducation;
  RangeValues? _heightRange;
  bool _onlyVerified = false;
  bool _onlyWithPhoto = true;
  bool _onlyOnline = false;

  // Options
  final List<String> _denominations = [
    'Toutes',
    'Orthodoxe',
    'Massorti',
    'Libéral',
    'Traditionaliste',
    'Loubavitch',
    'Séfarade',
    'Ashkénaze',
  ];

  final List<String> _observances = [
    'Shomer Shabbat',
    'Casher',
    'Casher strict',
    'Prière quotidienne',
    'Mikvé',
    'Tsniout',
  ];

  final List<String> _educations = [
    'Tous',
    'Lycée',
    'Bac',
    'Licence',
    'Master',
    'Doctorat',
    'Yeshiva/Sem',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  Future<void> _loadCurrentFilters() async {
    // Load saved filters from API or local storage
    final response = await _apiService.getCurrentUser();
    if (response.success && response.data?.profile != null) {
      final profile = response.data!.profile!;
      setState(() {
        _ageRange = RangeValues(
          (profile.ageMin ?? 18).toDouble(),
          (profile.ageMax ?? 45).toDouble(),
        );
        _distanceMax = (profile.distanceMax ?? 50).toDouble();
      });
    }
  }

  Future<void> _saveFilters() async {
    setState(() => _isLoading = true);

    final data = {
      'ageMin': _ageRange.start.round(),
      'ageMax': _ageRange.end.round(),
      'distanceMax': _distanceMax.round(),
      if (_selectedDenomination != null && _selectedDenomination != 'Toutes')
        'denomination': _selectedDenomination,
      if (_selectedObservances.isNotEmpty)
        'observances': _selectedObservances.toList(),
      if (_selectedEducation != null && _selectedEducation != 'Tous')
        'education': _selectedEducation,
      if (_heightRange != null)
        'heightMin': _heightRange!.start.round(),
      if (_heightRange != null)
        'heightMax': _heightRange!.end.round(),
      'onlyVerified': _onlyVerified,
      'onlyWithPhoto': _onlyWithPhoto,
      'onlyOnline': _onlyOnline,
    };

    final response = await _apiService.updateProfile(data);

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      _hasChanges = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtres enregistrés'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 45);
      _distanceMax = 50;
      _selectedDenomination = null;
      _selectedObservances = {};
      _selectedEducation = null;
      _heightRange = null;
      _onlyVerified = false;
      _onlyWithPhoto = true;
      _onlyOnline = false;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = PremiumGate.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Age range
              _FilterSection(
                title: 'Tranche d\'âge',
                icon: LucideIcons.users,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_ageRange.start.round()} ans',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_ageRange.end.round()} ans',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 70,
                      divisions: 52,
                      activeColor: AppColors.primary,
                      onChanged: (values) {
                        setState(() {
                          _ageRange = values;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Distance
              _FilterSection(
                title: 'Distance maximale',
                icon: LucideIcons.mapPin,
                child: Column(
                  children: [
                    Text(
                      '${_distanceMax.round()} km',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Slider(
                      value: _distanceMax,
                      min: 5,
                      max: 200,
                      divisions: 39,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _distanceMax = value;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Denomination (Premium)
              _FilterSection(
                title: 'Courant religieux',
                icon: LucideIcons.star,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _denominations.map((denom) {
                    final isSelected = _selectedDenomination == denom ||
                        (_selectedDenomination == null && denom == 'Toutes');
                    return FilterChip(
                      label: Text(denom),
                      selected: isSelected,
                      onSelected: isPremium
                          ? (selected) {
                              setState(() {
                                _selectedDenomination = selected ? denom : null;
                                _hasChanges = true;
                              });
                            }
                          : null,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              // Observances (Premium)
              _FilterSection(
                title: 'Pratiques religieuses',
                icon: LucideIcons.heart,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _observances.map((obs) {
                    final isSelected = _selectedObservances.contains(obs);
                    return FilterChip(
                      label: Text(obs),
                      selected: isSelected,
                      onSelected: isPremium
                          ? (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedObservances.add(obs);
                                } else {
                                  _selectedObservances.remove(obs);
                                }
                                _hasChanges = true;
                              });
                            }
                          : null,
                      selectedColor: AppColors.secondary.withOpacity(0.2),
                      checkmarkColor: AppColors.secondary,
                    );
                  }).toList(),
                ),
              ),

              // Education (Premium)
              _FilterSection(
                title: 'Niveau d\'études',
                icon: LucideIcons.graduationCap,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _educations.map((edu) {
                    final isSelected = _selectedEducation == edu ||
                        (_selectedEducation == null && edu == 'Tous');
                    return FilterChip(
                      label: Text(edu),
                      selected: isSelected,
                      onSelected: isPremium
                          ? (selected) {
                              setState(() {
                                _selectedEducation = selected ? edu : null;
                                _hasChanges = true;
                              });
                            }
                          : null,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              // Height (Premium)
              _FilterSection(
                title: 'Taille',
                icon: LucideIcons.ruler,
                isPremium: !isPremium,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _heightRange != null
                              ? '${_heightRange!.start.round()} cm'
                              : 'Min',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _heightRange != null
                              ? '${_heightRange!.end.round()} cm'
                              : 'Max',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _heightRange ?? const RangeValues(150, 200),
                      min: 140,
                      max: 210,
                      divisions: 70,
                      activeColor: AppColors.primary,
                      onChanged: isPremium
                          ? (values) {
                              setState(() {
                                _heightRange = values;
                                _hasChanges = true;
                              });
                            }
                          : null,
                    ),
                    if (_heightRange != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _heightRange = null;
                            _hasChanges = true;
                          });
                        },
                        child: const Text('Effacer le filtre taille'),
                      ),
                  ],
                ),
              ),

              // Verification
              _FilterSection(
                title: 'Options',
                icon: LucideIcons.settings,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Profils vérifiés uniquement'),
                      subtitle: const Text('Voir seulement les profils vérifiés'),
                      value: _onlyVerified,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _onlyVerified = value;
                          _hasChanges = true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Avec photo uniquement'),
                      subtitle: const Text('Exclure les profils sans photo'),
                      value: _onlyWithPhoto,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _onlyWithPhoto = value;
                          _hasChanges = true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('En ligne maintenant'),
                      subtitle: const Text('Voir les utilisateurs actifs'),
                      value: _onlyOnline,
                      activeColor: AppColors.primary,
                      onChanged: isPremium
                          ? (value) {
                              setState(() {
                                _onlyOnline = value;
                                _hasChanges = true;
                              });
                            }
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // Upgrade banner for free users
              if (!isPremium) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.crown, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Débloquer tous les filtres',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Passe à Mazl Pro pour des recherches précises',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await PremiumGate.checkAccess(
                            context,
                            PremiumFeature.advancedFilters,
                          );
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accentGold,
                        ),
                        child: const Text('Voir'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100), // Space for FAB
            ],
          ),

          // Save button
          if (_hasChanges)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Appliquer les filtres',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
    this.isPremium = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPremium) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        LucideIcons.crown,
                        size: 12,
                        color: AppColors.accentGold,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: isPremium ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: isPremium,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
