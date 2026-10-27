import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/couple_failure_label.dart';
import 'concierge_bubble.dart';
import 'concierge_composer.dart';
import 'concierge_controller.dart';
import 'concierge_options.dart';
import 'concierge_request_card.dart';
import 'concierge_steps.dart';
import 'couple_message_view.dart';

/// What the title area of a conversation shows.
enum ConciergeHeader {
  /// The eyebrow, the title, the deadline and the steps.
  full,

  /// The deadline and the steps only (the page's bar already has the title).
  details,
}

/// Which part of a request a [ConciergeConversation] draws. A page that has
/// room for two pages (the book pose) draws [request] on one and [messages]
/// on the other, so that nothing sits on the fold.
enum ConciergePart {
  /// Everything, on one page.
  all,

  /// The title area, the ideas, the buttons, the notes and « Annuler ».
  request,

  /// The bubbles and the field.
  messages,
}

/// The conversation of one request, or the empty one that creates a request
/// with its first message: the bubbles, the ideas to choose from, the buttons
/// that follow, the field. Shared by the right page of the book pose and by
/// the stacked page. It draws [controller]; nothing else is kept here.
class ConciergeConversation extends StatelessWidget {
  const ConciergeConversation({
    super.key,
    required this.controller,
    required this.partnerName,
    this.topPadding = 16,
    this.header = ConciergeHeader.full,
    this.part = ConciergePart.all,
  });

  final ConciergeController controller;
  final String partnerName;

  /// Space above the first line (the status bar on a page without a bar).
  final double topPadding;

  final ConciergeHeader header;
  final ConciergePart part;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final failure = controller.failure;
      if (failure != null && controller.thread == null) {
        return part == ConciergePart.request
            ? const SizedBox.shrink()
            : CoupleMessageView.failure(failure, onRetry: controller.reload);
      }
      final request = controller.thread?.request;
      final body = _Body(
        controller: controller,
        partnerName: partnerName,
        topPadding: topPadding,
        header: header,
        part: part,
      );
      if (part == ConciergePart.request) return body;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          if (request != null && !request.isOpenForMessages)
            _ClosedNote(request: request)
          else
            ConciergeComposer(controller: controller),
        ],
      );
    },
  );
}

extension on ConciergeRequest {
  bool get isOpenForMessages =>
      status != ConciergeStatus.closed && status != ConciergeStatus.cancelled;
}

class _ClosedNote extends StatelessWidget {
  const _ClosedNote({required this.request});

  final ConciergeRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            request.status == ConciergeStatus.cancelled
                ? l10n.coupleConciergeNoteCancelled
                : l10n.coupleConciergeNoteClosed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const ConciergePrivacyNote(),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.partnerName,
    required this.topPadding,
    required this.header,
    required this.part,
  });

  final ConciergeController controller;
  final String partnerName;
  final double topPadding;
  final ConciergeHeader header;
  final ConciergePart part;

  @override
  Widget build(BuildContext context) {
    final request = controller.thread?.request;
    final showRequest = part != ConciergePart.messages;
    final showMessages = part != ConciergePart.request;
    return SingleChildScrollView(
      controller: showMessages ? controller.scroll : null,
      primary: false,
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showRequest) ..._head(context, request),
          if (controller.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (showMessages) ..._bubbles(),
          if (showRequest && request != null) ..._outcome(context, request),
        ],
      ),
    );
  }

  List<Widget> _head(BuildContext context, ConciergeRequest? request) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final full = header == ConciergeHeader.full;
    if (request == null) {
      return [
        if (full) ...[
          SectionLabel(l10n.coupleConciergeNewEyebrow),
          const SizedBox(height: 8),
        ],
        if (controller.messages.isEmpty && part != ConciergePart.request)
          Text(l10n.coupleConciergeNewLine, style: text.bodyLarge),
      ];
    }
    final step = _stepOf(request);
    return [
      if (full) ...[
        SectionLabel(l10n.coupleConciergeThreadEyebrow),
        const SizedBox(height: 8),
        Text(request.title, style: text.headlineSmall),
      ],
      if (conciergeDeadline(context, request.wantedAt)
          case final deadline?) ...[
        const SizedBox(height: 4),
        Text(deadline, style: text.bodySmall),
      ],
      if (step != null) ...[
        const SizedBox(height: 16),
        ConciergeStepsBar(step: step),
      ],
    ];
  }

  List<Widget> _bubbles() => [
    if (controller.messages.isNotEmpty) const SizedBox(height: 20),
    for (final message in controller.messages) ...[
      ConciergeBubble(message: message, partnerName: partnerName),
      const SizedBox(height: 12),
    ],
    if (controller.waiting) const ConciergeTyping(),
  ];

  /// The step a request has reached (the list gives it; a thread derives it).
  static int? _stepOf(ConciergeRequest? request) {
    if (request == null || !request.isOpenForMessages) return null;
    return switch (request.status) {
      ConciergeStatus.booked => 3,
      ConciergeStatus.chosen => 2,
      _ => 1,
    };
  }

  List<Widget> _outcome(BuildContext context, ConciergeRequest request) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final chosen = request.chosenIndex;
    final retained =
        chosen != null && chosen >= 0 && chosen < request.options.length
        ? request.options[chosen]
        : null;
    final note = switch (request.status) {
      ConciergeStatus.fresh => l10n.coupleConciergeNoteFresh,
      ConciergeStatus.chosen => l10n.coupleConciergeNoteChosen,
      ConciergeStatus.booked => l10n.coupleConciergeNoteBooked,
      _ => null,
    };
    return [
      if (request.canChoose) ...[
        const SizedBox(height: 8),
        SectionLabel(l10n.coupleConciergeOptionsLabel),
        const SizedBox(height: 12),
        ConciergeOptions(
          options: request.options,
          picked: controller.picked,
          onPick: controller.select,
        ),
        const SizedBox(height: 16),
        _Decision(controller: controller),
      ] else if (retained != null) ...[
        const SizedBox(height: 8),
        ConciergeOptionTile(
          key: const ValueKey('concierge-retained'),
          option: retained,
          chosen: true,
        ),
      ],
      if (note != null) ...[
        const SizedBox(height: 16),
        Text(note, style: text.bodySmall),
      ],
      if (request.isOpenForMessages) ...[
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const ValueKey('concierge-cancel'),
            onPressed: controller.acting || controller.waiting
                ? null
                : () => _confirmCancel(context),
            child: Text(l10n.coupleConciergeCancel),
          ),
        ),
      ],
    ];
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showMazlSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.coupleConciergeCancelTitle,
            style: Theme.of(sheet).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.coupleConciergeCancelBody,
            style: Theme.of(sheet).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('concierge-cancel-confirm'),
            onPressed: () => Navigator.of(sheet).pop(true),
            child: Text(l10n.coupleConciergeCancelConfirm),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(sheet).pop(false),
            child: Text(l10n.coupleConciergeKeep),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.cancel();
  }
}

/// « Oui, réservez » (off until an idea is ticked) and « Autre idée ».
class _Decision extends StatelessWidget {
  const _Decision({required this.controller});

  final ConciergeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = controller.acting || controller.waiting;
    const padding = EdgeInsets.symmetric(horizontal: 12);
    Widget label(String value) => Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton(
            key: const ValueKey('concierge-book'),
            onPressed: controller.picked == null || busy
                ? null
                : controller.choose,
            style: FilledButton.styleFrom(padding: padding),
            child: label(l10n.coupleConciergeBook),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            key: const ValueKey('concierge-other-idea'),
            onPressed: busy
                ? null
                : () => controller.askOtherIdea(
                    l10n.coupleConciergeOtherIdeaMessage,
                  ),
            style: OutlinedButton.styleFrom(padding: padding),
            child: label(l10n.coupleConciergeOtherIdea),
          ),
        ),
      ],
    );
  }
}

/// Shows [failure] as a floating message (an action that did not go through).
void reportConciergeFailure(BuildContext context, CoupleFailure failure) {
  if (!context.mounted) return;
  showCoupleError(context, failure.label(context.l10n));
}
