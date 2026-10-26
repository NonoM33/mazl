import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/layout/fold_spread.dart';
import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/duo_tutorial/duo_tutorial_policy.dart';
import '../../../../core/layout/fold_state.dart';
import '../../../../core/links/public_links.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../premium/widgets/plus_settings_card.dart';
import 'blocked_users_screen.dart';
import '../../../common/l10n/open_public_link.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../../../../core/l10n/app_language_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../l10n/delete_account_reason.dart';
import '../widgets/language_picker_sheet.dart';
import '../../couple/l10n/couple_failure_label.dart';
import '../widgets/settings_couple_card.dart';
import 'package:mazl/core/layout/column_app_bar.dart';

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
  final CoupleService _coupleService = CoupleService();

  // Settings values
  String? _location;
  double? _latitude;
  double? _longitude;
  int _distanceMax = 50;
  int _ageMin = 18;
  String? _lookingFor; // 'male' | 'female', as the server stores it
  int _ageMax = 99;

  /// « 1.0.0 (12) » : the version and the build of the installed app.
  String? _appVersion;

  // Places service for city autocomplete
  final PlacesService _placesService = PlacesService();

  @override
  void initState() {
    super.initState();
    _coupleService.addListener(_onCoupleChanged);
    _loadUserProfile();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  @override
  void dispose() {
    _coupleService.removeListener(_onCoupleChanged);
    super.dispose();
  }

  void _onCoupleChanged() {
    if (mounted) setState(() {});
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
        _lookingFor = profile?.lookingFor;
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
      if (_lookingFor != null) 'lookingFor': _lookingFor,
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
        SnackBar(
          content: Text(context.l10n.settingsSaved),
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

    showMazlSheet(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  context.l10n.settingsLocation,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Current location display
              if (_location != null && selectedCity == null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _location!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        LucideIcons.check,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              // Selected city display
              if (selectedCity != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: AppColors.success,
                      ),
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
                        child: Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                    hintText: context.l10n.settingsCitySearchHint,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
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
                  context.l10n.settingsCitySearchHelp,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              // Suggestions list
              if (suggestions.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        leading: Icon(
                          LucideIcons.mapPin,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
                selectedCity != null
                    ? context.l10n.commonSave
                    : context.l10n.commonClose,
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
    );
  }

  void _showDistanceSheet() {
    double tempDistance = _distanceMax.toDouble();
    showMazlSheet(
      context,
      padded: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.settingsMaxDistance,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.l10n.settingsDistanceKm(tempDistance.round()),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
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
            _buildSheetButton(context.l10n.commonSave, () {
              setState(() => _distanceMax = tempDistance.round());
              Navigator.pop(context);
              _saveSettings();
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _lookingForLabel(AppLocalizations l10n) => switch (_lookingFor) {
    'male' => l10n.profileAMan,
    'female' => l10n.profileAWoman,
    _ => '—',
  };

  /// Who Discover proposes: chosen at sign-up, changed here.
  void _showLookingForSheet() {
    showMazlSheet(
      context,
      padded: false,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              sheetContext.l10n.profileILookFor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          for (final (value, label) in [
            ('female', sheetContext.l10n.profileAWoman),
            ('male', sheetContext.l10n.profileAMan),
          ])
            ListTile(
              key: ValueKey('looking-for-$value'),
              minVerticalPadding: 14,
              title: Text(label),
              trailing: _lookingFor == value
                  ? Icon(
                      LucideIcons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() => _lookingFor = value);
                Navigator.pop(sheetContext);
                _saveSettings();
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAgeRangeSheet() {
    RangeValues tempRange = RangeValues(_ageMin.toDouble(), _ageMax.toDouble());
    showMazlSheet(
      context,
      padded: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.settingsAgeRange,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.l10n.settingsAgeRangeValue(
                          tempRange.start.round(),
                          tempRange.end.round(),
                        ),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
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
            _buildSheetButton(context.l10n.commonSave, () {
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
    );
  }

  void _showLanguageSheet() {
    showMazlSheet(
      context,
      padded: false,
      builder: (sheetContext) =>
          LanguagePickerSheet(onChosen: () => Navigator.of(sheetContext).pop()),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> _handleOpenSubscription() async {
    final isPremium = SubscriptionService().isMazlPro;
    await context.push<bool>(
      isPremium ? RoutePaths.subscription : RoutePaths.premium,
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final result = await SubscriptionService().restore();
      if (mounted) {
        final message = switch (result) {
          RestoreFound() => context.l10n.settingsRestoreSuccess,
          RestoreNothing() => context.l10n.settingsRestoreNothing,
          // The store's own wording is a diagnostic, not for the screen.
          RestoreFailed() => context.l10n.settingsRestoreError,
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final l10n = context.l10n;
    final confirmed = await _showConfirmSheet(
      title: l10n.settingsLogOut,
      message: l10n.settingsLogOutMessage,
      confirmText: l10n.settingsLogOut,
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
    final result = await authService.deleteAccount(reason: reason.apiValue);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.go(RoutePaths.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.settingsDeleteError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<DeleteAccountReason?> _showDeleteReasonSheet() {
    DeleteAccountReason? selectedReason;
    const reasons = DeleteAccountReason.values;

    return showMazlSheet<DeleteAccountReason>(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.userX,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.settingsDeleteAccount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.l10n.settingsDeleteReasonPrompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                        onTap: () =>
                            setSheetState(() => selectedReason = reason),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.error.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.1),
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
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(reason.label(context.l10n))),
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
                        child: Text(context.l10n.commonCancel),
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
                        child: Text(context.l10n.commonContinue),
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

  Future<bool?> _showDeleteConfirmationSheet(DeleteAccountReason reason) {
    return showMazlSheet<bool>(
      context,
      padded: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.alertTriangle,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.settingsDeleteFinalTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  context.l10n.settingsDeleteIrreversible,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.settingsDeleteDataList,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
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
                    child: Text(context.l10n.settingsDeleteKeep),
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
                    child: Text(context.l10n.commonDelete),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleDeactivateCoupleMode() async {
    final l10n = context.l10n;
    final confirmed = await _showConfirmSheet(
      title: l10n.settingsCoupleLeave,
      message: l10n.settingsCoupleLeaveMessage,
      confirmText: l10n.settingsCoupleLeaveConfirm,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    // The server answers first: on failure nothing changes. On success the
    // router guard brings the member back to the dating screens.
    final messenger = ScaffoldMessenger.of(context);
    final result = await _coupleService.leaveCouple();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? l10n.settingsCoupleLeft
              : result.failure?.label(l10n) ?? l10n.settingsCoupleLeaveError,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<bool?> _showConfirmSheet({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) {
    return showMazlSheet<bool>(
      context,
      padded: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDestructive ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDestructive ? LucideIcons.alertTriangle : LucideIcons.logOut,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? Theme.of(context).colorScheme.error
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
    );
  }

  Widget _buildCoupleModeCard(BuildContext context) {
    return SettingsCoupleCard(
      service: _coupleService,
      onOpenSpace: () => context.push(RoutePaths.coupleActivities),
      onOpenCalendar: () => context.push(RoutePaths.jewishCalendar),
      onActivate: () => context.push(RoutePaths.coupleSetup),
      onLeave: _handleDeactivateCoupleMode,
      onCancelRequest: _handleCancelCoupleRequest,
    );
  }

  Future<void> _handleCancelCoupleRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await _coupleService.cancelCoupleRequest();
    if (!result.ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.failure?.label(l10n) ??
                l10n.settingsCoupleCancelRequestError,
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  // ============ DEBUG METHODS ============

  /// Runs a /api/dev/couple/* call and reports what really happened: a refused
  /// call (503 outside dev, no success flag) is an error, never a green message.
  Future<void> _debugCoupleCall(String route, String fallbackMessage) async {
    setState(() => _isLoading = true);

    try {
      final userId = _userProfile?.id ?? 22; // Default to user 22 if not loaded
      final response = await _apiService.post(route, {'userId': userId});
      final succeeded = response['success'] == true;

      if (succeeded) {
        // Align on the server; the router guard moves to the right mode.
        await CoupleService().refresh();
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = succeeded
          ? (response['message'] as String? ?? fallbackMessage)
          : (response['error'] as String? ?? 'Refusé par le serveur');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: succeeded ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settingsRestoreError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _debugEnableCoupleMode() =>
      _debugCoupleCall('/api/dev/couple/enable', 'Mode couple activé');

  Future<void> _debugDisableCoupleMode() =>
      _debugCoupleCall('/api/dev/couple/disable', 'Mode couple désactivé');

  Future<void> _debugResetSwipes() async {
    setState(() => _isLoading = true);

    try {
      final email = _userProfile?.email ?? 'renaudlemagicien@gmail.com';
      final response = await _apiService.get('/api/dev/reset-swipes/$email');

      if (mounted) {
        setState(() => _isLoading = false);
        final message = response['message'] ?? 'Swipes reset';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _debugShowCoupleStatus() async {
    setState(() => _isLoading = true);

    try {
      final userId = _userProfile?.id ?? 22;
      final response = await _apiService.get('/api/dev/couple/status/$userId');

      if (mounted) {
        setState(() => _isLoading = false);

        final activeCouple = response['activeCouple'];
        final allCouples = response['allCouples'] as List? ?? [];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Status Couple (Debug)'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'User ID: $userId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mode couple actif: ${activeCouple != null ? "OUI" : "NON"}',
                  ),
                  if (activeCouple != null) ...[
                    const SizedBox(height: 8),
                    Text('Partner: ${activeCouple['partner_name']}'),
                    Text('Couple ID: ${activeCouple['id']}'),
                    Text('Status: ${activeCouple['status']}'),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Historique (${allCouples.length} couples):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...allCouples.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '- ID ${c['id']}: ${c['status']} (partner: ${c['partner_name']})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscriptions = SubscriptionService();
    final isMazlPro = subscriptions.isMazlPro;
    final renewal = subscriptions.expirationDate;
    final subscriptionDetail = [
      if (subscriptions.activePlanMonths case final months?)
        l10n.plusMonths(months),
      if (renewal != null)
        if (subscriptions.willRenew)
          l10n.settingsSubscriptionRenewsOn(renewal.toLocal())
        else
          l10n.settingsSubscriptionEndsOn(renewal.toLocal()),
    ].join(' · ');
    final currentUser = ref.watch(currentUserProvider);
    final inCouple = _coupleService.isCoupleModeEnabled;

    final userEmail =
        _userProfile?.email ?? currentUser?.email ?? l10n.settingsNotSignedIn;
    final userName =
        _userProfile?.name ??
        currentUser?.displayName ??
        l10n.settingsDefaultUserName;
    final userPicture = _userProfile?.picture ?? currentUser?.photoUrl;

    return Scaffold(
      appBar: ColumnAppBar(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            icon: const DirectionalIcon(LucideIcons.arrowLeft),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/profile');
              }
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // Held like a book: the account, discovery and Jewish settings on the
          // page where the reading starts, the rest on the other.
          FoldSpread(
            // Each page ends above the home indicator.
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            start: [
              // User header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: userPicture != null
                          ? CachedNetworkImageProvider(userPicture)
                          : null,
                      child: userPicture == null
                          ? Icon(
                              LucideIcons.user,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Account section
              _SectionHeader(title: l10n.settingsSectionAccount),
              _SettingTile(
                icon: LucideIcons.userCircle,
                title: l10n.settingsEditProfile,
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              _SettingTile(
                icon: LucideIcons.mail,
                title: l10n.settingsEmail,
                subtitle: userEmail,
                showChevron: false,
              ),
              _SettingTile(
                icon: LucideIcons.languages,
                title: l10n.settingsLanguage,
                subtitle:
                    ref.watch(appLanguageProvider)?.autonym ??
                    l10n.settingsLanguageSystem,
                onTap: _showLanguageSheet,
              ),

              // Discovery section (meaningless once the member is in a couple)
              if (!inCouple) ...[
                _SectionHeader(title: l10n.settingsSectionDiscovery),
                _SettingTile(
                  icon: LucideIcons.mapPin,
                  title: l10n.settingsLocation,
                  subtitle: _location ?? l10n.settingsLocationNotSet,
                  onTap: _showLocationSheet,
                ),
                _SettingTile(
                  icon: LucideIcons.heart,
                  title: l10n.profileILookFor,
                  subtitle: _lookingForLabel(l10n),
                  onTap: _showLookingForSheet,
                ),
                _SettingTile(
                  icon: LucideIcons.radar,
                  title: l10n.settingsMaxDistance,
                  subtitle: l10n.settingsDistanceKm(_distanceMax),
                  onTap: _showDistanceSheet,
                ),
                _SettingTile(
                  icon: LucideIcons.users,
                  title: l10n.settingsAgeRange,
                  subtitle: l10n.settingsAgeRangeValue(_ageMin, _ageMax),
                  onTap: _showAgeRangeSheet,
                ),
              ],

              // Jewish settings
              _SectionHeader(title: l10n.settingsSectionJewish),
              _SettingTile(
                icon: LucideIcons.moonStar,
                iconColor: AppColors.accentGold,
                title: l10n.settingsShabbatMode,
                subtitle: l10n.settingsShabbatAutoPause,
                onTap: () => context.push(RoutePaths.shabbatMode),
              ),
            ],
            end: [
              // Couple Mode Section
              _SectionHeader(title: l10n.settingsSectionCouple),
              _buildCoupleModeCard(context),

              // Premium / Subscription
              _SectionHeader(title: l10n.settingsSectionSubscription),
              PlusSettingsCard(
                isPremium: isMazlPro,
                detail: subscriptionDetail,
                onTap: _handleOpenSubscription,
              ),
              _SettingTile(
                icon: LucideIcons.refreshCw,
                title: l10n.settingsRestorePurchases,
                onTap: _handleRestorePurchases,
              ),

              // Privacy & Safety
              _SectionHeader(title: l10n.settingsSectionPrivacy),
              _SettingTile(
                icon: LucideIcons.ban,
                title: l10n.settingsBlockedUsers,
                subtitle: l10n.settingsBlockedUsersHint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                ),
              ),
              _SettingTile(
                icon: LucideIcons.shieldCheck,
                title: l10n.settingsProfileVerification,
                subtitle: _userProfile?.profile?.isVerified == true
                    ? l10n.settingsVerified
                    : l10n.settingsNotVerified,
                onTap: () => context.push(RoutePaths.verification),
              ),
              Consumer(
                builder: (context, ref, _) => _SettingTile(
                  icon: LucideIcons.heartHandshake,
                  title: context.l10n.privacySettingsTitle,
                  subtitle: switch (ref
                      .watch(religiousDataConsentProvider)
                      .valueOrNull
                      ?.data
                      ?.isValid) {
                    true => context.l10n.privacySettingsGrantedShort,
                    false => context.l10n.privacySettingsDeniedShort,
                    null => null,
                  },
                  onTap: () => context.push(RoutePaths.religiousData),
                ),
              ),
              Consumer(
                builder: (context, ref, _) => _SettingTile(
                  icon: LucideIcons.activity,
                  title: context.l10n.analyticsSettingsTitle,
                  subtitle: switch (ref
                      .watch(analyticsConsentProvider)
                      .valueOrNull
                      ?.data
                      ?.isValid) {
                    true => context.l10n.analyticsSettingsGrantedShort,
                    false => context.l10n.analyticsSettingsDeniedShort,
                    null => null,
                  },
                  onTap: () => context.push(RoutePaths.analyticsSettings),
                ),
              ),
              _SettingTile(
                icon: LucideIcons.monitor,
                title: context.l10n.webSessionsTitle,
                onTap: () => context.push(RoutePaths.computers),
              ),

              // About
              _SectionHeader(title: l10n.settingsSectionAbout),
              if (showDuoTutorialInSettings(FoldScope.of(context)))
                _SettingTile(
                  icon: LucideIcons.smartphone,
                  title: l10n.duoTutorialSettingsTitle,
                  subtitle: l10n.duoTutorialSettingsSubtitle,
                  onTap: () => context.push(duoTutorialLocation()),
                ),
              _SettingTile(
                icon: LucideIcons.helpCircle,
                title: l10n.settingsHelp,
                onTap: () => openPublicLink(context, ref, PublicLinks.help),
              ),
              _SettingTile(
                icon: LucideIcons.fileText,
                title: l10n.settingsTerms,
                onTap: () => openPublicLink(context, ref, PublicLinks.terms),
              ),
              _SettingTile(
                icon: LucideIcons.receipt,
                title: l10n.settingsSales,
                onTap: () => openPublicLink(context, ref, PublicLinks.sales),
              ),
              _SettingTile(
                icon: LucideIcons.shield,
                title: l10n.settingsPrivacyPolicy,
                onTap: () => openPublicLink(context, ref, PublicLinks.privacy),
              ),
              _SettingTile(
                icon: LucideIcons.info,
                title: l10n.settingsVersion,
                subtitle: _appVersion,
                showChevron: false,
              ),

              // Debug section (only in debug mode)
              if (kDebugMode) ...[
                _SectionHeader(title: 'Debug (Dev Only)'),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.bug, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Menu Debug',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DebugButton(
                            label: 'Activer Couple',
                            icon: LucideIcons.heart,
                            onPressed: _debugEnableCoupleMode,
                          ),
                          _DebugButton(
                            label: 'Désactiver Couple',
                            icon: LucideIcons.heartOff,
                            onPressed: _debugDisableCoupleMode,
                          ),
                          _DebugButton(
                            label: 'Status Couple',
                            icon: LucideIcons.info,
                            onPressed: _debugShowCoupleStatus,
                          ),
                          _DebugButton(
                            label: 'Reset Swipes',
                            icon: LucideIcons.refreshCw,
                            onPressed: _debugResetSwipes,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Logout & Delete
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: Text(l10n.settingsLogOut),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _handleDeleteAccount,
                  child: Text(
                    l10n.settingsDeleteAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    this.iconColor,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool showChevron;

  /// Null for a row that only informs: it is then not tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: showChevron
          ? const DirectionalIcon(LucideIcons.chevronRight)
          : null,
      onTap: onTap,
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
    );
  }
}
