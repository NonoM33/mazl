import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/block_report_dialog.dart';
import '../../../widgets/skeletons.dart';
import '../widgets/profile_view/profile_action_bar.dart';
import '../widgets/profile_view/profile_compatibility_section.dart';
import '../widgets/profile_view/profile_completion_card.dart';
import '../widgets/profile_view/profile_couple_section.dart';
import '../widgets/profile_view/profile_match_dialog.dart';
import '../widgets/profile_view/profile_top_bar.dart';
import '../widgets/profile_view/profile_view_content.dart';
import '../widgets/profile_view/profile_view_data.dart';

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
  CompatibilityScore? _compatibilityScore;
  List<ProfilePrompt> _myPrompts = const [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  final ApiService _apiService = ApiService();
  final CoupleService _coupleService = CoupleService();

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
        _loadMyPrompts();
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
        final otherProfile = response.data!;
        // Load the current user's profile to compute a real compatibility score.
        final myResponse = await _apiService.getCurrentUser();
        final myProfile = myResponse.success ? myResponse.data?.profile : null;
        if (!mounted) return;
        setState(() {
          _otherProfile = otherProfile;
          _compatibilityScore = myProfile != null
              ? CompatibilityScore.calculate(
                  myProfile: myProfile,
                  otherProfile: otherProfile,
                )
              : null;
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

  /// Les prompts ne sont affichés que sur son propre profil : l'API n'expose
  /// que `getMyPrompts`. Un échec laisse simplement la section absente.
  Future<void> _loadMyPrompts() async {
    final response = await _apiService.getMyPrompts();
    if (!mounted || !response.success || response.data == null) return;
    final sorted = [...response.data!]..sort((a, b) => a.position.compareTo(b.position));
    setState(() => _myPrompts = sorted);
  }

  ProfileViewData _viewData() {
    final other = _otherProfile;
    if (other != null) {
      return ProfileViewData(
        name: other.displayName ?? 'Utilisateur',
        age: other.age,
        location: other.location ?? 'France',
        distance: other.distance,
        bio: other.bio,
        lookingFor: other.lookingFor,
        gender: other.gender,
        denomination: other.denomination,
        kashrut: other.kashrut,
        shabbatObservance: other.shabbatObservance,
        photos: other.photos,
        isVerified: other.isVerified,
        verificationLevel: other.verificationLevel,
      );
    }
    final currentUser = ref.watch(currentUserProvider);
    final profile = _userProfile?.profile;
    return ProfileViewData(
      name: profile?.displayName ?? _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur',
      age: profile?.age,
      location: profile?.location ?? 'France',
      bio: profile?.bio,
      lookingFor: profile?.lookingFor,
      gender: profile?.gender,
      denomination: profile?.denomination,
      kashrut: profile?.kashrut,
      shabbatObservance: profile?.shabbatObservance,
      photos: profile?.photos ?? const [],
      fallbackPicture: _userProfile?.picture ?? currentUser?.photoUrl,
      isVerified: profile?.isVerified ?? false,
      verificationLevel: profile?.verificationLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.isOwnProfile || _otherProfile == null;
    return Scaffold(
      body: _isLoading
          ? const ProfileViewSkeleton()
          : isOwnProfile
              ? _buildOwnProfile(_viewData())
              : _buildOtherProfile(_viewData()),
    );
  }

  Widget _buildOwnProfile(ProfileViewData data) {
    final steps = buildCompletionSteps(
      photos: data.photos,
      bio: data.bio,
      isVerified: data.isVerified,
      location: data.location,
    );
    return SafeArea(
      bottom: false,
      child: ProfileViewContent(
        data: data,
        isOwnProfile: true,
        // Sous la barre d'onglets flottante : paddingOf(bottom) l'inclut.
        bottomPadding: MediaQuery.paddingOf(context).bottom + 24,
        topBar: ProfileTopBar.own(
          onEdit: () => context.go(RoutePaths.editProfile),
          onSettings: () => context.go(RoutePaths.settings),
        ),
        leading: [
          ProfileCompletionCard(steps: steps, onStep: _openCompletionTarget),
        ],
        prompts: [
          for (final p in _myPrompts) (question: p.promptText, answer: p.answer),
        ],
        onVerificationTap: () => context.go(RoutePaths.verification),
        onAddPhotos: () => context.go(RoutePaths.editProfile),
      ),
    );
  }

  Widget _buildOtherProfile(ProfileViewData data) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final showActions = !widget.isFromMatch;
    final barBottom = safeBottom + 12 > 28 ? safeBottom + 12 : 28.0;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: ProfileViewContent(
            data: data,
            isOwnProfile: false,
            bottomPadding: showActions
                ? barBottom + ProfileActionBar.height + 24
                : safeBottom + 32,
            topBar: ProfileTopBar.other(
              onBack: () => context.pop(),
              onOptions: _showBlockReportDialog,
            ),
            trailing: [
              ProfileCompatibilitySection(
                firstName: data.firstName,
                hasPremium: ref.watch(isMazlProProvider),
                score: _compatibilityScore,
                onUnlock: () => context.push(RoutePaths.premium),
              ),
              if (widget.isFromMatch) _buildCoupleSection(data.name),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _showBlockReportDialog,
                  icon: const Icon(LucideIcons.flag, size: 16),
                  label: const Text('Signaler ce profil'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showActions)
          Positioned(
            left: 16,
            right: 16,
            bottom: barBottom,
            child: ProfileActionBar(
              firstName: data.firstName,
              onPass: () => _handleSwipe('pass'),
              onLike: () => _handleSwipe('like'),
            ),
          ),
      ],
    );
  }

  Widget _buildCoupleSection(String userName) {
    final state = _isInCoupleMode
        ? CoupleEntryState.inCouple
        : _hasPendingRequest
            ? CoupleEntryState.pending
            : CoupleEntryState.available;
    return ProfileCoupleSection(
      state: state,
      userName: userName,
      partnerName: _coupleService.coupleData?.partnerName,
      isSending: _isSendingRequest,
      onActivate: () => _sendCoupleRequest(userName),
      onCancel: _cancelCoupleRequest,
    );
  }

  void _openCompletionTarget(CompletionTarget target) {
    switch (target) {
      case CompletionTarget.editProfile:
        context.go(RoutePaths.editProfile);
      case CompletionTarget.settings:
        context.go(RoutePaths.settings);
      case CompletionTarget.verification:
        context.go(RoutePaths.verification);
    }
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

    if (!mounted) return;
    setState(() {
      _isSendingRequest = false;
      if (success) {
        _hasPendingRequest = true;
        _coupleRequestStatus = CoupleRequestStatus.pending;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Demande envoyée à $userName.' : "Erreur lors de l'envoi de la demande"),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _handleSwipe(String action) async {
    if (_otherProfile == null) return;

    final response = await _apiService.sendSwipe(
      targetUserId: _otherProfile!.userId,
      action: action,
    );

    if (response.success && mounted) {
      if (response.data?['matched'] == true) {
        _showMatchDialog();
      } else {
        context.pop();
      }
    }
  }

  void _showMatchDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProfileMatchDialog(
        name: _otherProfile?.displayName ?? 'cette personne',
        onContinue: () {
          Navigator.pop(dialogContext);
          context.pop();
        },
        onMessage: () {
          Navigator.pop(dialogContext);
          context.go(RoutePaths.chat);
        },
      ),
    );
  }

  /// Menu d'options et signalement : même fenêtre de blocage / signalement.
  void _showBlockReportDialog() {
    if (_otherProfile == null) return;

    BlockReportDialog.show(
      context,
      userId: _otherProfile!.userId,
      userName: _otherProfile!.displayName ?? 'Cet utilisateur',
      onBlocked: () {
        // Navigate back after blocking
        if (mounted) context.pop();
      },
      onReported: () {},
    );
  }
}
