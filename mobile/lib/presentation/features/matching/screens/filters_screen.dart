import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/filter_options.dart';

/// Advanced filters for discovery (Premium feature)
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Filter values
  RangeValues _ageRange = const RangeValues(18, 45);
  double _distanceMax = 50;
  FilterDenomination? _selectedDenomination;
  Set<FilterObservance> _selectedObservances = {};
  FilterEducation? _selectedEducation;
  RangeValues? _heightRange;
  bool _onlyVerified = false;
  bool _onlyWithPhoto = true;
  bool _onlyOnline = false;

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
      if (_selectedDenomination != null &&
          _selectedDenomination != FilterDenomination.all)
        'denomination': _selectedDenomination!.apiValue,
      if (_selectedObservances.isNotEmpty)
        'observances': _selectedObservances.map((o) => o.apiValue).toList(),
      if (_selectedEducation != null &&
          _selectedEducation != FilterEducation.all)
        'education': _selectedEducation!.apiValue,
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
        SnackBar(
          content: Text(context.l10n.matchingFiltersSaved),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.matchingFiltersSaveFailed),
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
        title: Text(context.l10n.matchingFilters),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(context.l10n.matchingFiltersReset),
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
                title: context.l10n.matchingFiltersAge,
                icon: LucideIcons.users,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.matchingFiltersYears(
                            _ageRange.start.round(),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.l10n.matchingFiltersYears(
                            _ageRange.end.round(),
                          ),
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
                title: context.l10n.matchingFiltersDistance,
                icon: LucideIcons.mapPin,
                child: Column(
                  children: [
                    Text(
                      context.l10n.matchingFiltersKm(_distanceMax.round()),
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
                title: context.l10n.matchingFiltersDenomination,
                icon: LucideIcons.star,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FilterDenomination.values.map((denom) {
                    final isSelected = _selectedDenomination == denom ||
                        (_selectedDenomination == null &&
                            denom == FilterDenomination.all);
                    return FilterChip(
                      label: Text(denom.label(context.l10n)),
                      selected: isSelected,
                      onSelected: isPremium
                          ? (selected) {
                              setState(() {
                                _selectedDenomination = selected ? denom : null;
                                _hasChanges = true;
                              });
                            }
                          : null,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              // Observances (Premium)
              _FilterSection(
                title: context.l10n.matchingFiltersObservances,
                icon: LucideIcons.heart,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FilterObservance.values.map((obs) {
                    final isSelected = _selectedObservances.contains(obs);
                    return FilterChip(
                      label: Text(obs.label(context.l10n)),
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
                      selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.secondary,
                    );
                  }).toList(),
                ),
              ),

              // Education (Premium)
              _FilterSection(
                title: context.l10n.matchingFiltersEducation,
                icon: LucideIcons.graduationCap,
                isPremium: !isPremium,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FilterEducation.values.map((edu) {
                    final isSelected = _selectedEducation == edu ||
                        (_selectedEducation == null &&
                            edu == FilterEducation.all);
                    return FilterChip(
                      label: Text(edu.label(context.l10n)),
                      selected: isSelected,
                      onSelected: isPremium
                          ? (selected) {
                              setState(() {
                                _selectedEducation = selected ? edu : null;
                                _hasChanges = true;
                              });
                            }
                          : null,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              // Height (Premium)
              _FilterSection(
                title: context.l10n.matchingFiltersHeight,
                icon: LucideIcons.ruler,
                isPremium: !isPremium,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _heightRange != null
                              ? context.l10n.matchingFiltersCm(
                                  _heightRange!.start.round(),
                                )
                              : context.l10n.matchingFiltersHeightMin,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _heightRange != null
                              ? context.l10n.matchingFiltersCm(
                                  _heightRange!.end.round(),
                                )
                              : context.l10n.matchingFiltersHeightMax,
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
                        child: Text(context.l10n.matchingFiltersHeightClear),
                      ),
                  ],
                ),
              ),

              // Verification
              _FilterSection(
                title: context.l10n.matchingFiltersOptions,
                icon: LucideIcons.settings,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(context.l10n.matchingFiltersVerifiedTitle),
                      subtitle: Text(context.l10n.matchingFiltersVerifiedHint),
                      value: _onlyVerified,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _onlyVerified = value;
                          _hasChanges = true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.matchingFiltersPhotoTitle),
                      subtitle: Text(context.l10n.matchingFiltersPhotoHint),
                      value: _onlyWithPhoto,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _onlyWithPhoto = value;
                          _hasChanges = true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.matchingFiltersOnlineTitle),
                      subtitle: Text(context.l10n.matchingFiltersOnlineHint),
                      value: _onlyOnline,
                      activeThumbColor: AppColors.primary,
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
                      const Icon(LucideIcons.plus, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.matchingFiltersUpsellTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.l10n.matchingFiltersUpsellBody,
                              style: const TextStyle(
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
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(context.l10n.commonSee),
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
                      : Text(
                          context.l10n.matchingFiltersApply,
                          style: const TextStyle(
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
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        LucideIcons.lock,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'mazl+',
                        style: TextStyle(
                          color: AppColors.primary,
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
              // The list tiles paint their ink here, above the card's colour.
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
