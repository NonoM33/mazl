import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/verification_providers.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/verification_api.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../identity/identity_parts.dart';
import '../providers/verification_providers.dart';
import '../verification_reasons.dart';
import 'verification_sections.dart';
import '../../../common/widgets/fold_pages.dart';
import 'package:mazl/core/layout/bar_navigation.dart';

enum _Stage { loading, ready, working }

/// A refusal or failure as the server's code (null when there is none), kept
/// until the screen is built so the sentence is in the language then in use.
class _Reason {
  const _Reason(this.code);

  final String? code;

  String text(AppLocalizations l10n) => verificationReasonText(l10n, code);
}

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  _Stage _stage = _Stage.loading;
  VerificationStatus? _status;

  /// Set when the status could not be read; the text is made at build time
  /// from the server code (null: no code), so a language change follows.
  _Reason? _loadError;
  _Reason? _problem;

  /// How many profile photos were set aside by the last selfie, 0 for none.
  int _mismatches = 0;

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
        _loadError = _Reason(response.error);
      }
    });
  }

  Future<void> _verifyPhoto() async {
    setState(() {
      _stage = _Stage.working;
      _problem = null;
      _mismatches = 0;
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
        if (expired) _problem = const _Reason('session_expired');
      });
      return;
    }

    final result = await _api.submitFace(session.data!.sessionId, frames);
    if (!mounted) return;
    final outcome = result.data;
    if (!result.success || outcome == null) return _fail(result.error);
    if (!outcome.verified) return _fail(outcome.reason);

    _mismatches = outcome.photoMatches.where((m) => !m.match).length;
    await _loadStatus();
  }

  void _fail(String? code) {
    setState(() {
      _stage = _Stage.ready;
      _problem = _Reason(code);
    });
    if (code == 'daily_limit_reached') _loadStatus();
  }

  Future<void> _removeVerification() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.verificationRemoveDialogTitle),
        content: Text(context.l10n.verificationRemoveDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.commonCancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.commonRemove)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _stage = _Stage.working;
      _problem = null;
      _mismatches = 0;
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
    // Its own `onPressed` on this page's context: with a vertical bar the
    // button is drawn above the navigator.
    Widget back() => RoundIconButton(
      // « back » points right in a right-to-left language
      icon: Directionality.of(context) == TextDirection.rtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
      tooltip: context.l10n.commonBack,
      onPressed: () => context.pop(),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BarNavigation(
              buttons: [back()],
              inline: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: back(),
                ),
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_stage == _Stage.loading) return const FoldSpinner();
    final l10n = context.l10n;
    final status = _status;
    if (status == null) {
      return VerificationRetry(message: (_loadError ?? const _Reason(null)).text(l10n), onRetry: _loadStatus);
    }
    final busy = _stage == _Stage.working;
    // Held like a book: the title and the photo level on the page where the
    // reading starts, the identity level on the other. Flat, one list.
    return FoldSpread(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      start: [
        SectionLabel(l10n.verificationProfileEyebrow),
        const SizedBox(height: 10),
        IdentityHeadline(l10n.verificationTitle, size: 34),
        const SizedBox(height: 24),
        if (_problem != null) VerificationNotice(text: _problem!.text(l10n), error: true),
        if (_mismatches > 0) VerificationNotice(text: l10n.verificationPhotosMismatch(_mismatches), error: false),
        PhotoLevel(
          step: status.photo,
          nextAttempt: status.nextAttemptTime,
          busy: busy,
          onVerify: _verifyPhoto,
          onRemove: _removeVerification,
        ),
      ],
      end: [IdentityLevel(step: status.identity, enabled: !busy, onVerify: _verifyIdentity)],
    );
  }
}
