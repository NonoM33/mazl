import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'identity_messages.dart';

/// Frame shared by every step: a close button, one title, content, actions.
class IdentityPage extends StatelessWidget {
  const IdentityPage({super.key, this.title, required this.child, this.actions = const [], this.onClose});

  final String? title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onClose == null
            ? null
            : IconButton(icon: const Icon(Icons.close), tooltip: 'Fermer', onPressed: onClose),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(title!, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
              ],
              Expanded(child: child),
              for (final action in actions) ...[const SizedBox(height: 8), action],
            ],
          ),
        ),
      ),
    );
  }
}

/// Link to the web page where a document is reviewed by a person.
class ManualReviewButton extends StatelessWidget {
  const ManualReviewButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => launchUrl(identityManualReviewUri, mode: LaunchMode.externalApplication),
        child: const Text('Envoyer mon document pour relecture'),
      );
}

class CenteredMessage extends StatelessWidget {
  const CenteredMessage({super.key, required this.icon, required this.message, this.color});

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: color ?? theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
