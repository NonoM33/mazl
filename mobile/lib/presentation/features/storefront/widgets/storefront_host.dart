import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/dev_session.dart';
import '../../../../core/di/providers/storefront_providers.dart';

/// Keeps the storefront fresh for the life of the app: reads it at launch,
/// again when the app returns to the foreground and when the language of the
/// interface changes, and when a demo session starts or ends (the launch read
/// came before the sign-in), and puts the holiday icon on the home screen when the
/// server asks for one (docs/storefront/CONTRACT.md §7).
class StorefrontHost extends ConsumerStatefulWidget {
  const StorefrontHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StorefrontHost> createState() => _StorefrontHostState();
}

class _StorefrontHostState extends ConsumerState<StorefrontHost>
    with WidgetsBindingObserver {
  String? _languageCode;

  /// The app is in front: a launch (no state yet) or a resumed one.
  bool get _foreground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DevSession.changes.addListener(_onDemoSessionChanged);
    ref.listenManual(storefrontProvider, (_, _) => _applyIcon());
    ref.listenManual(
      festiveIconEnabledProvider,
      (_, _) => _applyIcon(userInitiated: true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    final controller = ref.read(storefrontControllerProvider.notifier);
    if (_languageCode == null) {
      _languageCode = code;
      controller.start(code).whenComplete(_applyIcon);
    } else if (_languageCode != code) {
      _languageCode = code;
      controller.refresh(languageCode: code, force: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
        .read(storefrontControllerProvider.notifier)
        .refresh(languageCode: _languageCode)
        .whenComplete(_applyIcon);
    _applyIcon();
  }

  void _onDemoSessionChanged() {
    if (!mounted) return;
    ref
        .read(storefrontControllerProvider.notifier)
        .refresh(languageCode: _languageCode, force: true)
        .whenComplete(_applyIcon);
  }

  @override
  void dispose() {
    DevSession.changes.removeListener(_onDemoSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _applyIcon({bool userInitiated = false}) {
    if (!mounted) return;
    ref
        .read(festiveIconApplierProvider)
        .apply(
          requested: ref.read(storefrontProvider).appIcon,
          enabled: ref.read(festiveIconEnabledProvider),
          foreground: _foreground,
          userInitiated: userInitiated,
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
