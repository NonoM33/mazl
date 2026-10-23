import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/verification_providers.dart';
import '../../../../core/services/verification_api.dart';
import '../providers/verification_providers.dart';
import '../verification_reasons.dart';

const String consentText =
    'Nous comparons ton visage à tes photos. Les images ne sont pas conservées ; '
    'seule une empreinte chiffrée l\'est, supprimable à tout moment.';

enum _Stage { loading, ready, working }

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  _Stage _stage = _Stage.loading;
  VerificationStatus? _status;
  String? _loadError;
  String? _problem;
  String? _note;

  VerificationApi get _api => ref.read(verificationApiProvider);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _stage = _Stage.loading;
      _loadError = null;
    });
    final response = await _api.getStatus();
    if (!mounted) return;
    setState(() {
      _stage = _Stage.ready;
      if (response.success && response.data != null) {
        _status = response.data;
      } else {
        _loadError = verificationReasonText(response.error);
      }
    });
  }

  Future<void> _verifyPhoto() async {
    setState(() {
      _stage = _Stage.working;
      _problem = null;
      _note = null;
    });

    final session = await _api.startFaceSession(FacePurpose.photo);
    if (!mounted) return;
    if (!session.success || session.data == null) {
      return _fail(session.error);
    }

    final frames = await ref.read(livenessCaptureProvider).capture(context, session.data!.challenges);
    if (!mounted) return;
    if (frames == null) {
      final expired = !DateTime.now().isBefore(session.data!.expiresAt);
      setState(() {
        _stage = _Stage.ready;
        if (expired) _problem = verificationReasonText('session_expired');
      });
      return;
    }

    final result = await _api.submitFace(session.data!.sessionId, frames);
    if (!mounted) return;
    final outcome = result.data;
    if (!result.success || outcome == null) return _fail(result.error);
    if (!outcome.verified) return _fail(outcome.reason);

    final mismatches = outcome.photoMatches.where((m) => !m.match).length;
    _note = mismatches == 0
        ? null
        : mismatches == 1
            ? 'Une de tes photos ne te ressemble pas : elle ne compte pas.'
            : '$mismatches de tes photos ne te ressemblent pas : elles ne comptent pas.';
    await _loadStatus();
  }

  void _fail(String? code) {
    setState(() {
      _stage = _Stage.ready;
      _problem = verificationReasonText(code);
    });
    if (code == 'daily_limit_reached') _loadStatus();
  }

  Future<void> _removeVerification() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ma vérification ?'),
        content: const Text('Ton badge et l\'empreinte de ton visage seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _stage = _Stage.working;
      _problem = null;
      _note = null;
    });
    final response = await _api.deleteFaceReference();
    if (!mounted) return;
    if (!response.success) return _fail(response.error);
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_stage == _Stage.loading) return const Center(child: CircularProgressIndicator());
    final status = _status;
    if (status == null) {
      return _Retry(message: _loadError ?? verificationReasonText(null), onRetry: _loadStatus);
    }
    final busy = _stage == _Stage.working;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_problem != null) _Banner(text: _problem!, error: true),
        if (_note != null) _Banner(text: _note!, error: false),
        _PhotoCard(status: status, busy: busy, onVerify: _verifyPhoto, onRemove: _removeVerification),
        const SizedBox(height: 12),
        const _IdentityCard(),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.status, required this.busy, required this.onVerify, required this.onRemove});

  final VerificationStatus status;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = status.photo.verified;
    final blockedUntil = status.nextAttemptTime;
    final blocked = !verified && blockedUntil != null && blockedUntil.isAfter(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verified ? LucideIcons.badgeCheck : LucideIcons.camera, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Photo vérifiée', style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 12),
            if (verified) ...[
              Text(_verifiedLine(status.photo.verifiedAt)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: busy ? null : onRemove,
                child: const Text('Retirer ma vérification'),
              ),
            ] else ...[
              const Text(consentText),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy || blocked ? null : onVerify,
                  child: busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Vérifier ma photo'),
                ),
              ),
              if (blocked) ...[
                const SizedBox(height: 8),
                Text(
                  'Limite atteinte, nouvel essai possible ${_whenText(blockedUntil)}.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _verifiedLine(DateTime? at) =>
      at == null ? 'Ton visage correspond à tes photos.' : 'Vérifiée le ${DateFormat('dd/MM/yyyy').format(at.toLocal())}.';

  static String _whenText(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    final time = DateFormat('HH:mm').format(local);
    return sameDay ? 'à $time' : 'le ${DateFormat('dd/MM').format(local)} à $time';
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        enabled: false,
        leading: const Icon(LucideIcons.idCard),
        title: const Text('Vérifier mon identité (passeport / CNI)'),
        trailing: Text('Bientôt', style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = error ? scheme.error : scheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
