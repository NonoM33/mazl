import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/premium/boost_schedule_api.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/boost_schedule_text.dart';
import '../logic/boost_moment.dart';

/// « Meilleur moment : samedi 21 h, après Shabbat » and the button that
/// schedules the Boost for then (docs/premium/MONETISATION.md §8).
///
/// The server measures the busy hours, spends the Boost at the scheduled time
/// and sends the push. This card only asks, and shows what the server holds.
class BoostBestTimeCard extends StatefulWidget {
  const BoostBestTimeCard({
    super.key,
    required this.onBoostsExhausted,
    this.api,
  });

  /// The server says no Boost is left: opens the packs sheet. True when the
  /// member bought some, then the scheduling is asked again.
  final Future<bool> Function() onBoostsExhausted;

  /// Injected by tests; the app uses the real client.
  final BoostScheduleApi? api;

  @override
  State<BoostBestTimeCard> createState() => _BoostBestTimeCardState();
}

class _BoostBestTimeCardState extends State<BoostBestTimeCard> {
  late final BoostScheduleApi _api = widget.api ?? HttpBoostScheduleApi();

  BoostScheduleInfo? _info;
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final info = await _api.bestTime();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } on BoostScheduleException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _schedule(DateTime at) async {
    setState(() => _busy = true);
    try {
      await _scheduleAsking(at);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleAsking(
    DateTime at, {
    bool afterPurchase = false,
  }) async {
    try {
      final held = await _api.schedule(at);
      if (!mounted) return;
      final current = _info;
      setState(
        () => _info = BoostScheduleInfo(
          city: current?.city,
          bestTime: current?.bestTime,
          scheduledAt: held,
        ),
      );
      _say(context.l10n.boostScheduledDone);
    } on BoostScheduleException catch (e) {
      if (!mounted) return;
      if (e.kind == BoostScheduleErrorKind.boostsExhausted && !afterPurchase) {
        final bought = await widget.onBoostsExhausted();
        if (bought && mounted) {
          await _scheduleAsking(at, afterPurchase: true);
        }
        return;
      }
      final text = boostScheduleErrorText(context.l10n, e.kind);
      if (text != null) _say(text);
      // The server may hold another schedule, or have changed its best time.
      if (e.kind == BoostScheduleErrorKind.alreadyScheduled ||
          e.kind == BoostScheduleErrorKind.invalidTime) {
        await _load();
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await _api.cancel();
      if (!mounted) return;
      final current = _info;
      setState(
        () => _info = BoostScheduleInfo(
          city: current?.city,
          bestTime: current?.bestTime,
          scheduledAt: null,
        ),
      );
      _say(context.l10n.boostScheduleCancelled);
    } on BoostScheduleException {
      if (!mounted) return;
      _say(context.l10n.boostScheduleCancelFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _failed
            ? _failure(context)
            : _content(context),
      ),
    );
  }

  Widget _failure(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Icon(
          LucideIcons.calendarClock,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(l10n.boostBestTimeLoadFailed)),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _load,
          child: Text(l10n.commonRetry),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final info = _info!;
    final scheduled = info.scheduledAt;
    final best = info.bestTime;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);

    final Widget body;
    if (scheduled != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            context,
            l10n.boostScheduledFor(boostMomentText(l10n, scheduled)),
          ),
          const SizedBox(height: 4),
          Text(l10n.boostScheduleNote, style: muted),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: _busy ? null : _cancel,
              child: Text(l10n.boostScheduleCancel),
            ),
          ),
        ],
      );
    } else if (best != null) {
      final moment = boostMomentText(l10n, best.startsAt);
      final line = isAfterShabbat(best.startsAt)
          ? l10n.boostBestTimeLineAfterShabbat(moment)
          : l10n.boostBestTimeLine(moment);
      final city = info.city;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, line),
          const SizedBox(height: 4),
          Text(
            city == null
                ? l10n.boostBestTimeBasisNoCity
                : l10n.boostBestTimeBasis(city),
            style: muted,
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: _busy ? null : () => _schedule(best.startsAt),
            child: Text(l10n.boostScheduleAction),
          ),
          const SizedBox(height: 8),
          Text(l10n.boostScheduleNote, style: muted),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, l10n.boostBestTimeTitle),
          const SizedBox(height: 4),
          Text(l10n.boostBestTimeNoData, style: muted),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(LucideIcons.calendarClock, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: body),
      ],
    );
  }

  Widget _heading(BuildContext context, String text) => Semantics(
    header: true,
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}
