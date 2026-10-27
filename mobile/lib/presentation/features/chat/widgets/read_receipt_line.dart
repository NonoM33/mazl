import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../logic/chat_dates.dart';

/// « Lu à 21:04 » under the last message I sent, when the server gave it a
/// `read_at` (mazl+ sender, reader with receipts on: docs/premium/MONETISATION.md
/// §4). The time is in the member's language and local time zone.
class ReadReceiptLine extends StatelessWidget {
  const ReadReceiptLine({super.key, required this.readAt});

  final DateTime readAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        l10n.chatSeenAt(clock(l10n, readAt)),
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
