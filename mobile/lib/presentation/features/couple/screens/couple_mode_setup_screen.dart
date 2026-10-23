import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart' show ProfilePhoto;

/// Loads the member's matches (the real API in production).
typedef MatchesLoader = Future<ApiResponse<List<Map<String, dynamic>>>> Function();

/// Choose a match and ask them to activate the couple mode. Nothing is
/// activated here: the other member has to accept (contract §0.1).
class CoupleModeSetupScreen extends StatefulWidget {
  const CoupleModeSetupScreen({super.key, this.service, this.loadMatches});

  final CoupleService? service;
  final MatchesLoader? loadMatches;

  @override
  State<CoupleModeSetupScreen> createState() => _CoupleModeSetupScreenState();
}

class _CoupleModeSetupScreenState extends State<CoupleModeSetupScreen> {
  late final CoupleService _service = widget.service ?? CoupleService();

  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isBusy = false;

  /// True right after a successful send: the confirmation has no cancel button
  /// then. Reopening the screen with a pending request shows it.
  bool _justSent = false;
  Map<String, dynamic>? _selectedProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final load = widget.loadMatches ?? ApiService().getMatches;
    final response = await load();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadFailed = !response.success;
      _matches = response.data ?? [];
    });
  }

  Future<void> _send() async {
    final profile = _selectedProfile;
    final userId = parseCoupleId(profile?['user_id']);
    if (profile == null || userId == null) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final result = await _service.sendCoupleRequest(
      targetUserId: userId,
      targetName: profile['display_name'] as String? ?? '',
      targetPicture: profile['picture'] as String?,
    );
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _justSent = result.ok;
      _errorMessage = result.message;
    });
  }

  Future<void> _cancel() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final result = await _service.cancelCoupleRequest();
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _errorMessage = result.message;
    });
  }

  /// Closes the screen and goes back to where the member came from.
  void _done() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.settings);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode couple'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: _back,
        ),
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final pending = _service.pendingRequest;
          if (pending != null) return _buildPending(context, pending);
          return _buildChooser(context);
        },
      ),
    );
  }

  Widget _buildPending(BuildContext context, CoupleRequest request) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = request.targetName ?? '';
    final who = name.isEmpty ? 'Cette personne' : name;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          _Avatar(name: name, picture: request.targetPicture, size: 96, seed: request.targetId),
          const SizedBox(height: 24),
          Text(
            'Demande envoyée',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$who doit accepter. Nous vous préviendrons dès sa réponse.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorText(_errorMessage!),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isBusy ? null : _done,
              child: const Text('Compris'),
            ),
          ),
          if (!_justSent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isBusy ? null : _cancel,
                child: _isBusy ? const _Spinner() : const Text('Annuler la demande'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChooser(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Impossible de charger vos matchs.'),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadMatches, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final profiles = [
      for (final match in _matches)
        if (match['profile'] is Map<String, dynamic>) match['profile'] as Map<String, dynamic>,
    ];
    if (profiles.isEmpty) {
      return const Center(child: Text('Aucun match pour l\'instant.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            children: [
              Text(
                'Avec qui ?',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              for (final profile in profiles) _buildOption(context, profile),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              if (_errorMessage != null) ...[
                _ErrorText(_errorMessage!),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedProfile == null || _isBusy ? null : _send,
                  child: _isBusy ? const _Spinner() : const Text('Envoyer la demande'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, Map<String, dynamic> profile) {
    final scheme = Theme.of(context).colorScheme;
    final selected = identical(_selectedProfile, profile) ||
        (_selectedProfile != null && _selectedProfile!['user_id'] == profile['user_id']);
    final name = profile['display_name'] as String? ?? '';
    final userId = parseCoupleId(profile['user_id']);
    final border = selected ? scheme.primary : _hairline(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          onTap: () => setState(() {
            _selectedProfile = profile;
            _errorMessage = null;
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Avatar(
                  name: name,
                  picture: profile['picture'] as String?,
                  size: 52,
                  seed: userId,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (selected) Icon(LucideIcons.check, size: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _hairline(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.hairline;

/// Round avatar shared by every row and the confirmation: the photo when there
/// is one, otherwise the initial on a neutral fill.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.picture, required this.size, this.seed});

  final String name;
  final String? picture;
  final double size;
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPicture = picture != null && picture!.isNotEmpty;
    return Container(
      key: const ValueKey('couple-avatar'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainer,
        border: Border.all(color: _hairline(context)),
      ),
      child: ClipOval(
        child: hasPicture
            ? ProfilePhoto(url: picture, seed: seed ?? 0, radius: size / 2, iconSize: size * 0.4)
            : Center(
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DefaultTextStyle.of(context).style.color,
        ),
      );
}
