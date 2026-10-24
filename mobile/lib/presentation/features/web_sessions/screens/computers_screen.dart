import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/web_sessions_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/web_sessions/web_session_models.dart';
import '../../../../core/web_sessions/web_sessions_api.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/web_session_format.dart';

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
    _toast('Ordinateur connecté.');
    await _load();
  }

  Future<void> _revoke(WebSession session) async {
    final response = await _api.revoke(session.id);
    if (!mounted) return;
    if (!response.success) {
      _toast('Impossible de déconnecter cet ordinateur. Réessayez.');
    }
    await _load();
  }

  Future<void> _revokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnecter tous les ordinateurs ?'),
        content: const Text(
          'Vous devrez vous reconnecter sur chaque ordinateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter tout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await _api.revokeAll();
    if (!mounted) return;
    if (!response.success) {
      _toast('Impossible de déconnecter les ordinateurs. Réessayez.');
    }
    await _load();
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordinateurs connectés')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          const SectionLabel('MAZL sur ordinateur', color: AppColors.tekhelet),
          const SizedBox(height: 8),
          Text(
            'Utilisez MAZL sur ordinateur sur app.mazl.app. '
            'Chaque ordinateur reste connecté 7 jours au plus.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _connect,
            icon: const Icon(LucideIcons.qrCode),
            label: const Text('Connecter un ordinateur'),
          ),
          const SizedBox(height: 28),
          ..._content(),
        ],
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
        text:
            'Impossible de charger vos ordinateurs. Vérifiez votre connexion.',
        action: TextButton(onPressed: _load, child: const Text('Réessayer')),
      ),
    ],
    _Stage.ready when _sessions.isEmpty => const [
      _Notice(text: 'Aucun ordinateur n\'est connecté pour le moment.'),
    ],
    _Stage.ready => [
      const SectionLabel('Ordinateurs'),
      for (final session in _sessions)
        _SessionTile(session: session, onRevoke: () => _revoke(session)),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _revokeAll,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Déconnecter tous les ordinateurs'),
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
    final details =
        '${connectionMethodLabel(session.method)} · ${lastActivityLabel(session.lastSeenAt)}';
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
              label: 'Déconnecter ${session.browser}',
              excludeSemantics: true,
              child: const Text('Déconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}
