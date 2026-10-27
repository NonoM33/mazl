import 'package:flutter/material.dart';

import 'read_receipts_switch.dart';

/// The mazl+ related privacy rows of the settings screen: the read receipts
/// switch (every member), and the discreet mode (docs/premium/MONETISATION.md
/// §3, §4). Each row is its own widget; a row is added here with one line.
class PlusPrivacySection extends StatelessWidget {
  const PlusPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [ReadReceiptsSwitch()]);
  }
}
