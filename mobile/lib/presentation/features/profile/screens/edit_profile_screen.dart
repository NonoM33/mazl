import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/profile_labels.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../common/widgets/directional_icon.dart';
import '../l10n/profile_answer_labels.dart';
import '../widgets/profile_prompts_section.dart';
import '../widgets/relationship_intention_selector.dart';
import '../../../common/widgets/mazl_sheet.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final _bioController = TextEditingController();

  UserProfile? _userProfile;
  List<ProfilePhoto> _photos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _hasLoadError = false;
  ApiErrorKind? _errorKind;

  // Editable fields
  String? _displayName;
  String? _location;
  String? _bio;
  String? _denomination;
  String? _kashrut;
  String? _shabbatObservance;
  String? _relationshipIntention;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _errorKind = null;
    });

    // Load user profile
    final userResponse = await _apiService.getCurrentUser();

    if (userResponse.success && userResponse.data != null) {
      final user = userResponse.data!;
      final profile = user.profile;

      setState(() {
        _userProfile = user;
        _displayName = profile?.displayName ?? user.name;
        _location = profile?.location;
        _bio = profile?.bio;
        _denomination = profile?.denomination;
        _kashrut = profile?.kashrut;
        _shabbatObservance = profile?.shabbatObservance;
        _relationshipIntention = profile?.relationshipIntention;
        _bioController.text = _bio ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasLoadError = true;
        _errorKind = userResponse.errorKind;
        _isLoading = false;
      });
    }

    // Load photos separately (don't block if it fails - endpoints may not be deployed yet)
    try {
      final photosResponse = await _apiService.getProfilePhotos();
      if (photosResponse.success && photosResponse.data != null) {
        setState(() {
          _photos = photosResponse.data!;
        });
      }
    } catch (e) {
      // Silently ignore - photos feature may not be available yet
      debugPrint('Photos API not available: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final response = await _apiService.updateProfile({
      'displayName': _displayName,
      'location': _location,
      'bio': _bioController.text,
      'denomination': _denomination,
      'kashrutLevel': _kashrut,
      'shabbatObservance': _shabbatObservance,
      'relationshipIntention': _relationshipIntention,
    });

    setState(() => _isSaving = false);

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorText(context.l10n, response.errorKind)),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      setState(() => _isUploadingPhoto = false);

      if (response.success && response.data != null) {
        setState(() {
          _photos.add(response.data!);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.profilePhotoAdded),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiErrorText(context.l10n, response.errorKind)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileUploadUnavailable),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(ProfilePhoto photo) async {
    final confirmed = await showMazlSheet<bool>(
      context,
      padded: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.trash2,
              color: Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.profileDeletePhotoTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileIrreversible,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
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
                      backgroundColor: Colors.red,
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

    if (confirmed != true) return;

    try {
      final response = await _apiService.deleteProfilePhoto(photo.id);

      if (response.success) {
        setState(() {
          _photos.removeWhere((p) => p.id == photo.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.profilePhotoDeleted)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiErrorText(context.l10n, response.errorKind)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileServiceUnavailable),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _setAsPrimary(ProfilePhoto photo) async {
    try {
      final response = await _apiService.setPhotoPrimary(photo.id);

      if (response.success && response.data != null) {
        setState(() {
          _photos = response.data!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.profilePrimaryUpdated)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileServiceUnavailable),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showEditSheet(
    String title,
    String hint,
    String? currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    showMazlSheet(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.commonSave,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSelectionSheet(
    String title,
    List<_Choice> choices,
    Function(String) onSave,
  ) {
    showMazlSheet(
      context,
      isScrollControlled: true,
      padded: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Options
          ...choices.map((choice) {
            final isSelected = choice.isSelected;
            return InkWell(
              onTap: () {
                onSave(choice.storedValue);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        choice.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
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
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileEditTitle),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.commonSave),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasLoadError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(apiErrorText(context.l10n, _errorKind)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photos section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.profilePhotos,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isUploadingPhoto)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.profilePhotosHint,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _buildPhotosGrid(),

        const SizedBox(height: 24),

        // Bio
        Text(
          l10n.profileAbout,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: l10n.profileBioHint,
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Profile Prompts
        const ProfilePromptsSection(),

        const SizedBox(height: 24),

        // Relationship Intention
        RelationshipIntentionSelector(
          selectedIntention: _relationshipIntention,
          onChanged: (value) => setState(() => _relationshipIntention = value),
        ),

        const SizedBox(height: 24),

        // Basic info
        Text(
          l10n.profileBasicInfo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _EditField(
          label: l10n.profileFirstName,
          value: _displayName ?? l10n.commonNotSpecified,
          onTap: () => _showEditSheet(
            l10n.profileFirstName,
            l10n.profileEnterFirstName,
            _displayName,
            (v) => setState(() => _displayName = v),
          ),
        ),
        _EditField(
          label: l10n.profileCity,
          value: _location ?? l10n.commonNotSpecified,
          onTap: () => _showEditSheet(
            l10n.profileCity,
            l10n.profileEnterCity,
            _location,
            (v) => setState(() => _location = v),
          ),
        ),

        const SizedBox(height: 24),

        // Jewish preferences
        Text(
          l10n.profilePracticeTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _EditField(
          label: l10n.profileDenomination,
          value: denominationField(l10n, _denomination),
          onTap: () {
            final current = ProfileLabels.denominationAnswer(_denomination)?.kind;
            _showSelectionSheet(
              l10n.profileDenomination,
              [
                for (final kind in Denomination.choices)
                  _Choice(kind.label(l10n), kind.storedValue!, kind == current),
              ],
              (v) => setState(() => _denomination = v),
            );
          },
        ),
        _EditField(
          label: l10n.profileFieldKashrut,
          value: kashrutField(l10n, _kashrut),
          onTap: () {
            final current = ProfileLabels.kashrutAnswer(_kashrut)?.kind;
            _showSelectionSheet(
              l10n.profileFieldKashrut,
              [
                for (final kind in Kashrut.choices)
                  _Choice(kind.optionLabel(l10n), kind.storedValue, kind == current),
              ],
              (v) => setState(() => _kashrut = v),
            );
          },
        ),
        _EditField(
          label: l10n.profileShabbat,
          value: shabbatField(l10n, _shabbatObservance),
          onTap: () {
            final current = ProfileLabels.shabbatAnswer(_shabbatObservance)?.kind;
            _showSelectionSheet(
              l10n.profileShabbat,
              [
                for (final kind in ShabbatObservance.choices)
                  _Choice(kind.optionLabel(l10n), kind.storedValue!, kind == current),
              ],
              (v) => setState(() => _shabbatObservance = v),
            );
          },
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPhotosGrid() {
    // Get user's SSO picture as fallback
    final ssoPicture = _userProfile?.picture;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(6, (index) {
        // First show uploaded photos, then SSO picture if no photos, then empty slots
        ProfilePhoto? photo;
        String? fallbackUrl;
        bool isFromPhotos = false;

        if (index < _photos.length) {
          photo = _photos[index];
          isFromPhotos = true;
        } else if (index == 0 && _photos.isEmpty && ssoPicture != null) {
          fallbackUrl = ssoPicture;
        }

        final hasPhoto = photo != null || fallbackUrl != null;
        final photoUrl = photo?.url ?? fallbackUrl;
        final isPrimary = photo?.isPrimary ?? (index == 0 && _photos.isEmpty);

        return _PhotoSlot(
          photoUrl: photoUrl,
          isPrimary: isPrimary,
          onTap: hasPhoto ? null : _pickAndUploadPhoto,
          onRemove: isFromPhotos ? () => _deletePhoto(photo!) : null,
          onLongPress: isFromPhotos && !photo!.isPrimary
              ? () => _setAsPrimary(photo!)
              : null,
        );
      }),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    this.photoUrl,
    this.isPrimary = false,
    this.onTap,
    this.onRemove,
    this.onLongPress,
  });

  final String? photoUrl;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(color: AppColors.accentGold, width: 3)
              : null,
        ),
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isPrimary ? 9 : 12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          LucideIcons.user,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (isPrimary)
                    PositionedDirectional(
                      bottom: 4,
                      start: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.profilePrimaryPhoto,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : const Center(
                child: Icon(
                  LucideIcons.imagePlus,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const DirectionalIcon(LucideIcons.chevronRight),
      onTap: onTap,
    );
  }
}

/// Un choix d'une feuille de sélection : ce qu'on lit, et la valeur que l'API
/// enregistre.
class _Choice {
  const _Choice(this.label, this.storedValue, this.isSelected);

  final String label;
  final String storedValue;
  final bool isSelected;
}

// The values the API stores for each choice. The profile ranking compares
// these strings as they are, so they are not translated and not renamed
// (the display side lives in l10n/profile_answer_labels.dart).

extension DenominationStoredValue on Denomination {
  String? get storedValue => switch (this) {
    Denomination.secular => 'Laique',
    Denomination.traditional => 'Traditionaliste',
    Denomination.masorti => 'Massorti',
    Denomination.modernOrthodox => 'Modern Orthodox',
    Denomination.orthodox => 'Orthodox',
    Denomination.chabad => 'Habad',
    Denomination.other => 'Autre',
    Denomination.liberal => null,
  };
}

extension KashrutStoredValue on Kashrut {
  String get storedValue => switch (this) {
    Kashrut.none => 'Non',
    Kashrut.home => 'A la maison',
    Kashrut.strict => 'Strict',
    Kashrut.glatt => 'Glatt',
  };
}

extension ShabbatStoredValue on ShabbatObservance {
  String? get storedValue => switch (this) {
    ShabbatObservance.notObservant => 'Non observant',
    ShabbatObservance.partial => 'Partiellement',
    ShabbatObservance.observant => 'Observant',
    ShabbatObservance.strict => 'Tres observant',
    ShabbatObservance.family => null,
  };
}
