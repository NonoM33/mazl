import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/di/providers/web_sessions_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/web_sessions/web_session_models.dart';
import '../../../../core/web_sessions/web_sessions_api.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/web_session_format.dart';
import '../../../../l10n/l10n.dart';

enum _Stage { loading, ready, error }

/// Lists the computers connected to the account and connects a new one.
class ComputersScreen extends ConsumerStatefulWidget {
  const ComputersScreen({super.key});

  @override
  ConsumerState<ComputersScreen> createState() => _ComputersScreenState();
}

class _ComputersScreenState extends ConsumerState<ComputersScreen> {
  _Stage _stage = _Stage.loading;
  List<WebSession> _sessions = const [];

  WebSessionsApi get _api => ref.read(webSessionsApiProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _stage = _Stage.loading);
    final response = await _api.listSessions();
    if (!mounted) return;
    setState(() {
      _sessions = response.data ?? const [];
      _stage = response.success ? _Stage.ready : _Stage.error;
    });
  }

  Future<void> _connect() async {
    final connected = await context.push<bool>(RoutePaths.webScan);
    if (!mounted || connected != true) return;
    _toast(context.l10n.webSessionsConnected);
    await _load();
  }

  Future<void> _revoke(WebSession session) async {
    final response = await _api.revoke(session.id);
    if (!mounted) return;
    if (!response.success) {
      _toast(context.l10n.webSessionsRevokeFailed);
    }
    await _load();
  }

  Future<void> _revokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.webSessionsRevokeAllTitle),
        content: Text(context.l10n.webSessionsRevokeAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.webSessionsRevokeAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await _api.revokeAll();
    if (!mounted) return;
    if (!response.success) {
      _toast(context.l10n.webSessionsRevokeAllFailed);
    }
    await _load();
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.webSessionsTitle)),
      // Held like a book: what this is and the button to connect on the page
      // where the reading starts, the computers on the other.
      body: FoldSpread(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        start: [
          SectionLabel(
            context.l10n.webSessionsSectionLabel,
            color: AppColors.tekhelet,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.webSessionsIntro,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FoldSafeActions(
            child: ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(LucideIcons.qrCode),
              label: Text(context.l10n.webSessionsConnect),
            ),
          ),
          const SizedBox(height: 28),
        ],
        end: _content(),
      ),
    );
  }

  List<Widget> _content() => switch (_stage) {
    _Stage.loading => const [
      Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    ],
    _Stage.error => [
      _Notice(
        text: context.l10n.webSessionsLoadFailed,
        action: TextButton(
          onPressed: _load,
          child: Text(context.l10n.commonRetry),
        ),
      ),
    ],
    _Stage.ready when _sessions.isEmpty => [
      _Notice(text: context.l10n.webSessionsEmpty),
    ],
    _Stage.ready => [
      SectionLabel(context.l10n.webSessionsListLabel),
      for (final session in _sessions)
        _SessionTile(session: session, onRevoke: () => _revoke(session)),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _revokeAll,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(context.l10n.webSessionsRevokeAll),
      ),
    ],
  };
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onRevoke});

  final WebSession session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final details =
        '${connectionMethodLabel(l10n, session.method)} · ${lastActivityLabel(l10n, session.lastSeenAt)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(LucideIcons.monitor, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              container: true,
              label: '${session.browser}. $details',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.browser,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onRevoke,
            child: Semantics(
              label: l10n.webSessionsRevokeNamed(session.browser),
              excludeSemantics: true,
              child: Text(l10n.webSessionsRevoke),
            ),
          ),
        ],
      ),
    );
  }
}
