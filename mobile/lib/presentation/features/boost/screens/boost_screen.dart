import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/store/credit_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../../core/layout/fold_message_view.dart';

/// Screen to manage and activate profile boost
class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  /// How long one Boost lasts.
  static const int _boostMinutes = 30;

  late final ApiService _apiService = widget.apiService ?? ApiService();

  BoostStatus? _boostStatus;
  bool _isLoading = true;
  bool _isActivating = false;
  bool _loadFailed = false;
  ApiErrorKind? _errorKind;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBoostStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoostStatus() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    final result = await _apiService.getBoostStatus();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _boostStatus = result.data;
          if (_boostStatus!.isActive) {
            _startTimer();
          }
        } else {
          _loadFailed = true;
          _errorKind = result.errorKind;
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {}); // Refresh remaining time display
        if (_boostStatus?.minutesRemaining == 0) {
          _timer?.cancel();
          _loadBoostStatus(); // Reload to get final stats
        }
      }
    });
  }

  /// Boosts the member can start now: the server's balance, else the older
  /// `remaining_boosts` of a server that does not send it yet.
  int? get _remaining =>
      _boostStatus?.credits?.boost.available ?? _boostStatus?.remainingBoosts;

  /// The button: with nothing left the packs sheet opens first, and the Boost
  /// starts once a pack is bought.
  Future<void> _onActivatePressed() async {
    final remaining = _remaining;
    if (remaining != null && remaining <= 0) {
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
    setState(() => _isActivating = true);

    final result = await _apiService.activateBoost();

    if (!mounted) return;
    setState(() => _isActivating = false);

    if (result.success && result.data != null) {
      setState(() {
        _boostStatus = result.data;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.boostActivated),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (result.isCreditsExhausted) {
      // The server's balance (read from its answer) says none is left.
      await PremiumGate.offerCredits(
        context,
        CreditKind.boost,
        boostMinutes: _boostMinutes,
      );
      if (mounted) await _loadBoostStatus();
    } else if (result.isBoostAlreadyActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorText(context.l10n, result.errorKind))),
      );
      await _loadBoostStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.boostActivateFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.boostTitle),
        leading: IconButton(
          icon: const DirectionalIcon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const FoldSpinner()
          : _loadFailed
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return FoldMessageView(
      icon: LucideIcons.alertCircle,
      title: apiErrorText(context.l10n, _errorKind),
      actionLabel: context.l10n.commonRetry,
      onAction: _loadBoostStatus,
    );
  }

  Widget _buildContent() {
    final isActive = _boostStatus?.isActive ?? false;
    final details = <Widget>[
      // Stats or benefits
      if (isActive) _buildActiveStats() else _buildBenefits(),

      const SizedBox(height: 16),

      // Premium upsell if not premium
      if (_remaining != null && _remaining! <= 1) _buildPremiumUpsell(),
    ];

    return FoldCutBuilder(
      builder: (context, cut) {
        if (cut?.axis == FoldSplitAxis.vertical) {
          return _buildBook(cut!, isActive, details);
        }
        final list = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            _buildHeaderCard(isActive),

            const SizedBox(height: 24),

            ...details,
          ],
        );
        if (isActive) return list;
        // The action stays anchored under the scrolling content, above the
        // home indicator and out of the fold.
        return Column(
          children: [
            Expanded(child: list),
            _buildAnchoredActivate(),
          ],
        );
      },
    );
  }

  Widget _buildAnchoredActivate() => SafeArea(
    top: false,
    child: FoldSafeActions(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _buildActivateButton(),
      ),
    ),
  );

  /// Held like a book: the Boost card (promise, countdown) on the
  /// reading-start page, the benefits or the stats, the upsell and the
  /// activation button on the other.
  Widget _buildBook(FoldCut cut, bool isActive, List<Widget> details) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: cut.leadExtent,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildHeaderCard(isActive),
          ),
        ),
      ),
      SizedBox(width: cut.gap),
      Expanded(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: details,
              ),
            ),
            if (!isActive) _buildAnchoredActivate(),
          ],
        ),
      ),
    ],
  );

  Widget _buildHeaderCard(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
              : [const Color(0xFF6C5CE7), const Color(0xFFa29bfe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.success : const Color(0xFF6C5CE7))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated rocket icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? LucideIcons.zap : LucideIcons.rocket,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isActive
                ? context.l10n.boostHeadlineActive
                : context.l10n.boostHeadlineIdle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (isActive) ...[
            Text(
              context.l10n.boostMinutesLeft(_boostStatus!.minutesRemaining),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _boostStatus!.minutesRemaining / _boostMinutes,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 6,
              ),
            ),
          ] else
            Text(
              context.l10n.boostTagline,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart2, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.boostDuringTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.eye,
                    value: '${_boostStatus?.viewsDuringBoost ?? 0}',
                    label: context.l10n.boostViews,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.heart,
                    value: '${_boostStatus?.likesDuringBoost ?? 0}',
                    label: context.l10n.boostLikes,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.boostBenefitsTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _BenefitRow(
              icon: LucideIcons.trendingUp,
              text: context.l10n.boostBenefitFirst,
              color: Colors.purple,
            ),
            _BenefitRow(
              icon: LucideIcons.eye,
              text: context.l10n.boostBenefitVisibility(_boostMinutes),
              color: Colors.blue,
            ),
            _BenefitRow(
              icon: LucideIcons.heart,
              text: context.l10n.boostBenefitMatches,
              color: AppColors.secondary,
            ),
            _BenefitRow(
              icon: LucideIcons.barChart2,
              text: context.l10n.boostBenefitStats,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivateButton() {
    final remaining = _remaining;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActivating ? null : _onActivatePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isActivating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.rocket, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.boostActivate,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (remaining != null) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.boostRemaining(remaining),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumUpsell() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.plus, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.boostUpsellTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  context.l10n.boostUpsellBody,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.premium),
            child: Text(context.l10n.commonSee),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
