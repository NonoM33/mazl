import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/likes/like_allowance.dart';
import '../../../../core/likes/like_allowance_api.dart';
import '../../../../core/models/swipe_result.dart';
import '../../../../core/premium/purchase_moments.dart';
import '../../../../core/premium/swipe_undo_api.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/store/credit_models.dart';
import '../../../../core/services/store/credits_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/swipe_deck/swipe_deck.dart';
import '../../passport/l10n/passport_city_label.dart';
import '../../passport/screens/passport_screen.dart';
import '../../../widgets/skeletons.dart';
import '../../chat/conversation_lookup.dart';
import '../widgets/discover_card.dart';
import '../widgets/match_sheet.dart';
import '../widgets/super_like_note_sheet.dart';
import '../../../../core/layout/fold_message_view.dart';
import '../../../common/widgets/fold_pages.dart';

/// One pass, like or Super Like the deck let go, to take back with the server.
class _ThrownCard {
  _ThrownCard(this.index, this.sent);

  final int index;

  /// Whether the server recorded it (true once its answer was a success).
  final Future<bool> sent;
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.apiService,
    this.likeAllowanceApi,
    this.swipeUndoApi,
    this.offerPlus,
  });

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  /// Reads how many likes the server still lets the member send today.
  final LikeAllowanceApi? likeAllowanceApi;

  /// Asks the server to take back the last pass or like.
  final SwipeUndoApi? swipeUndoApi;

  /// Shows the mazl+ offer for a moment; the app uses [PurchaseMoments.offer].
  final Future<bool> Function(BuildContext context, PurchaseMoment moment)?
  offerPlus;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final SwipeDeckController _deck = SwipeDeckController();
  final DataPrefetchService _prefetchService = DataPrefetchService();
  late final ApiService _apiService = widget.apiService ?? ApiService();
  late final LikeAllowanceApi _allowanceApi =
      widget.likeAllowanceApi ?? HttpLikeAllowanceApi.app();
  late final SwipeUndoApi _undoApi = widget.swipeUndoApi ?? HttpSwipeUndoApi();
  final CreditsService _credits = CreditsService();

  /// What the deck let go, oldest first: the undo button takes the last back.
  final List<_ThrownCard> _thrown = [];
  bool _undoing = false;

  /// The word chosen for the Super Like that is leaving, read in [_onSwiped].
  String? _pendingNote;

  /// The member closed the word sheet: the card springs back and no gate opens.
  bool _noteCancelled = false;

  /// The day's likes as the SERVER last said it; null until it has.
  LikeAllowance? _allowance;

  /// The card [SwipeDeck.undo] last brought back, to know when the refused
  /// one is on top again.
  int? _undoneIndex;

  List<Profile> _profiles = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  ApiErrorKind? _errorKind;

  /// How long a Boost lasts, as announced to the member.
  static const int _boostMinutes = 30;

  bool _swipeFromDetail = false; // Flag to prevent duplicate API calls

  /// Bumped with each new list so the deck starts again from its first card.
  int _deckGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    unawaited(_refreshAllowance());
    // The Super Like badge shows the server's balance.
    _credits.addListener(_onCreditsChanged);
    if (!_credits.isLoaded) unawaited(_credits.refresh());
  }

  void _onCreditsChanged() {
    if (mounted) setState(() {});
  }

  /// Asks the server how many likes are left today. An unreadable answer is
  /// not « none »: nothing is refused here, the server refuses what it cannot
  /// take.
  Future<void> _refreshAllowance() async {
    try {
      final allowance = await _allowanceApi.getAllowance();
      if (mounted) _allowance = allowance;
    } on LikeAllowanceException catch (error) {
      debugPrint('Like allowance unavailable: ${error.kind.name}');
    }
  }

  bool get _likesKnownExhausted =>
      _allowance?.isExhaustedAt(DateTime.now()) ?? false;

  Future<void> _initializeData() async {
    // Try to use prefetched data first
    final cachedProfiles = _prefetchService.discoverProfiles;
    if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
      setState(() {
        _profiles = cachedProfiles;
        _thrown.clear();
        _deckGeneration++;
        _isLoading = false;
      });
    } else {
      // Load from API if no cached data
      await _loadProfiles();
    }
  }

  Future<void> _loadProfiles({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    final response = await _apiService.getDiscoverProfiles();
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _profiles = response.data!;
        _thrown.clear();
        _deckGeneration++;
        _isLoading = false;
      });
    } else {
      setState(() {
        _loadFailed = true;
        _errorKind = response.errorKind;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _deck.dispose();
    _credits.removeListener(_onCreditsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      // SafeArea réserve aussi la place de la barre d'onglets flottante.
      body: SafeArea(
        child: Column(
          children: [
            _buildTopRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const MazlWordmark(size: 26),
          const Spacer(),
          RoundIconButton(
            icon: LucideIcons.sparkles,
            tooltip: context.l10n.matchingDiscoverDailyPicks,
            onPressed: () => context.push(RoutePaths.dailyPicks),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: LucideIcons.globe,
            tooltip: context.l10n.passportTitle,
            onPressed: _openPassport,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: LucideIcons.slidersHorizontal,
            tooltip: context.l10n.matchingFilters,
            onPressed: _openFilters,
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await context.push<bool>(RoutePaths.filters);
    if (result == true && mounted) {
      // Reload profiles with new filters
      _loadProfiles(isRefresh: true);
    }
  }

  /// The Passeport (mazl+): another city for Discover. Back from it with a new
  /// passport, the feed is read again for that city.
  Future<void> _openPassport() async {
    final change = await context.push<PassportChange>(RoutePaths.passport);
    if (change == null || !mounted) return;
    final l10n = context.l10n;
    final passport = change.passport;
    _showMessage(
      passport == null
          ? l10n.passportDeactivated
          : l10n.passportActivated(
              passportServerCityLabel(l10n, passport.city),
            ),
    );
    await _loadProfiles(isRefresh: true);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ProfileCardSkeleton();
    }
    if (_loadFailed) {
      return _buildError();
    }
    if (_profiles.isEmpty) {
      return _buildEmpty();
    }
    return _buildSwiper();
  }

  Widget _buildError() => FoldMessageView(
    icon: LucideIcons.circleAlert,
    title: apiErrorText(context.l10n, _errorKind),
    actionLabel: context.l10n.commonRetry,
    onAction: _loadProfiles,
  );

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
    // The words on the page where reading starts, the actions on the other
    // when the fold cuts the screen.
    return FoldPages(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 28,
      lead: [
        Text(
          context.l10n.matchingDiscoverEmptyTitle,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.matchingDiscoverEmptyBody,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
      rest: [
        OutlinedButton(
          onPressed: _openFilters,
          child: Text(context.l10n.matchingDiscoverOpenFilters),
        ),
        const SizedBox(height: 4),
        // No inner padding: its text sits on the same edge as the title.
        TextButton(
          onPressed: _loadProfiles,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 48),
            alignment: AlignmentDirectional.centerStart,
          ),
          child: Text(context.l10n.matchingDiscoverRefresh),
        ),
      ],
    );
  }

  Widget _buildSwiper() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SwipeDeck(
        key: ValueKey(_deckGeneration),
        controller: _deck,
        itemCount: _profiles.length,
        allowed: const {
          SwipeDirection.left,
          SwipeDirection.right,
          SwipeDirection.up,
        },
        intents: {
          SwipeDirection.right: SwipeIntent(
            icon: LucideIcons.heart,
            color: scheme.primary,
          ),
          SwipeDirection.left: const SwipeIntent(
            icon: LucideIcons.x,
            color: AppColors.muted,
          ),
          SwipeDirection.up: SwipeIntent(
            icon: LucideIcons.star,
            color: scheme.primary,
          ),
        },
        heavyHapticOn: const {SwipeDirection.up},
        onWillSwipe: _willSwipe,
        onRefused: _onRefused,
        onSwiped: _onSwiped,
        onUndone: (index) {
          _undoneIndex = index;
          _thrown.removeWhere((card) => card.index == index);
        },
        onEnd: _onDeckEnd,
        cardBuilder: (context, index, isTop) {
          final profile = _profiles[index];
          return DiscoverCard(
            profile: profile,
            swipeProgress: isTop ? _deck.progress : null,
            onPass: () => _deck.swipe(SwipeDirection.left),
            onLike: () => _deck.swipe(SwipeDirection.right),
            onTapProfile: () async {
              final result = await context.push<String>(
                '/discover/profile/${profile.userId}',
              );
              if (result != null && mounted) {
                _handleSwipeFromDetail(result);
              }
            },
            secondaryActions: _buildSecondaryActions(followsSwipe: isTop),
          );
        },
      ),
    );
  }

  List<Widget> _buildSecondaryActions({required bool followsSwipe}) {
    final undo = DiscoverMiniAction(
      icon: LucideIcons.undo2,
      tooltip: context.l10n.discoverUndo,
      onPressed: () => unawaited(_onUndoPressed()),
    );
    final superLike = DiscoverMiniAction(
      icon: LucideIcons.star,
      tooltip: context.l10n.matchingDiscoverSuperLike,
      badge: PremiumGate.remainingSuperLikes.toString(),
      // Refused (none left): the card stays, then the gate opens.
      onPressed: () => _deck.swipe(SwipeDirection.up),
    );
    return [
      // Undo: the server decides whether the last choice can be taken back.
      undo,
      // Super Like
      if (followsSwipe)
        SwipeProgressScale(
          progress: _deck.progress,
          direction: SwipeDirection.up,
          child: superLike,
        )
      else
        superLike,
      // Boost: the server decides if one can start (included in mazl+, or
      // bought), so the button is open to everyone.
      DiscoverMiniAction(
        icon: LucideIcons.zap,
        tooltip: context.l10n.matchingDiscoverBoost,
        onPressed: _onBoostPressed,
      ),
    ];
  }

  Future<void> _onBoostPressed() async {
    if (!_credits.isLoaded) await _credits.refresh();
    if (!mounted) return;
    if (PremiumGate.remainingBoosts <= 0) {
      final bought = await PremiumGate.offerCredits(
        context,
        CreditKind.boost,
        boostMinutes: _boostMinutes,
      );
      if (!bought || !mounted) return;
    }
    await _activateBoost();
  }

  Future<void> _activateBoost() async {
    final response = await _apiService.activateBoost();
    if (!mounted) return;

    if (response.success) {
      _showMessage(context.l10n.matchingDiscoverBoostOn(_boostMinutes));
    } else if (response.isCreditsExhausted) {
      // The server's balance (already read) says there is none: the packs.
      await PremiumGate.offerCredits(
        context,
        CreditKind.boost,
        boostMinutes: _boostMinutes,
      );
    } else if (response.isBoostAlreadyActive) {
      _showMessage(apiErrorText(context.l10n, response.errorKind));
    } else {
      _showMessage(context.l10n.matchingDiscoverBoostFailed);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _handleSwipeFromDetail(String action) {
    // Set flag to prevent duplicate API call (already sent from detail page)
    _swipeFromDetail = true;

    // Trigger the swipe animation based on the action from profile detail
    final direction = switch (action) {
      'like' => SwipeDirection.right,
      'pass' => SwipeDirection.left,
      'super_like' => SwipeDirection.up,
      _ => null,
    };
    if (direction == null) {
      _swipeFromDetail = false;
      return;
    }
    _deck.swipe(direction).then((left) {
      if (!left) _swipeFromDetail = false;
    });
  }

  /// Asked before the card moves: a like or a super like that is not allowed
  /// keeps the card, which springs back, and the gate opens in [_onRefused].
  FutureOr<bool> _willSwipe(int index, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.right:
        // Le serveur compte les likes du jour. Ici on ne refuse que ce qu'il a
        // déjà dit épuisé ; sinon il tranche au moment d'envoyer (402). Un like
        // venu de la fiche profil a déjà été contrôlé là-bas.
        return _swipeFromDetail || !_likesKnownExhausted;
      case SwipeDirection.up:
        // Check if user has super likes remaining
        if (PremiumGate.remainingSuperLikes <= 0) return false;
        // From the profile page the Super Like is already sent there.
        if (_swipeFromDetail) return true;
        return _askSuperLikeNote();
      case SwipeDirection.left:
        return true;
    }
  }

  /// The card is back in place: now the premium gate may open.
  void _onRefused(int index, SwipeDirection direction) {
    _swipeFromDetail = false;
    if (_noteCancelled) {
      // The member changed their mind in the word sheet: nothing to buy.
      _noteCancelled = false;
      return;
    }
    if (direction == SwipeDirection.right) {
      unawaited(_offerPlusForLikes());
    } else if (direction == SwipeDirection.up) {
      unawaited(_offerSuperLikes());
    }
  }

  /// Asks for the optional word of the Super Like. False (the sheet was
  /// closed or cancelled) keeps the card and sends nothing.
  Future<bool> _askSuperLikeNote() async {
    _pendingNote = null;
    final choice = await showSuperLikeNoteSheet(context);
    if (!mounted) return false;
    switch (choice) {
      case null:
        _noteCancelled = true;
        return false;
      case SendWithNote(:final note):
        _pendingNote = note;
        return true;
      case SendWithoutNote():
        return true;
    }
  }

  /// The balance says none is left: the packs sheet opens. The card goes up
  /// by itself once the server says a Super Like can be spent.
  Future<void> _offerSuperLikes() async {
    // An unknown balance is not « none »: ask the server before refusing.
    if (!_credits.isLoaded) await _credits.refresh();
    if (!mounted) return;
    if (PremiumGate.remainingSuperLikes > 0) {
      unawaited(_deck.swipe(SwipeDirection.up));
      return;
    }
    final bought = await PremiumGate.offerCredits(
      context,
      CreditKind.superLike,
    );
    if (bought && mounted && PremiumGate.remainingSuperLikes > 0) {
      unawaited(_deck.swipe(SwipeDirection.up));
    }
  }

  /// The server refused a Super Like the app thought it could send (HTTP 402):
  /// its balance has been read from the answer. The card is already gone, so
  /// once a pack is bought the Super Like is sent again to the same person.
  Future<void> _offerSuperLikesAfterRefusal(
    Profile profile,
    String? note,
  ) async {
    if (!mounted) return;
    final bought = await PremiumGate.offerCredits(
      context,
      CreditKind.superLike,
    );
    if (!bought) return;
    final response = await _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: 'super_like',
      note: note,
    );
    if (mounted && response.success && response.data?['match'] == true) {
      unawaited(_showMatchDialog(profile));
    }
  }

  void _onSwiped(int index, SwipeDirection direction) {
    final profile = _profiles[index];

    String action;
    if (direction == SwipeDirection.right) {
      debugPrint('Liked ${profile.displayName}');
      action = 'like';
    } else if (direction == SwipeDirection.left) {
      debugPrint('Passed ${profile.displayName}');
      action = 'pass';
    } else {
      debugPrint('Super liked ${profile.displayName}');
      action = 'super_like';
    }

    // The word of a Super Like leaves with it, whatever happens next.
    final note = action == 'super_like' ? _pendingNote : null;
    if (action == 'super_like') _pendingNote = null;

    // Skip API call if swipe came from detail page (already sent)
    if (_swipeFromDetail) {
      _swipeFromDetail = false;
      _thrown.add(_ThrownCard(index, Future.value(true)));
      return;
    }

    // Send swipe to backend
    final sending = _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: action,
      note: note,
    );
    _thrown.add(
      _ThrownCard(index, sending.then((response) => response.success)),
    );
    sending.then((response) {
      if (response.success && swipeMatched(response.data)) {
        // Show match animation
        _showMatchDialog(profile);
      } else if (response.isLikesExhausted) {
        unawaited(_onLikeRefusedByServer(index, profile, response));
      } else if (response.isCreditsExhausted) {
        unawaited(_offerSuperLikesAfterRefusal(profile, note));
      } else if (response.errorCode == 'invalid_note') {
        unawaited(_onNoteRefusedByServer(index, profile));
      }
      if (response.success && action == 'like') {
        // Le reste du jour a baissé : on le relit, on ne le calcule pas.
        unawaited(_refreshAllowance());
      }
    });
  }

  /// The server refused the word of a Super Like (HTTP 400 `invalid_note`:
  /// too long, a link, contact details). Nothing was sent or spent: the card
  /// is put back so the member can write another one.
  Future<void> _onNoteRefusedByServer(int index, Profile profile) async {
    await _bringBack(index, profile);
    if (mounted) _showMessage(context.l10n.superLikeNoteRefused);
  }

  /// Takes the last pass or like back: the SERVER decides, and the card only
  /// comes back once it agreed (or when it never recorded the choice).
  Future<void> _onUndoPressed() async {
    if (_undoing) return;
    if (_thrown.isEmpty) {
      _showMessage(context.l10n.discoverUndoNothing);
      return;
    }
    _undoing = true;
    try {
      final recorded = await _thrown.last.sent;
      if (!mounted) return;
      // A choice the server never received has nothing to take back there.
      if (recorded) await _undoApi.undoLastSwipe();
      if (!mounted) return;
      await _restoreLastCard();
    } on SwipeUndoException catch (error) {
      if (mounted) await _onUndoRefused(error);
    } finally {
      _undoing = false;
    }
  }

  /// The last card that left comes back on top. One try per frame for about a
  /// second: the deck is busy while a card is being dragged or thrown.
  Future<void> _restoreLastCard() async {
    const attempts = 60;
    for (var attempt = 0; attempt < attempts && mounted; attempt++) {
      _undoneIndex = null;
      await _deck.undo();
      if (_undoneIndex != null) return;
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _onUndoRefused(SwipeUndoException error) async {
    final l10n = context.l10n;
    switch (error.kind) {
      case SwipeUndoErrorKind.limitReached:
        final offer = widget.offerPlus ?? PurchaseMoments.offer;
        final shown = await offer(context, PurchaseMoment.undoRefused);
        // The offer is made once a day: the other times, say why nothing moved.
        if (!shown && mounted) _showMessage(l10n.discoverUndoLimit);
      case SwipeUndoErrorKind.nothingToUndo:
        _showMessage(l10n.discoverUndoNothing);
      case SwipeUndoErrorKind.notPossible:
        _showMessage(l10n.discoverUndoNotPossible);
      case SwipeUndoErrorKind.sessionExpired:
        _showMessage(l10n.errorSessionExpired);
      case SwipeUndoErrorKind.server:
        _showMessage(l10n.errorServer);
      case SwipeUndoErrorKind.timeout:
        _showMessage(l10n.errorTimeout);
      case SwipeUndoErrorKind.network:
        _showMessage(l10n.errorNetwork);
      case SwipeUndoErrorKind.unknown:
        _showMessage(l10n.discoverUndoFailed);
    }
  }

  /// The server took no like (HTTP 402 `likes_exhausted`): the card the member
  /// threw is put back, then the mazl+ offer opens.
  Future<void> _onLikeRefusedByServer(
    int index,
    Profile profile,
    ApiResponse<Map<String, dynamic>> response,
  ) async {
    final told = response.exhaustedAllowance;
    if (told != null) {
      _allowance = told;
    } else {
      await _refreshAllowance();
    }
    await _bringBack(index, profile);
    if (mounted) await _offerPlusForLikes();
  }

  /// Puts the card [index] back on top. The member may have thrown others
  /// since (the answer was slow): they come back first, in order. A deck that
  /// has already ended is built again from this one card.
  Future<void> _bringBack(int index, Profile profile) async {
    // One try per frame for about a second: the deck is busy while a card is
    // being dragged or thrown.
    const attempts = 60;
    for (var attempt = 0; attempt < attempts && mounted; attempt++) {
      _undoneIndex = null;
      await _deck.undo();
      final undone = _undoneIndex;
      if (undone == index) return;
      // Another card came back (go on at once), or the deck was busy (next frame).
      if (undone == null) await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted && _profiles.isEmpty) {
      setState(() {
        _profiles = [profile];
        _deckGeneration++;
      });
    }
  }

  /// The day's likes are gone: the existing sheet, with the server's limit and
  /// reset time. Back from it (the member may have subscribed), the server is
  /// asked again.
  Future<void> _offerPlusForLikes() async {
    if (!mounted) return;
    final allowance = _allowance;
    await PremiumGate.showDailyLimitSheet(
      context,
      freeLikesPerDay: allowance?.dailyAllowance,
      resetsAt: allowance?.resetsAt,
    );
    await _refreshAllowance();
  }

  /// Every profile has been seen: the empty state offers to look again.
  void _onDeckEnd() {
    if (!mounted) return;
    setState(() => _profiles = const []);
  }

  Future<void> _showMatchDialog(Profile profile) async {
    final choice = await showMatchSheet(context, matched: profile);
    if (choice == MatchSheetChoice.message && mounted) {
      await _openConversationWith(profile.userId);
    }
  }

  /// Le serveur crée la conversation au match sans renvoyer son id : on la
  /// retrouve par la personne, et à défaut on ouvre Messages.
  Future<void> _openConversationWith(int userId) async {
    final route = await conversationRouteWith(_apiService, userId);
    if (!mounted) return;
    context.go(route);
  }
}
