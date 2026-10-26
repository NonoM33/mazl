import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/fold_aware_split.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/quiet_display.dart';
import '../../../../core/services/rest_display_content.dart';
import '../../../../core/services/screen_keeper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/shabbat_display_labels.dart';
import '../shabbat_place.dart';
import '../widgets/shabbat_display_panels.dart';

/// Affichage Shabbat : le téléphone posé comme une tente (iPhone Duo fermé et
/// tourné, écran extérieur face à la pièce), ou posé à plat, affiche l'heure
/// en grand, l'allumage et la havdala du lieu du membre, la parasha, et
/// s'adapte à Hanoucca, à l'Omer et aux fêtes.
///
/// PRÉCAUTION : l'affichage se lance AVANT Shabbat ; il ne demande plus AUCUNE
/// interaction ensuite. Aucun bouton, aucune bascule, aucun geste ne le
/// touche : l'écran reste allumé (`ScreenKeeper`), rien de l'app n'allume, ne
/// sonne ni ne vibre (`QuietDisplay`), le retour par balayage est refusé. La
/// seule sortie est un appui long de DEUX secondes, n'importe où sur l'écran,
/// pensée pour qu'un effleurement, un chat ou un enfant ne la déclenche pas.
/// L'indication s'affiche dix secondes au lancement, puis disparaît (VoiceOver
/// la lit toujours).
///
/// Le contenu vient de [RestDisplayResolver] ; l'horloge est injectable.
class ShabbatDisplayScreen extends StatefulWidget {
  const ShabbatDisplayScreen({
    super.key,
    this.apiService,
    this.clock,
    this.place,
    this.keeper = const WakelockScreenKeeper(),
    this.quiet,
    this.onExit,
  });

  /// Injecté par les tests ; l'app utilise le vrai service.
  final ApiService? apiService;

  /// L'heure qu'il est ; injectée par les tests.
  final DateTime Function()? clock;

  /// Le lieu, quand l'appelant le connaît déjà ; sinon il est lu sur le profil.
  final ShabbatPlace? place;

  final ScreenKeeper keeper;

  /// Celui de l'app par défaut.
  final QuietDisplay? quiet;

  /// Ce qui se passe à la sortie ; par défaut, retour à l'écran précédent.
  final VoidCallback? onExit;

  /// Combien de temps il faut appuyer pour quitter.
  static const exitHold = Duration(seconds: 2);

  /// Combien de temps l'indication de sortie reste visible.
  static const hintDuration = Duration(seconds: 10);

  @override
  State<ShabbatDisplayScreen> createState() => _ShabbatDisplayScreenState();
}

class _ShabbatDisplayScreenState extends State<ShabbatDisplayScreen> {
  static const _refresh = Duration(seconds: 15);

  final RestDisplayResolver _resolver = RestDisplayResolver();
  Timer? _refreshTimer;
  Timer? _hintTimer;

  ShabbatPlace? _place;
  RestDisplayContent? _content;
  DateTime _now = DateTime.now();
  bool _hintVisible = true;

  QuietDisplay get _quiet => widget.quiet ?? QuietDisplay.instance;

  @override
  void initState() {
    super.initState();
    _quiet.enter();
    unawaited(_guarded(widget.keeper.hold));
    _hintTimer = Timer(ShabbatDisplayScreen.hintDuration, () {
      if (mounted) setState(() => _hintVisible = false);
    });
    _refreshTimer = Timer.periodic(_refresh, (_) => _update());
    _now = _readClock();
    final place = widget.place;
    if (place != null) {
      _place = place;
      _content = _resolve(place);
    } else {
      unawaited(_loadPlace());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _hintTimer?.cancel();
    _quiet.leave();
    unawaited(_guarded(widget.keeper.release));
    super.dispose();
  }

  DateTime _readClock() => (widget.clock ?? DateTime.now)();

  /// A phone that refuses to stay lit (or to let go) must not close the
  /// display: the error is logged and the display goes on.
  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      debugPrint('$error\n$stackTrace');
    }
  }

  Future<void> _loadPlace() async {
    final place = await loadShabbatPlace(widget.apiService ?? ApiService());
    if (!mounted) return;
    setState(() {
      _place = place;
      _now = _readClock();
      _content = _resolve(place);
    });
  }

  RestDisplayContent _resolve(ShabbatPlace place) =>
      _resolver.resolve(now: _now, location: place.location);

  /// Called twice a minute: the screen is redrawn when the minute changes.
  void _update() {
    final now = _readClock();
    final sameMinute =
        now.hour == _now.hour &&
        now.minute == _now.minute &&
        now.day == _now.day;
    if (sameMinute || !mounted) return;
    final place = _place;
    setState(() {
      _now = now;
      if (place != null) _content = _resolve(place);
    });
  }

  void _exit() {
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = _content;
    final texts = content == null
        ? null
        : ShabbatDisplayTexts(l10n, content, _now);
    final place = _place;
    final clock = DateFormat.Hm(l10n.localeName).format(_now);
    final header = ShabbatDisplayHeader(
      clock: clock,
      eyebrow: texts?.eyebrow,
      title: texts?.title ?? '',
    );
    final facts = ShabbatDisplayFacts(
      facts: texts?.facts ?? const [],
      restName: texts?.restName,
      hanukkahNight: content?.moment == RestDisplayMoment.hanukkah
          ? content?.hanukkahNight
          : null,
      place: place == null
          ? null
          : l10n.settingsShabbatBasedOn(
              place.isDefault
                  ? l10n.settingsShabbatDefaultPlace
                  : place.location.name,
            ),
    );
    final hint = _hintVisible
        ? Text(
            l10n.shabbatDisplayExitHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: 13,
              color: AppColors.shabbatDisplayMuted,
            ),
          )
        : const SizedBox.shrink();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.shabbatDisplayBackground,
        body: Semantics(
          container: true,
          hint: l10n.shabbatDisplayExitHint,
          onLongPress: _exit,
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(
                      duration: ShabbatDisplayScreen.exitHold,
                    ),
                    (recognizer) => recognizer.onLongPress = _exit,
                  ),
            },
            child: SafeArea(
              minimum: const EdgeInsets.all(20),
              child: FoldAwareSplit(
                lead: _Pane(hint: hint, child: header),
                action: _Layout(header: header, facts: facts, hint: hint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A part of the display, centred and shrunk to fit its room: the display
/// never overflows, whatever the pose or the text size. [hint] sits at its
/// foot, in the room kept for it whether it is shown or not, so that nothing
/// moves when it goes.
class _Pane extends StatelessWidget {
  const _Pane({required this.child, this.hint});

  final Widget child;
  final Widget? hint;

  static const _hintRoom = 26.0;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    if (hint == null) {
      return Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          bottom: _hintRoom,
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FittedBox(fit: BoxFit.scaleDown, child: hint),
        ),
      ],
    );
  }
}

/// The whole display: side by side where the room is wide and low (the tent),
/// stacked elsewhere. When the fold splits the page, the header is already
/// shown above it or beside it: only the facts remain.
class _Layout extends StatelessWidget {
  const _Layout({
    required this.header,
    required this.facts,
    required this.hint,
  });

  final Widget header;
  final Widget facts;
  final Widget hint;

  /// Wide enough, compared with its height, to put the two parts side by side.
  static const _sideBySideRatio = 1.25;

  @override
  Widget build(BuildContext context) {
    if (FoldAwareSplit.axisOf(context) != null) return _Pane(child: facts);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth / box.maxHeight >= _sideBySideRatio;
        if (!wide) {
          return _Pane(
            hint: hint,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [header, const SizedBox(height: 28), facts],
            ),
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _Pane(hint: hint, child: header),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _Pane(child: facts)),
          ],
        );
      },
    );
  }
}
