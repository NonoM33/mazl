import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';

/// The most the server takes for an answer (docs/couple/ESPACE-COUPLE.md §5).
const int kQuestionAnswerMaxLength = 2000;

/// The counter only shows when the end is in sight: from 90 % of the limit.
const int kQuestionCounterFrom = 1800;

/// The field to answer the question of the day and the button that sends it.
/// The text lives in [controller], owned by the screen: it survives the fold
/// and an unsuccessful send.
class QuestionComposer extends StatelessWidget {
  const QuestionComposer({
    super.key,
    required this.controller,
    required this.sendLabel,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final String sendLabel;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.coupleQuestionYourAnswer,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: TextField(
            controller: controller,
            enabled: !sending,
            minLines: 5,
            maxLines: 10,
            maxLength: kQuestionAnswerMaxLength,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(kQuestionAnswerMaxLength),
            ],
            decoration: InputDecoration(
              hintText: l10n.coupleQuestionHint,
              semanticCounterText: '',
            ),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => currentLength < kQuestionCounterFrom
                ? null
                : Text(
                    l10n.coupleQuestionCounter(
                      currentLength,
                      maxLength ?? kQuestionAnswerMaxLength,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Semantics(
            label: sending ? l10n.coupleQuestionSending : null,
            child: ElevatedButton(
              onPressed: value.text.trim().isEmpty || sending ? null : onSend,
              child: sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.surface,
                      ),
                    )
                  : Text(sendLabel),
            ),
          ),
        ),
      ],
    );
  }
}
