import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/duo_tutorial/duo_scene_renderer.dart';
import '../../../../core/duo_tutorial/duo_tutorial_controller.dart';
import '../../../../core/layout/fold_state.dart';
import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../duo_tutorial_layout.dart';
import '../duo_tutorial_navigation.dart';
import '../duo_tutorial_providers.dart';
import '../l10n/duo_tutorial_text.dart';
import '../widgets/duo_check.dart';
import '../widgets/duo_step_indicator.dart';

/// Le tutoriel de l'iPhone Duo, en plein écran : une scène 3D qui suit en
/// direct la charnière réelle de l'appareil, cinq étapes à faire EN MÊME TEMPS,
/// et toujours « Passer » et « Suivant ».
///
/// Le titre et les boutons sont des widgets Flutter, lisibles par VoiceOver,
/// posés autour de la vue 3D ; l'écran se range selon la pose (voir
/// [DuoTutorialLayout]) et ne pose rien d'interactif sur le pli.
class DuoTutorialScreen extends ConsumerStatefulWidget {
  const DuoTutorialScreen({super.key, this.next, this.onFinished});

  /// La route à rejoindre à la fin (le démarrage) ; sans elle, retour d'où
  /// l'on vient (les Réglages).
  final String? next;

  /// Remplace la sortie par défaut ([leaveDuoTutorial]), pour les tests.
  final VoidCallback? onFinished;

  @override
  ConsumerState<DuoTutorialScreen> createState() => _DuoTutorialScreenState();
}

class _DuoTutorialScreenState extends ConsumerState<DuoTutorialScreen> {
  late final DuoSceneRenderer _renderer = ref.read(
    duoSceneRendererFactoryProvider,
  )();
  late final DuoTutorialController _controller;
  final GlobalKey _pageKey = GlobalKey(debugLabel: 'duo-tutorial-page');

  /// Où la page se trouve dans la fenêtre : le pli est donné en coordonnées de
  /// la fenêtre, mesuré après chaque image (comme `FoldAwareSplit`).
  Offset _origin = Offset.zero;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Full screen while the tutorial runs: no status bar, so the foldable
    // iPhone frees its side column too (Renaud, 2026-10-27).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = DuoTutorialController(renderer: _renderer)
      ..addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.update(
      fold: FoldScope.of(context),
      size: MediaQuery.sizeOf(context),
      reduceMotion: MazlMotion.reduced(context),
      dark: Theme.of(context).brightness == Brightness.dark,
      // VoiceOver avance à son rythme : jamais d'étape qui change toute seule.
      autoAdvance: !MediaQuery.accessibleNavigationOf(context),
    );
  }

  void _onChanged() {
    if (_controller.finished) {
      if (_left) return;
      _left = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final done = widget.onFinished;
        if (done != null) {
          done();
        } else {
          leaveDuoTutorial(context, next: widget.next);
        }
      });
      return;
    }
    if (mounted) setState(() {});
  }

  void _measureOrigin(Duration _) {
    if (!mounted) return;
    final box = _pageKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    if (origin != _origin) setState(() => _origin = origin);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context).activeDivision;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Light or dark like the rest of the app (Renaud, 2026-10-27).
    return Theme(
      data: Theme.of(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (fold != null) {
                  SchedulerBinding.instance.addPostFrameCallback(
                    _measureOrigin,
                  );
                }
                final layout = DuoTutorialLayout.resolve(
                  size: constraints.biggest,
                  fold: fold?.shift(-_origin),
                  rtl: rtl,
                );
                return Stack(
                  key: _pageKey,
                  children: [
                    Positioned.fromRect(
                      rect: layout.scene,
                      child: _renderer.build(context),
                    ),
                    Positioned.fromRect(
                      rect: layout.text,
                      child: _TextPanel(
                        controller: _controller,
                        centered: layout.stacked,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.controller, required this.centered});

  final DuoTutorialController controller;
  final bool centered;

  static const _swap = Duration(milliseconds: 360);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final step = controller.step;
    final reduced = MazlMotion.reduced(context);
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: centered
                  ? Alignment.topCenter
                  : AlignmentDirectional.centerStart,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    DuoStepIndicator(
                      count: controller.stepCount,
                      index: controller.index,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: reduced ? MazlMotion.reducedFade : _swap,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: centered
                            ? Alignment.topCenter
                            : AlignmentDirectional.topStart,
                        children: [...previous, ?current],
                      ),
                      child: Column(
                        key: ValueKey(step),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: align,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              step.title(l10n),
                              textAlign: textAlign,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            step.body(l10n),
                            textAlign: textAlign,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DoneMark(visible: step.hasGesture && controller.validated),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Buttons(controller: controller),
        ],
      ),
    );
  }
}

/// « C'est fait », avec la coche qui se trace : la petite célébration d'un
/// geste reconnu. Sa place est réservée : le texte ne bouge pas.
class _DoneMark extends StatelessWidget {
  const _DoneMark({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DuoCheck(),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.duoTutorialDone,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.tekhelet,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.controller});

  final DuoTutorialController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = controller.step.isLast;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        if (!last)
          TextButton(
            onPressed: controller.skip,
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(l10n.duoTutorialSkip),
          ),
        FilledButton(
          onPressed: controller.next,
          child: Text(last ? l10n.duoTutorialStart : l10n.duoTutorialNext),
        ),
      ],
    );
  }
}
