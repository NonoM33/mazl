import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/block_report_dialog.dart';
import '../../../widgets/skeletons.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({
    super.key,
    this.userId,
    this.isOwnProfile = false,
    this.isFromMatch = false,
  });

  final String? userId;
  final bool isOwnProfile;
  final bool isFromMatch; // True when viewing a matched profile (from chat or matches list)

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  UserProfile? _userProfile;
  Profile? _otherProfile;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  final ApiService _apiService = ApiService();
  final CoupleService _coupleService = CoupleService();
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;

  // Couple mode state
  bool _isInCoupleMode = false;
  bool _hasPendingRequest = false;
  bool _isSendingRequest = false;
  CoupleRequestStatus _coupleRequestStatus = CoupleRequestStatus.none;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    if (widget.isFromMatch) {
      _loadCoupleStatus();
    }
  }

  Future<void> _loadCoupleStatus() async {
    // Check if we're already in couple mode
    _isInCoupleMode = _coupleService.isCoupleModeEnabled;

    // Check couple request status with this user
    if (widget.userId != null) {
      final userId = int.tryParse(widget.userId!);
      if (userId != null) {
        _coupleRequestStatus = _coupleService.getRequestStatusWithUser(userId);
        _hasPendingRequest = _coupleRequestStatus == CoupleRequestStatus.pending;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    // Only show skeleton on first load
    if (!_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }

    if (widget.isOwnProfile || widget.userId == null) {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null && mounted) {
        setState(() {
          _userProfile = response.data;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    } else {
      final userId = int.tryParse(widget.userId!);
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
        return;
      }

      final response = await _apiService.getProfileById(userId);
      if (response.success && response.data != null && mounted) {
        setState(() {
          _otherProfile = response.data;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = widget.isOwnProfile || _otherProfile == null;

    // Extract profile data
    String userName;
    int? userAge;
    String userLocation;
    String? userBio;
    bool isVerified;
    String? verificationLevel;
    String? denomination;
    String? kashrut;
    String? shabbatObservance;
    String? lookingFor;
    String? gender;
    List<String> photos;
    String? fallbackPicture;
    double? distance;

    if (_otherProfile != null) {
      userName = _otherProfile!.displayName ?? 'Utilisateur';
      userAge = _otherProfile!.age;
      userLocation = _otherProfile!.location ?? 'France';
      userBio = _otherProfile!.bio;
      isVerified = _otherProfile!.isVerified;
      verificationLevel = _otherProfile!.verificationLevel;
      denomination = _otherProfile!.denomination;
      kashrut = _otherProfile!.kashrut;
      shabbatObservance = _otherProfile!.shabbatObservance;
      lookingFor = _otherProfile!.lookingFor;
      gender = _otherProfile!.gender;
      photos = _otherProfile!.photos;
      distance = _otherProfile!.distance;
      fallbackPicture = null;
    } else {
      final profile = _userProfile?.profile;
      userName = profile?.displayName ?? _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
      userAge = profile?.age;
      userLocation = profile?.location ?? 'France';
      userBio = profile?.bio;
      isVerified = profile?.isVerified ?? false;
      verificationLevel = profile?.verificationLevel;
      denomination = profile?.denomination;
      kashrut = profile?.kashrut;
      shabbatObservance = profile?.shabbatObservance;
      lookingFor = profile?.lookingFor;
      gender = profile?.gender;
      photos = profile?.photos ?? [];
      fallbackPicture = _userProfile?.picture ?? currentUser?.photoUrl;
      distance = null;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const ProfileViewSkeleton()
          : Stack(
              children: [
                // Main scrollable content
                CustomScrollView(
                  slivers: [
                    // Photo gallery header
                    SliverToBoxAdapter(
                      child: _buildPhotoGallery(
                        photos: photos,
                        fallbackPicture: fallbackPicture,
                        userName: userName,
                        isOwnProfile: isOwnProfile,
                      ),
                    ),

                    // Profile content
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        transform: Matrix4.translationValues(0, -24, 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile completion banner for own profile
                              if (isOwnProfile)
                                _buildProfileCompletionBanner(
                                  photos: photos,
                                  bio: userBio,
                                  isVerified: isVerified,
                                  location: userLocation,
                                ),

                              // Name, age, verification
                              _buildNameSection(
                                userName: userName,
                                userAge: userAge,
                                isVerified: isVerified,
                                verificationLevel: verificationLevel,
                              ),

                              const SizedBox(height: 8),

                              // Location and distance
                              _buildLocationSection(
                                location: userLocation,
                                distance: distance,
                              ),

                              const SizedBox(height: 24),

                              // Bio / About section
                              if (userBio != null && userBio.isNotEmpty)
                                _buildSection(
                                  title: 'A propos de moi',
                                  icon: LucideIcons.user,
                                  child: Text(
                                    userBio,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                              // Basic info cards
                              _buildSection(
                                title: 'Informations',
                                icon: LucideIcons.info,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (userAge != null)
                                      _buildInfoChip(
                                        icon: LucideIcons.cake,
                                        label: '$userAge ans',
                                      ),
                                    if (gender != null)
                                      _buildInfoChip(
                                        icon: gender == 'male' ? LucideIcons.user : LucideIcons.user,
                                        label: gender == 'male' ? 'Homme' : 'Femme',
                                      ),
                                    _buildInfoChip(
                                      icon: LucideIcons.mapPin,
                                      label: userLocation,
                                    ),
                                  ],
                                ),
                              ),

                              // Jewish practice section
                              if (denomination != null || kashrut != null || shabbatObservance != null)
                                _buildSection(
                                  title: 'Ma pratique',
                                  icon: LucideIcons.sparkles,
                                  child: Column(
                                    children: [
                                      if (denomination != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.star,
                                          label: 'Courant',
                                          value: denomination,
                                        ),
                                      if (kashrut != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.utensilsCrossed,
                                          label: 'Cacherout',
                                          value: kashrut,
                                        ),
                                      if (shabbatObservance != null)
                                        _buildDetailRow(
                                          icon: LucideIcons.moonStar,
                                          label: 'Shabbat',
                                          value: shabbatObservance,
                                        ),
                                    ],
                                  ),
                                ),

                              // Looking for section
                              if (lookingFor != null && lookingFor.isNotEmpty)
                                _buildSection(
                                  title: 'Ce que je recherche',
                                  icon: LucideIcons.heart,
                                  child: Text(
                                    lookingFor,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                              // Own profile actions
                              if (isOwnProfile) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),

                                _buildProfileAction(
                                  icon: LucideIcons.pencil,
                                  title: 'Modifier mon profil',
                                  subtitle: 'Photos, bio, informations',
                                  onTap: () => context.go(RoutePaths.editProfile),
                                ),
                                _buildProfileAction(
                                  icon: LucideIcons.shieldCheck,
                                  title: 'Verification',
                                  subtitle: isVerified ? 'Profil verifie' : 'Verifier mon profil',
                                  color: AppColors.success,
                                  onTap: () => context.go(RoutePaths.verification),
                                ),
                                _buildProfileAction(
                                  icon: LucideIcons.settings,
                                  title: 'Parametres',
                                  subtitle: 'Compte, notifications, confidentialite',
                                  onTap: () => context.go(RoutePaths.settings),
                                ),
                              ],

                              // AI Compatibility card for other profiles (premium feature)
                              if (!isOwnProfile)
                                _buildAICompatibilityCard(userName),

                              // Couple mode card for matched profiles
                              if (!isOwnProfile && widget.isFromMatch)
                                _buildCoupleModeCard(userName),

                              // Report/Block for other profiles
                              if (!isOwnProfile) ...[
                                const SizedBox(height: 24),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => _showReportDialog(context),
                                    icon: Icon(LucideIcons.flag, size: 16, color: Colors.grey[500]),
                                    label: Text(
                                      'Signaler ce profil',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Back button (only for other profiles)
                if (!isOwnProfile)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    child: _buildCircleButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                  ),

                // More options button (for other profiles)
                if (!isOwnProfile)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: _buildCircleButton(
                      icon: LucideIcons.moreVertical,
                      onTap: () => _showOptionsMenu(context),
                    ),
                  ),

                // Action buttons for discovery profiles (NOT for matches)
                if (!isOwnProfile && !widget.isFromMatch)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildActionButtons(context),
                  ),
              ],
            ),
    );
  }

  /// Build the couple mode activation card for matched profiles
  Widget _buildCoupleModeCard(String userName) {
    // Already in couple mode with someone else
    if (_isInCoupleMode) {
      final partnerName = _coupleService.coupleData?.partnerName ?? 'quelqu\'un';
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.heartHandshake, color: Colors.grey[600], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deja en couple',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu es en mode couple avec $partnerName',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Already sent a request to this person
    if (_hasPendingRequest) {
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentGold.withOpacity(0.1),
              AppColors.accentGold.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.clock, color: AppColors.accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demande envoyee',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$userName n\'a pas encore repondu',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _cancelCoupleRequest,
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    // Can activate couple mode
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.heartHandshake, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mode Couple',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vous avez matche ! Pret a passer a l\'etape suivante ?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activez le mode couple pour profiter d\'activites exclusives ensemble et montrer au monde que vous etes ensemble.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingRequest ? null : () => _sendCoupleRequest(userName),
              icon: _isSendingRequest
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                      ),
                    )
                  : const Icon(LucideIcons.heart, size: 18),
              label: Text(
                _isSendingRequest ? 'Envoi...' : 'Activer avec $userName',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF6B9D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCoupleRequest(String userName) async {
    if (widget.userId == null) return;
    final userId = int.tryParse(widget.userId!);
    if (userId == null) return;

    setState(() => _isSendingRequest = true);

    final success = await _coupleService.sendCoupleRequest(
      targetUserId: userId,
      targetName: userName,
      targetPicture: _otherProfile?.photos.isNotEmpty == true
          ? _otherProfile!.photos.first
          : null,
    );

    if (mounted) {
      setState(() {
        _isSendingRequest = false;
        if (success) {
          _hasPendingRequest = true;
          _coupleRequestStatus = CoupleRequestStatus.pending;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande envoyee a $userName !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de la demande'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelCoupleRequest() async {
    final success = await _coupleService.cancelCoupleRequest();

    if (mounted && success) {
      setState(() {
        _hasPendingRequest = false;
        _coupleRequestStatus = CoupleRequestStatus.none;
      });
    }
  }

  Widget _buildPhotoGallery({
    required List<String> photos,
    required String? fallbackPicture,
    required String userName,
    required bool isOwnProfile,
  }) {
    final displayPhotos = photos.isNotEmpty ? photos : <String>[];
    final hasMultiplePhotos = displayPhotos.length > 1;

    // For own profile with only SSO photo (no uploaded photos), show smaller circle
    final showSmallAvatar = isOwnProfile && photos.isEmpty && fallbackPicture != null;

    if (showSmallAvatar) {
      return _buildCompactProfileHeader(
        fallbackPicture: fallbackPicture,
        userName: userName,
      );
    }

    // Add fallback picture to displayPhotos if no photos uploaded
    final photosToShow = displayPhotos.isNotEmpty
        ? displayPhotos
        : (fallbackPicture != null ? [fallbackPicture] : <String>[]);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photos PageView
          if (photosToShow.isNotEmpty)
            PageView.builder(
              controller: _photoController,
              itemCount: photosToShow.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: photosToShow[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPhotoPlaceholder(userName),
                );
              },
            )
          else
            _buildPhotoPlaceholder(userName),

          // Photo indicators as dots at bottom (only if multiple photos)
          if (hasMultiplePhotos && photosToShow.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photosToShow.length,
                  (index) => Container(
                    width: index == _currentPhotoIndex ? 8 : 6,
                    height: index == _currentPhotoIndex ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPhotoIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Tap zones for photo navigation
          if (hasMultiplePhotos) ...[
            // Left tap zone
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: () {
                  if (_currentPhotoIndex > 0) {
                    _photoController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Right tap zone
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: () {
                  if (_currentPhotoIndex < photosToShow.length - 1) {
                    _photoController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // Gradient at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String userName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pas de photo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICompatibilityCard(String userName) {
    // TODO: Check subscription status from provider
    final hasPremium = false; // Replace with actual subscription check

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Compatibilite IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!hasPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.crown, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasPremium) ...[
            // Show actual compatibility score
            Row(
              children: [
                const Text(
                  '87%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'compatible',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Memes valeurs, interets communs en cuisine et voyages',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ] else ...[
            // Blurred preview for non-premium users
            Text(
              'Decouvre ton score de compatibilite avec $userName',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RoutePaths.premium),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Debloquer avec Premium',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactProfileHeader({
    required String? fallbackPicture,
    required String userName,
  }) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Small circle avatar that doesn't pixelate
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: fallbackPicture != null
                    ? CachedNetworkImage(
                        imageUrl: fallbackPicture,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white.withOpacity(0.2),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Sexy badge button to add photos
            GestureDetector(
              onTap: () => context.go(RoutePaths.editProfile),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.camera,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouter des photos',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection({
    required String userName,
    required int? userAge,
    required bool isVerified,
    required String? verificationLevel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            userAge != null ? '$userName, $userAge' : userName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  verificationLevel == 'verified_plus' ? 'Verifie+' : 'Verifie',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection({
    required String location,
    required double? distance,
  }) {
    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          location,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${distance!.round()} km',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileCompletionBanner({
    required List<String> photos,
    required String? bio,
    required bool isVerified,
    required String location,
  }) {
    // Calculate completion steps
    final List<_CompletionStep> steps = [
      _CompletionStep(
        icon: LucideIcons.camera,
        label: 'Photos',
        isComplete: photos.length >= 2,
        description: photos.length >= 2 ? 'Ajoutees' : 'Ajoute au moins 2 photos',
      ),
      _CompletionStep(
        icon: LucideIcons.pencil,
        label: 'Bio',
        isComplete: bio != null && bio.isNotEmpty,
        description: bio != null && bio.isNotEmpty ? 'Completee' : 'Decris-toi',
      ),
      _CompletionStep(
        icon: LucideIcons.mapPin,
        label: 'Localisation',
        isComplete: location != 'France' && location.isNotEmpty,
        description: location != 'France' ? 'Definie' : 'Indique ta ville',
      ),
      _CompletionStep(
        icon: LucideIcons.shieldCheck,
        label: 'Verification',
        isComplete: isVerified,
        description: isVerified ? 'Verifie' : 'Verifie ton profil',
      ),
    ];

    final completedCount = steps.where((s) => s.isComplete).length;
    final isComplete = completedCount == steps.length;

    // Don't show banner if profile is complete
    if (isComplete) return const SizedBox.shrink();

    final progress = completedCount / steps.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete ton profil',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(progress * 100).round()}% complete - ${steps.length - completedCount} etape${steps.length - completedCount > 1 ? 's' : ''} restante${steps.length - completedCount > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),

          // Steps list
          const SizedBox(height: 16),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: step.isComplete
                        ? AppColors.success.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.isComplete ? LucideIcons.check : step.icon,
                    size: 14,
                    color: step.isComplete ? AppColors.success : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: step.isComplete ? AppColors.success : Colors.grey[700],
                      fontWeight: step.isComplete ? FontWeight.w500 : FontWeight.normal,
                      decoration: step.isComplete ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          )),

          // Benefits
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.trophy, color: AppColors.accentGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profils complets recoivent 3x plus de matchs !',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CTA Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the first incomplete step
                final firstIncomplete = steps.firstWhere(
                  (s) => !s.isComplete,
                  orElse: () => steps.first,
                );

                if (firstIncomplete.icon == LucideIcons.camera ||
                    firstIncomplete.icon == LucideIcons.pencil) {
                  context.go(RoutePaths.editProfile);
                } else if (firstIncomplete.icon == LucideIcons.mapPin) {
                  context.go(RoutePaths.settings);
                } else if (firstIncomplete.icon == LucideIcons.shieldCheck) {
                  context.go(RoutePaths.verification);
                }
              },
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Completer maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: LucideIcons.x,
            color: Colors.grey[400]!,
            size: 56,
            onTap: () => _handleSwipe('pass'),
          ),
          // Super like button
          _buildActionButton(
            icon: LucideIcons.star,
            color: AppColors.accentGold,
            size: 48,
            onTap: () => _handleSwipe('super_like'),
          ),
          // Like button
          _buildActionButton(
            icon: LucideIcons.heart,
            color: AppColors.secondary,
            size: 56,
            onTap: () => _handleSwipe('like'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }

  Future<void> _handleSwipe(String action) async {
    if (_otherProfile == null) return;

    final response = await _apiService.sendSwipe(
      targetUserId: _otherProfile!.userId,
      action: action,
    );

    if (response.success && mounted) {
      if (response.data?['matched'] == true) {
        // Show match dialog
        _showMatchDialog();
      } else {
        context.pop();
      }
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "C'est un Match !",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vous pouvez maintenant discuter avec ${_otherProfile?.displayName ?? "cette personne"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Continuer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(RoutePaths.chat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Envoyer un message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    if (_otherProfile == null) return;

    BlockReportDialog.show(
      context,
      userId: _otherProfile!.userId,
      userName: _otherProfile!.displayName ?? 'Cet utilisateur',
      onBlocked: () {
        // Navigate back after blocking
        if (mounted) context.pop();
      },
      onReported: () {
        // Optionally navigate back after reporting
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    if (_otherProfile == null) return;

    BlockReportDialog.show(
      context,
      userId: _otherProfile!.userId,
      userName: _otherProfile!.displayName ?? 'Cet utilisateur',
      onBlocked: () {
        // Navigate back after blocking
        if (mounted) context.pop();
      },
      onReported: () {
        // Optionally navigate back after reporting
      },
    );
  }
}

class _CompletionStep {
  final IconData icon;
  final String label;
  final bool isComplete;
  final String description;

  _CompletionStep({
    required this.icon,
    required this.label,
    required this.isComplete,
    required this.description,
  });
}
