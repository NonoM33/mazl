import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';

/// The wording of the monthly check-in, in the member's language.
extension CheckinThemeLabel on CheckinTheme {
  String label(AppLocalizations l10n) => switch (this) {
    CheckinTheme.talk => l10n.coupleCheckinTalk,
    CheckinTheme.time => l10n.coupleCheckinTime,
    CheckinTheme.close => l10n.coupleCheckinClose,
  };
}

/// The one sentence of attention under the summary: the theme where the two
/// notes are lowest, moderated by how it moved since the month before
/// (`trend`, `null` on a first check-in).
String checkinAttentionLine(
  AppLocalizations l10n,
  CheckinSummary summary,
) => switch ((summary.lowest, summary.trend)) {
  (CheckinTheme.talk, CheckinTrend.up) => l10n.coupleCheckinAttentionTalkUp,
  (CheckinTheme.talk, CheckinTrend.down) => l10n.coupleCheckinAttentionTalkDown,
  (CheckinTheme.talk, CheckinTrend.same) => l10n.coupleCheckinAttentionTalkSame,
  (CheckinTheme.talk, null) => l10n.coupleCheckinAttentionTalkNone,
  (CheckinTheme.time, CheckinTrend.up) => l10n.coupleCheckinAttentionTimeUp,
  (CheckinTheme.time, CheckinTrend.down) => l10n.coupleCheckinAttentionTimeDown,
  (CheckinTheme.time, CheckinTrend.same) => l10n.coupleCheckinAttentionTimeSame,
  (CheckinTheme.time, null) => l10n.coupleCheckinAttentionTimeNone,
  (CheckinTheme.close, CheckinTrend.up) => l10n.coupleCheckinAttentionCloseUp,
  (CheckinTheme.close, CheckinTrend.down) =>
    l10n.coupleCheckinAttentionCloseDown,
  (CheckinTheme.close, CheckinTrend.same) =>
    l10n.coupleCheckinAttentionCloseSame,
  (CheckinTheme.close, null) => l10n.coupleCheckinAttentionCloseNone,
};
