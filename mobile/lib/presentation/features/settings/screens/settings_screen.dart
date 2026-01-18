import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  UserProfile? _userProfile;
  final ApiService _apiService = ApiService();

  // Settings values
  String? _location;
  double? _latitude;
  double? _longitude;
  int _distanceMax = 50;
  int _ageMin = 18;
  int _ageMax = 99;
  bool _notifMatches = true;
  bool _notifMessages = true;
  bool _notifSuperLikes = true;
  bool _notifHolidays = true;

  // Places service for city autocomplete
  final PlacesService _placesService = PlacesService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final response = await _apiService.getCurrentUser();
    if (response.success && response.data != null && mounted) {
      final profile = response.data!.profile;
      setState(() {
        _userProfile = response.data;
        _location = profile?.location;
        _latitude = profile?.latitude;
        _longitude = profile?.longitude;
        _distanceMax = profile?.distanceMax ?? 50;
        _ageMin = profile?.ageMin ?? 18;
        _ageMax = profile?.ageMax ?? 99;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'location': _location,
      'distanceMax': _distanceMax,
      'ageMin': _ageMin,
      'ageMax': _ageMax,
    };

    // Include coordinates if available
    if (_latitude != null && _longitude != null) {
      data['latitude'] = _latitude;
      data['longitude'] = _longitude;
    }

    final response = await _apiService.updateProfile(data);

    setState(() => _isSaving = false);

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parametres sauvegardes'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showLocationSheet() {
    final controller = TextEditingController();
    List<CitySuggestion> suggestions = [];
    CitySuggestion? selectedCity;
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Localisation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  // Current location display
                  if (_location != null && selectedCity == null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _location!,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(LucideIcons.check, size: 20, color: AppColors.primary),
                        ],
                      ),
                    ),
                  // Selected city display
                  if (selectedCity != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 20, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCity!.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setSheetState(() {
                              selectedCity = null;
                              controller.clear();
                            }),
                            child: Icon(LucideIcons.x, size: 20, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une ville...',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(LucideIcons.search),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) async {
                        if (value.length < 2) {
                          setSheetState(() => suggestions = []);
                          return;
                        }
                        setSheetState(() => isSearching = true);
                        final results = await _placesService.searchCities(value);
                        if (context.mounted) {
                          setSheetState(() {
                            suggestions = results;
                            isSearching = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Hint text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Tape le nom de ta ville et selectionne une suggestion',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  // Suggestions list
                  if (suggestions.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return ListTile(
                            leading: Icon(LucideIcons.mapPin, color: AppColors.primary),
                            title: Text(suggestion.displayName),
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              setSheetState(() {
                                selectedCity = suggestion;
                                suggestions = [];
                                controller.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Save button
                  _buildSheetButton(
                    selectedCity != null ? 'Enregistrer' : 'Fermer',
                    () {
                      if (selectedCity != null) {
                        setState(() {
                          _location = selectedCity!.displayName;
                          _latitude = selectedCity!.latitude;
                          _longitude = selectedCity!.longitude;
                        });
                        Navigator.pop(context);
                        _saveSettings();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDistanceSheet() {
    double tempDistance = _distanceMax.toDouble();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Distance maximale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${tempDistance.round()} km',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Slider(
                    value: tempDistance,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setSheetState(() => tempDistance = value),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSheetButton('Enregistrer', () {
                  setState(() => _distanceMax = tempDistance.round());
                  Navigator.pop(context);
                  _saveSettings();
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAgeRangeSheet() {
    RangeValues tempRange = RangeValues(_ageMin.toDouble(), _ageMax.toDouble());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Tranche d\'age', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${tempRange.start.round()} - ${tempRange.end.round()} ans',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RangeSlider(
                    values: tempRange,
                    min: 18,
                    max: 99,
                    divisions: 81,
                    activeColor: AppColors.primary,
                    onChanged: (values) => setSheetState(() => tempRange = values),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSheetButton('Enregistrer', () {
                  setState(() {
                    _ageMin = tempRange.start.round();
                    _ageMax = tempRange.end.round();
                  });
                  Navigator.pop(context);
                  _saveSettings();
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSheetButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Future<void> _handleShowPaywall() async {
    await context.push<bool>(RoutePaths.premium);
    if (mounted) setState(() {});
  }

  Future<void> _handleShowCustomerCenter() async {
    try {
      await RevenueCatService().showCustomerCenter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    try {
      await RevenueCatService().restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achats restaures avec succes!')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmSheet(
      title: 'Se deconnecter',
      message: 'Es-tu sur de vouloir te deconnecter ?',
      confirmText: 'Se deconnecter',
      isDestructive: false,
    );

    if (confirmed == true && mounted) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) context.go(RoutePaths.login);
    }
  }

  Future<void> _handleDeleteAccount() async {
    // Step 1: Show reason selection
    final reason = await _showDeleteReasonSheet();
    if (reason == null || !mounted) return;

    // Step 2: Show final confirmation
    final confirmed = await _showDeleteConfirmationSheet(reason);
    if (confirmed != true || !mounted) return;

    // Step 3: Delete account
    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.deleteAccount(reason: reason);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.go(RoutePaths.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Erreur lors de la suppression'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String?> _showDeleteReasonSheet() {
    String? selectedReason;
    final reasons = [
      'J\'ai trouvé quelqu\'un',
      'Je n\'utilise plus l\'application',
      'Je souhaite faire une pause',
      'Problèmes techniques',
      'Je ne suis pas satisfait(e) du service',
      'Autre raison',
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 16),
                const Icon(LucideIcons.userX, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Supprimer mon compte',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pourquoi souhaites-tu nous quitter ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reasons.length,
                    itemBuilder: (context, index) {
                      final reason = reasons[index];
                      final isSelected = selectedReason == reason;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedReason = reason),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.error.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.error
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.circle,
                                  color: isSelected
                                      ? AppColors.error
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(reason)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedReason != null
                              ? () => Navigator.pop(context, selectedReason)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Continuer'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationSheet(String reason) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirmation finale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Cette action est irréversible !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toutes tes données seront supprimées :\n• Ton profil et tes photos\n• Tes matchs et conversations\n• Ton historique de likes\n• Tes paramètres',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Garder mon compte'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeactivateCoupleMode() async {
    final confirmed = await _showConfirmSheet(
      title: 'Quitter le mode couple',
      message: 'Tu pourras le reactiver plus tard si tu le souhaites.',
      confirmText: 'Quitter',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      CoupleService().disableCoupleMode();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode couple desactive')),
      );
    }
  }

  Future<bool?> _showConfirmSheet({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructive ? LucideIcons.alertTriangle : LucideIcons.logOut,
                  color: isDestructive ? Colors.red : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? Colors.red : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(confirmText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleModeCard(BuildContext context) {
    final coupleService = CoupleService();
    final isCoupleModeEnabled = coupleService.isCoupleModeEnabled;
    final coupleData = coupleService.coupleData;

    if (isCoupleModeEnabled && coupleData != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.heartHandshake, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode Couple Actif',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Avec ${coupleData.partnerName ?? 'ton/ta partenaire'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${coupleData.daysTogether} jours',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(RoutePaths.coupleDashboard),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Dashboard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(RoutePaths.jewishCalendar),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Calendrier'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleDeactivateCoupleMode,
                  icon: const Icon(LucideIcons.logOut, color: Colors.white70, size: 20),
                  tooltip: 'Quitter le mode couple',
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show activate couple mode card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary.withOpacity(0.1), AppColors.primary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.heartHandshake, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu as trouve l\'amour ?', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Active le mode couple pour des features exclusives',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(RoutePaths.coupleSetup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenueCat = RevenueCatService();
    final isMazlPro = revenueCat.isMazlPro;
    final subscriptionStatus = revenueCat.subscriptionStatusText;
    final currentUser = ref.watch(currentUserProvider);

    final profile = _userProfile?.profile;
    final userEmail = _userProfile?.email ?? currentUser?.email ?? 'Non connecte';
    final userName = _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
    final userPicture = _userProfile?.picture ?? currentUser?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
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
      body: Stack(
        children: [
          ListView(
            children: [
              // User header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: userPicture != null ? CachedNetworkImageProvider(userPicture) : null,
                      child: userPicture == null
                          ? Icon(LucideIcons.user, size: 40, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Account section
              _SectionHeader(title: 'Compte'),
              _SettingTile(
                icon: LucideIcons.userCircle,
                title: 'Modifier le profil',
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              _SettingTile(
                icon: LucideIcons.mail,
                title: 'Email',
                subtitle: userEmail,
                showChevron: false,
                onTap: () {},
              ),

              // Discovery section
              _SectionHeader(title: 'Decouverte'),
              _SettingTile(
                icon: LucideIcons.mapPin,
                title: 'Localisation',
                subtitle: _location ?? 'Non defini',
                onTap: _showLocationSheet,
              ),
              _SettingTile(
                icon: LucideIcons.radar,
                title: 'Distance maximale',
                subtitle: '$_distanceMax km',
                onTap: _showDistanceSheet,
              ),
              _SettingTile(
                icon: LucideIcons.users,
                title: 'Tranche d\'age',
                subtitle: '$_ageMin - $_ageMax ans',
                onTap: _showAgeRangeSheet,
              ),

              // Jewish settings
              _SectionHeader(title: 'Parametres juifs'),
              _SettingTile(
                icon: LucideIcons.moonStar,
                iconColor: AppColors.accentGold,
                title: 'Mode Shabbat',
                subtitle: 'Pause automatique',
                onTap: () => context.push(RoutePaths.shabbatMode),
              ),
              _SettingTile(
                icon: LucideIcons.calendarHeart,
                title: 'Alertes fetes',
                subtitle: 'Notifications avant les fetes',
                trailing: Switch(
                  value: _notifHolidays,
                  onChanged: (value) => setState(() => _notifHolidays = value),
                  activeColor: AppColors.primary,
                ),
                onTap: () => setState(() => _notifHolidays = !_notifHolidays),
              ),

              // Notifications
              _SectionHeader(title: 'Notifications'),
              _SettingTile(
                icon: LucideIcons.heartHandshake,
                title: 'Nouveaux matchs',
                trailing: Switch(
                  value: _notifMatches,
                  onChanged: (value) => setState(() => _notifMatches = value),
                  activeColor: AppColors.primary,
                ),
                onTap: () => setState(() => _notifMatches = !_notifMatches),
              ),
              _SettingTile(
                icon: LucideIcons.messageCircle,
                title: 'Messages',
                trailing: Switch(
                  value: _notifMessages,
                  onChanged: (value) => setState(() => _notifMessages = value),
                  activeColor: AppColors.primary,
                ),
                onTap: () => setState(() => _notifMessages = !_notifMessages),
              ),
              _SettingTile(
                icon: LucideIcons.star,
                title: 'Super Likes',
                trailing: Switch(
                  value: _notifSuperLikes,
                  onChanged: (value) => setState(() => _notifSuperLikes = value),
                  activeColor: AppColors.primary,
                ),
                onTap: () => setState(() => _notifSuperLikes = !_notifSuperLikes),
              ),

              // Couple Mode Section
              _SectionHeader(title: 'Mode Couple'),
              _buildCoupleModeCard(context),

              // Premium / Subscription
              _SectionHeader(title: 'Abonnement'),
              if (isMazlPro) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.premiumGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.crown, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mazl Pro',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(subscriptionStatus, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Actif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleShowCustomerCenter,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text('Gerer mon abonnement'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.premiumGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.crown, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Passe a Mazl Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Likes illimites, voir qui t\'aime, boost', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handleShowPaywall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accentGold,
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('Voir'),
                      ),
                    ],
                  ),
                ),
              ],
              _SettingTile(
                icon: LucideIcons.refreshCw,
                title: 'Restaurer les achats',
                onTap: _handleRestorePurchases,
              ),

              // Privacy & Safety
              _SectionHeader(title: 'Confidentialite & Securite'),
              _SettingTile(
                icon: LucideIcons.ban,
                title: 'Utilisateurs bloques',
                subtitle: 'Gerer les personnes bloquees',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                ),
              ),
              _SettingTile(
                icon: LucideIcons.shieldCheck,
                title: 'Verification du profil',
                subtitle: _userProfile?.profile?.isVerified == true ? 'Verifie' : 'Non verifie',
                onTap: () => context.push(RoutePaths.verification),
              ),

              // About
              _SectionHeader(title: 'A propos'),
              _SettingTile(
                icon: LucideIcons.helpCircle,
                title: 'Aide & Support',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.fileText,
                title: 'Conditions d\'utilisation',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.shield,
                title: 'Politique de confidentialite',
                onTap: () {},
              ),
              _SettingTile(
                icon: LucideIcons.info,
                title: 'Version',
                subtitle: '1.0.0',
                showChevron: false,
                onTap: () {},
              ),

              // Logout & Delete
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Se deconnecter'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _handleDeleteAccount,
                  child: const Text('Supprimer mon compte', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (_isLoading || _isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.showChevron = true,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (showChevron ? const Icon(LucideIcons.chevronRight) : null),
      onTap: onTap,
    );
  }
}
