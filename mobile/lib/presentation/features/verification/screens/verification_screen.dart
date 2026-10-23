import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/verification_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/verification_api.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';
import '../providers/verification_providers.dart';
import '../verification_reasons.dart';
import 'verification_sections.dart';

export 'verification_sections.dart' show consentText;

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
        ? 'Une de vos photos ne vous ressemble pas : elle ne compte pas.'
        : '$mismatches de vos photos ne vous ressemblent pas : elles ne comptent pas.';
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
        content: const Text('Votre badge et l\'empreinte de votre visage seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
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

  Future<void> _verifyIdentity() async {
    await context.pushNamed<bool>(RouteNames.verificationIdentity);
    if (mounted) await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RoundIconButton(icon: LucideIcons.arrowLeft, tooltip: 'Retour', onPressed: () => context.pop()),
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_stage == _Stage.loading) return const Center(child: CircularProgressIndicator());
    final status = _status;
    if (status == null) {
      return VerificationRetry(message: _loadError ?? verificationReasonText(null), onRetry: _loadStatus);
    }
    final busy = _stage == _Stage.working;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const SectionLabel('Votre profil'),
        const SizedBox(height: 10),
        const IdentityHeadline('Vérification', size: 34),
        const SizedBox(height: 24),
        if (_problem != null) VerificationNotice(text: _problem!, error: true),
        if (_note != null) VerificationNotice(text: _note!, error: false),
        PhotoLevel(
          step: status.photo,
          nextAttempt: status.nextAttemptTime,
          busy: busy,
          onVerify: _verifyPhoto,
          onRemove: _removeVerification,
        ),
        IdentityLevel(step: status.identity, enabled: !busy, onVerify: _verifyIdentity),
      ],
    );
  }
}
