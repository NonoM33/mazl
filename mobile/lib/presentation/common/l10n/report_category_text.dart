import '../../../core/models/report_category.dart';
import '../../../l10n/l10n.dart';

/// The words of a report category, in the member's language.
extension ReportCategoryText on ReportCategory {
  String label(AppLocalizations l10n) => switch (id) {
    'fake_profile' => l10n.safetyCategoryFakeProfile,
    'inappropriate_photos' => l10n.safetyCategoryInappropriatePhotos,
    'harassment' => l10n.safetyCategoryHarassment,
    'spam' => l10n.safetyCategorySpam,
    'underage' => l10n.safetyCategoryUnderage,
    'offline_behavior' => l10n.safetyCategoryOfflineBehavior,
    _ => l10n.safetyCategoryOther,
  };

  String description(AppLocalizations l10n) => switch (id) {
    'fake_profile' => l10n.safetyCategoryFakeProfileHint,
    'inappropriate_photos' => l10n.safetyCategoryInappropriatePhotosHint,
    'harassment' => l10n.safetyCategoryHarassmentHint,
    'spam' => l10n.safetyCategorySpamHint,
    'underage' => l10n.safetyCategoryUnderageHint,
    'offline_behavior' => l10n.safetyCategoryOfflineBehaviorHint,
    _ => l10n.safetyCategoryOtherHint,
  };
}
