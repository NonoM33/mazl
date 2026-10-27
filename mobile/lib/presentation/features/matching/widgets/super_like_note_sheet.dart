import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/layout/fold_state.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// The most characters a Super Like word may have (the server refuses more).
const int kSuperLikeNoteMax = 140;

/// What the member decided in the Super Like word sheet.
sealed class SuperLikeNoteChoice {
  const SuperLikeNoteChoice();
}

/// Send the Super Like with this word (already trimmed, 1 to 140 characters).
class SendWithNote extends SuperLikeNoteChoice {
  const SendWithNote(this.note);

  final String note;
}

/// Send the Super Like without a word.
class SendWithoutNote extends SuperLikeNoteChoice {
  const SendWithoutNote();
}

/// Asks the member for the optional word of a Super Like. Resolves to what
/// they chose, or null when they cancel (close the sheet, tap outside or
/// « Annuler »): the Super Like is then not sent.
///
/// Held like a laptop (fold across the screen) the keyboard would fill the
/// half below the fold, so the form is a panel at the TOP of the screen, above
/// the fold, and the keyboard stays below it. Anywhere else it is a bottom
/// sheet, kept on one side of a vertical fold.
Future<SuperLikeNoteChoice?> showSuperLikeNoteSheet(BuildContext context) {
  final division = FoldScope.of(context).activeDivision;
  final acrossScreen = division != null && division.width > division.height;
  if (acrossScreen) {
    return showDialog<SuperLikeNoteChoice>(
      context: context,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SuperLikeNoteForm(
            stacked: false,
            onChoice: (choice) => Navigator.pop(dialogContext, choice),
          ),
        ),
      ),
    );
  }
  return showMazlSheet<SuperLikeNoteChoice>(
    context,
    isScrollControlled: true,
    builder: (sheetContext) => FoldSafeActions(
      child: SuperLikeNoteForm(
        stacked: true,
        onChoice: (choice) => Navigator.pop(sheetContext, choice),
      ),
    ),
  );
}

/// The form: a title, the field with its counter, and three ways out. The
/// word is optional: « Envoyer sans mot » is always there, at the same weight
/// as the other buttons.
class SuperLikeNoteForm extends StatefulWidget {
  const SuperLikeNoteForm({
    super.key,
    required this.onChoice,
    this.stacked = true,
  });

  final ValueChanged<SuperLikeNoteChoice?> onChoice;

  /// Buttons one under another (a sheet); otherwise side by side (the panel
  /// above the fold, which has little height).
  final bool stacked;

  @override
  State<SuperLikeNoteForm> createState() => _SuperLikeNoteFormState();
}

class _SuperLikeNoteFormState extends State<SuperLikeNoteForm> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _note => _controller.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // What the window leaves above the keyboard: a short one (the foldable
    // iPhone sideways, the keyboard up) gets the buttons side by side and
    // loses the explanation, so the field and the choices stay in view.
    final media = MediaQuery.of(context);
    final room =
        media.size.height - media.viewInsets.bottom - media.padding.vertical;
    final stacked = widget.stacked && room >= 520;
    final showBody = room >= 380;
    final withNote = FilledButton(
      key: const ValueKey('super-like-note-send'),
      onPressed: _note.isEmpty
          ? null
          : () => widget.onChoice(SendWithNote(_note)),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(l10n.superLikeNoteSend),
    );
    final without = OutlinedButton(
      key: const ValueKey('super-like-note-without'),
      onPressed: () => widget.onChoice(const SendWithoutNote()),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(l10n.superLikeNoteSendWithout),
    );
    final cancel = TextButton(
      key: const ValueKey('super-like-note-cancel'),
      onPressed: () => widget.onChoice(null),
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(l10n.commonCancel),
    );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.superLikeNoteTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (showBody) ...[
            const SizedBox(height: 6),
            Text(
              l10n.superLikeNoteBody,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
          SizedBox(height: stacked ? 12 : 8),
          TextField(
            key: const ValueKey('super-like-note-field'),
            controller: _controller,
            minLines: stacked ? 3 : 2,
            maxLines: stacked ? 4 : 3,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(kSuperLikeNoteMax),
            ],
            decoration: InputDecoration(
              hintText: l10n.superLikeNoteHint,
              // Our own counter: the field's would not be translated.
              counterText: '',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: stacked ? 12 : 4),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                l10n.superLikeNoteCounter(
                  _controller.text.length,
                  kSuperLikeNoteMax,
                ),
                key: const ValueKey('super-like-note-counter'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          if (stacked) ...[
            withNote,
            const SizedBox(height: 8),
            without,
            const SizedBox(height: 4),
            cancel,
          ] else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [cancel, without, withNote],
            ),
        ],
      ),
    );
  }
}
