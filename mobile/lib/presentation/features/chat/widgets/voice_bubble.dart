import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../chat_providers.dart';
import '../logic/chat_dates.dart';
import '../state/chat_controller.dart';
import 'bubble_style.dart';
import 'waveform.dart';

/// Content of a voice bubble (docs/design/CHAT.md §8): play, waveform that
/// fills as it plays, duration and a speed chip. One shared [VoicePlayer]
/// plays one clip at a time; a bubble follows it only while it is the one loaded.
class VoiceBubbleContent extends ConsumerStatefulWidget {
  const VoiceBubbleContent({super.key, required this.voice, required this.mine});

  static const speeds = [1.0, 1.5, 2.0];

  final VoiceNote voice;
  final bool mine;

  /// « 1× », « 1,5× », « 2× » (decimal comma).
  static String speedLabel(double speed) => '${speed == speed.roundToDouble() ? speed.toInt() : speed.toString().replaceAll('.', ',')}×';

  @override
  ConsumerState<VoiceBubbleContent> createState() => _VoiceBubbleContentState();
}

class _VoiceBubbleContentState extends ConsumerState<VoiceBubbleContent> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  double _speed = 1;
  Duration? _position;
  bool _playing = false;

  bool get _current => ref.read(voicePlayerProvider).currentUrl == widget.voice.url;

  @override
  void initState() {
    super.initState();
    final player = ref.read(voicePlayerProvider);
    _subscriptions.add(player.position.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subscriptions.add(player.playing.listen((p) {
      if (mounted) setState(() => _playing = p);
    }));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = ref.read(voicePlayerProvider);
    if (_current && _playing) {
      await player.pause();
    } else {
      await player.play(widget.voice.url, speed: _speed);
    }
  }

  void _cycleSpeed() {
    final next = VoiceBubbleContent.speeds[(VoiceBubbleContent.speeds.indexOf(_speed) + 1) % VoiceBubbleContent.speeds.length];
    setState(() => _speed = next);
    if (_current) ref.read(voicePlayerProvider).setSpeed(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = BubbleColors.of(context, mine: widget.mine);
    final total = Duration(milliseconds: widget.voice.durationMs);
    final isCurrent = _current;
    final playing = isCurrent && _playing;
    final position = isCurrent ? (_position ?? Duration.zero) : Duration.zero;
    final progress = total.inMilliseconds == 0 ? 0.0 : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final shown = playing || (isCurrent && position > Duration.zero) ? position : total;
    final buttonFill = widget.mine ? scheme.onPrimary : scheme.onSurface;
    final buttonIcon = widget.mine ? scheme.primary : scheme.surface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: playing ? 'Mettre en pause' : 'Lire le message vocal',
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: buttonFill, shape: BoxShape.circle),
              child: Icon(playing ? LucideIcons.pause : LucideIcons.play, size: 16, color: buttonIcon),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Waveform(values: widget.voice.waveform, progress: progress, color: colors.text),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  minutesSeconds(shown),
                  style: TextStyle(
                    fontFamily: AppTypography.monoFamily,
                    fontSize: 12,
                    color: colors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _cycleSpeed,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: colors.inset, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      VoiceBubbleContent.speedLabel(_speed),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.text),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
