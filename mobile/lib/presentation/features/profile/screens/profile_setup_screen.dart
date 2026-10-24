import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/profile_labels.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/profile_completeness_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../privacy/widgets/religious_data_gate.dart';
import '../l10n/profile_answer_labels.dart';
import 'edit_profile_screen.dart'
    show DenominationStoredValue, KashrutStoredValue, ShabbatStoredValue;

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1 - basic info
  DateTime? _birthDate;
  String? _gender; // 'male' | 'female'

  // Step 3 - Jewish practice
  // The choices are typed; the API gets their stored value (the same ones
  // [EditProfileScreen] writes, so values round-trip between setup and edits).
  Denomination? _denomination;
  Kashrut? _kashrut;
  ShabbatObservance? _shabbat;
  SynagogueVisits? _synagogue;
  // The server ignores the four practice fields without a valid consent.
  bool _religiousConsent = false;

  // Step 4 - preferences
  String? _lookingFor; // 'male' | 'female'
  RangeValues _ageRange = const RangeValues(22, 35);
  double _maxDistance = 50;
  RelationshipIntention? _goal;

  // Photos
  final List<ProfilePhoto> _photos = [];
  bool _isUploadingPhoto = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileSetupStep(_currentStep + 1, _totalSteps)),
        leading: _currentStep > 0
            ? IconButton(
                icon: const DirectionalIcon(LucideIcons.arrowLeft),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.dividerLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildBasicInfoStep(),
                _buildPhotosStep(),
                _buildJewishInfoStep(),
                _buildPreferencesStep(),
              ],
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep < _totalSteps - 1
                            ? context.l10n.profileSetupNext
                            : context.l10n.profileSetupFinish,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ NAVIGATION ============

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _saveProfile();
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        return _fail(context.l10n.profileSetupNameRequired);
      }
      if (_birthDate == null) {
        return _fail(context.l10n.profileSetupBirthdateRequired);
      }
      if (_gender == null) {
        return _fail(context.l10n.profileSetupGenderRequired);
      }
    }
    if (_currentStep == _totalSteps - 1 && _lookingFor == null) {
      return _fail(context.l10n.genreLookingForRequired);
    }
    return true;
  }

  bool _fail(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    return false;
  }

  // ============ ACTIONS ============

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: context.l10n.profileBirthdate,
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final response = await _apiService.uploadProfilePhoto(
        image.path,
        isPrimary: _photos.isEmpty,
      );

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (response.success && response.data != null) {
        setState(() => _photos.add(response.data!));
      } else {
        _fail(apiErrorText(context.l10n, response.errorKind));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileUploadUnavailable),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'displayName': _nameController.text.trim(),
      if (_birthDate != null) 'birthdate': _formatBirthdate(_birthDate!),
      if (_gender != null) 'gender': _gender,
      if (_cityController.text.trim().isNotEmpty)
        'location': _cityController.text.trim(),
      if (_religiousConsent && _denomination != null)
        'denomination': _denomination!.storedValue,
      if (_religiousConsent && _kashrut != null)
        'kashrutLevel': _kashrut!.storedValue,
      if (_religiousConsent && _shabbat != null)
        'shabbatObservance': _shabbat!.storedValue,
      if (_lookingFor != null) 'lookingFor': _lookingFor,
      'ageMin': _ageRange.start.round(),
      'ageMax': _ageRange.end.round(),
      'distanceMax': _maxDistance.round(),
      if (_religiousConsent && _goal != null)
        'relationshipIntention': _storedGoal(_goal!),
    };

    final response = await _apiService.updateProfile(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.success) {
      // Gender and looking-for are both in this payload (checked above).
      ProfileCompletenessService().markComplete();
      context.go(RoutePaths.discover);
    } else {
      _fail(apiErrorText(context.l10n, response.errorKind));
    }
  }

  /// What the API stores for the goal (the sign-up has always written these
  /// words, and the display side reads them back).
  String? _storedGoal(RelationshipIntention goal) => switch (goal) {
    RelationshipIntention.marriage => 'Mariage',
    RelationshipIntention.serious => 'Relation serieuse',
    RelationshipIntention.undecided => 'Je ne sais pas',
    RelationshipIntention.open || RelationshipIntention.friendsFirst => null,
  };

  String _formatBirthdate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // ============ STEPS ============

  Widget _buildBasicInfoStep() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          title: l10n.profileSetupAboutYouTitle,
          subtitle: l10n.profileSetupAboutYouSubtitle,
        ),
        const SizedBox(height: 32),

        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.profileFirstName,
            hintText: l10n.profileFirstNameHint,
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _birthDate == null
                ? ''
                : DateFormat.yMd(l10n.localeName).format(_birthDate!),
          ),
          decoration: InputDecoration(
            labelText: l10n.profileBirthdate,
            hintText: l10n.profileBirthdateHint,
            suffixIcon: const Icon(LucideIcons.calendar),
          ),
          onTap: _selectBirthDate,
        ),
        const SizedBox(height: 16),

        Text(l10n.profileIAm, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderChip(
                label: l10n.profileAMan,
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderChip(
                label: l10n.profileAWoman,
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _cityController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.profileCity,
            hintText: l10n.profileCityHint,
            prefixIcon: const Icon(LucideIcons.mapPin),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          title: l10n.profileSetupPhotosTitle,
          subtitle: l10n.profileSetupPhotosSubtitle,
          trailing: _isUploadingPhoto
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: 32),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(6, (index) {
            final photo = index < _photos.length ? _photos[index] : null;
            return _PhotoSlot(
              photoUrl: photo?.url,
              isPrimary: index == 0,
              onTap: photo == null ? _pickAndUploadPhoto : null,
            );
          }),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.profileSetupPhotosTip,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJewishInfoStep() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          title: l10n.profileSetupPracticeTitle,
          subtitle: l10n.profileSetupPracticeSubtitle,
        ),
        const SizedBox(height: 32),

        ReligiousDataGate(
          onValidityChanged: (valid) {
            if (valid != _religiousConsent) setState(() => _religiousConsent = valid);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Text(l10n.profileDenomination, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _ChoiceChips<Denomination>(
          options: Denomination.choices,
          labelOf: (kind) => kind.label(l10n),
          selected: _denomination,
          onSelected: (v) => setState(() => _denomination = v),
        ),

        const SizedBox(height: 24),

        Text(l10n.profileFieldKashrut, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _ChoiceChips<Kashrut>(
          options: Kashrut.choices,
          labelOf: (kind) => kind.optionLabel(l10n),
          selected: _kashrut,
          onSelected: (v) => setState(() => _kashrut = v),
        ),

        const SizedBox(height: 24),

        Text(l10n.profileShabbat, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _ChoiceChips<ShabbatObservance>(
          options: ShabbatObservance.choices,
          labelOf: (kind) => kind.optionLabel(l10n),
          selected: _shabbat,
          onSelected: (v) => setState(() => _shabbat = v),
        ),

            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(l10n.profileSynagogue, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _ChoiceChips<SynagogueVisits>(
          options: SynagogueVisits.values,
          labelOf: (kind) => kind.label(l10n),
          selected: _synagogue,
          onSelected: (v) => setState(() => _synagogue = v),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StepHeader(
          title: l10n.profileSetupLookingTitle,
          subtitle: l10n.profileSetupLookingSubtitle,
        ),
        const SizedBox(height: 32),

        Text(l10n.profileILookFor, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderChip(
                label: l10n.profileAMan,
                selected: _lookingFor == 'male',
                onTap: () => setState(() => _lookingFor = 'male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderChip(
                label: l10n.profileAWoman,
                selected: _lookingFor == 'female',
                onTap: () => setState(() => _lookingFor = 'female'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(l10n.profileAgeRange, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 60,
          divisions: 42,
          labels: RangeLabels(
            '${_ageRange.start.round()}',
            '${_ageRange.end.round()}',
          ),
          onChanged: (values) => setState(() => _ageRange = values),
        ),

        const SizedBox(height: 24),

        Text(l10n.profileMaxDistance, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 5,
          max: 200,
          divisions: 39,
          label: l10n.profileDistanceSliderLabel(_maxDistance.round()),
          onChanged: (value) => setState(() => _maxDistance = value),
        ),

        const SizedBox(height: 24),

        Text(l10n.profileGoal, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ReligiousDataLocked(
          locked: !_religiousConsent,
          child: _ChoiceChips<RelationshipIntention>(
            options: RelationshipIntention.setupChoices,
            labelOf: (intention) => intention.label(l10n),
            selected: _goal,
            onSelected: (v) => setState(() => _goal = v),
          ),
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.profileShadchanNote,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return FilterChip(
          label: Text(labelOf(option)),
          selected: selected == option,
          onSelected: (_) => onSelected(option),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    this.photoUrl,
    this.isPrimary = false,
    this.onTap,
  });

  final String? photoUrl;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(isPrimary ? 10 : 12),
                child: CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(LucideIcons.user, color: Colors.white54, size: 32),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imagePlus,
                    color: isPrimary ? AppColors.primary : Colors.grey,
                    size: 32,
                  ),
                  if (isPrimary) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.profilePrimaryPhoto,
                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
