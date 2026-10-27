import 'package:flutter/widgets.dart';

import '../../../../core/motion/mazl_motion.dart';

/// A number whose changed digits roll vertically to their new value, like a
/// mechanical counter (docs/design/MOUVEMENT.md: one reward per gesture, so
/// the roll is the only thing that moves).
///
/// Shown alone ([sentence] null) or inside a translated [sentence] that
/// contains the number: the sentence stays one piece of text, only the digit
/// run equal to [value] is replaced by the rolling digits while it moves.
/// A sentence without that digit run (a plural written in words) is shown as
/// it is. The first value never rolls; under reduced motion a new value
/// appears at once.
class RollingCount extends StatefulWidget {
  const RollingCount({
    super.key,
    required this.value,
    this.sentence,
    this.style,
    this.textAlign,
    this.markup,
  }) : assert(value >= 0, 'a count cannot be negative');

  final int value;

  /// The whole translated text around the number, e.g. « Voir les 12 autres ».
  final String? sentence;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Dresses the pieces of [sentence] around the number (a brand name in
  /// bold, for instance). Defaults to the plain text.
  final InlineSpan Function(String text)? markup;

  @override
  State<RollingCount> createState() => _RollingCountState();
}

class _RollingCountState extends State<RollingCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: MazlMotion.rollingCount)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) setState(() {});
        });

  late int _from = widget.value;
  bool _up = true;

  @override
  void didUpdateWidget(RollingCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    if (MazlMotion.reduced(context)) {
      _controller.stop();
      return;
    }
    _from = oldWidget.value;
    _up = widget.value > oldWidget.value;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _resolvedStyle(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    return base.copyWith(
      fontFeatures: [...?base.fontFeatures, const FontFeature.tabularFigures()],
    );
  }

  /// The sentence (or bare number) as plain text, used at rest.
  Widget _still(TextStyle style) {
    final sentence = widget.sentence;
    final markup = widget.markup;
    if (sentence == null || markup == null) {
      return Text(
        sentence ?? '${widget.value}',
        style: style,
        textAlign: widget.textAlign,
      );
    }
    final at = _numberIn(sentence);
    return Text.rich(
      TextSpan(
        style: style,
        children: at == null
            ? [markup(sentence)]
            : [
                markup(sentence.substring(0, at.start)),
                TextSpan(text: sentence.substring(at.start, at.end)),
                markup(sentence.substring(at.end)),
              ],
      ),
      textAlign: widget.textAlign,
    );
  }

  /// Where the digit run equal to the value sits in the sentence, if it does.
  Match? _numberIn(String sentence) =>
      RegExp('(?<!\\d)${widget.value}(?!\\d)').firstMatch(sentence);

  InlineSpan _piece(String text) =>
      widget.markup?.call(text) ?? TextSpan(text: text);

  @override
  Widget build(BuildContext context) {
    final style = _resolvedStyle(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.isAnimating) return _still(style);
        final sentence = widget.sentence;
        if (sentence == null) {
          return _semantic('${widget.value}', _rolling(context, style, true));
        }
        final at = _numberIn(sentence);
        if (at == null) return _still(style);
        return _semantic(
          sentence,
          Text.rich(
            TextSpan(
              style: style,
              children: [
                _piece(sentence.substring(0, at.start)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  style: style,
                  child: _rolling(context, style, false),
                ),
                _piece(sentence.substring(at.end)),
              ],
            ),
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }

  /// A screen reader reads the final text once, never the digits on the way.
  Widget _semantic(String label, Widget child) =>
      Semantics(label: label, excludeSemantics: true, child: child);

  /// The digits in motion. Numbers read left to right whatever the language.
  /// [scaled]: the text scale is applied here; inside a sentence the text
  /// span scales its inline widgets itself.
  Widget _rolling(BuildContext context, TextStyle style, bool scaled) {
    final scaler = scaled
        ? MediaQuery.textScalerOf(context)
        : TextScaler.noScaling;
    final probe = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final cell = probe.size;
    probe.dispose();

    final eased = MazlMotion.rollingCountCurve.transform(_controller.value);
    final before = '$_from';
    final after = '${widget.value}';
    final length = before.length > after.length ? before.length : after.length;

    final cells = <Widget>[
      for (var fromRight = length - 1; fromRight >= 0; fromRight--)
        _cell(
          style: style,
          scaler: scaler,
          size: cell,
          column: fromRight,
          out: fromRight < before.length
              ? before[before.length - 1 - fromRight]
              : null,
          into: fromRight < after.length
              ? after[after.length - 1 - fromRight]
              : null,
          progress: eased,
        ),
    ];
    final row = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(mainAxisSize: MainAxisSize.min, children: cells),
    );
    return row;
  }

  Widget _cell({
    required TextStyle style,
    required TextScaler scaler,
    required Size size,
    required int column,
    required String? out,
    required String? into,
    required double progress,
  }) {
    // Moved at paint time only, so the cell keeps one steady text baseline.
    Widget glyph(String digit, Key key, double top) => Transform.translate(
      key: key,
      offset: Offset(0, top),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Text(digit, style: style, textScaler: scaler, softWrap: false),
      ),
    );

    if (out == into) {
      return SizedBox(
        key: ValueKey('rolling-still-$column'),
        width: size.width,
        height: size.height,
        child: Text(into!, style: style, textScaler: scaler, softWrap: false),
      );
    }
    final width = switch ((out, into)) {
      (_?, _?) => size.width,
      (null, _) => size.width * progress,
      _ => size.width * (1 - progress),
    };
    final direction = _up ? -1.0 : 1.0;
    return SizedBox(
      width: width,
      height: size.height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (out != null)
              glyph(
                out,
                ValueKey('rolling-out-$column'),
                direction * size.height * progress,
              ),
            if (into != null)
              glyph(
                into,
                ValueKey('rolling-in-$column'),
                -direction * size.height * (1 - progress),
              ),
          ],
        ),
      ),
    );
  }
}
