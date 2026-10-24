import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';

/// The couple dashboard's fixed content (milestones, daily questions, ideas)
/// is written in French by [CoupleService]. It is translated here on the
/// stable identifiers the service gives it; an identifier this file does not
/// know keeps the service's own text.

String milestoneTitle(AppLocalizations l10n, CoupleMilestone milestone) =>
    switch (milestone.id) {
      'first_week' => l10n.coupleFeedMilestoneFirstWeekTitle,
      'first_month' => l10n.coupleFeedMilestoneFirstMonthTitle,
      'three_months' => l10n.coupleFeedMilestoneThreeMonthsTitle,
      'six_months' => l10n.coupleFeedMilestoneSixMonthsTitle,
      'first_year' => l10n.coupleFeedMilestoneFirstYearTitle,
      _ => milestone.title,
    };

String milestoneLine(AppLocalizations l10n, CoupleMilestone milestone) =>
    switch (milestone.id) {
      'first_week' => l10n.coupleFeedMilestoneFirstWeekLine,
      'first_month' => l10n.coupleFeedMilestoneFirstMonthLine,
      'three_months' => l10n.coupleFeedMilestoneThreeMonthsLine,
      'six_months' => l10n.coupleFeedMilestoneSixMonthsLine,
      'first_year' => l10n.coupleFeedMilestoneFirstYearLine,
      _ => milestone.description,
    };

String questionText(AppLocalizations l10n, DailyQuestion question) =>
    switch (question.id) {
      '1' => l10n.coupleFeedQuestion1,
      '2' => l10n.coupleFeedQuestion2,
      '3' => l10n.coupleFeedQuestion3,
      '4' => l10n.coupleFeedQuestion4,
      '5' => l10n.coupleFeedQuestion5,
      _ => question.question,
    };

String questionCategory(AppLocalizations l10n, DailyQuestion question) =>
    switch (question.id) {
      '1' => l10n.coupleFeedQuestion1Category,
      '2' => l10n.coupleFeedQuestion2Category,
      '3' => l10n.coupleFeedQuestion3Category,
      '4' => l10n.coupleFeedQuestion4Category,
      '5' => l10n.coupleFeedQuestion5Category,
      _ => question.category,
    };

/// The [index]th ready-made answer of a question.
String questionOption(
  AppLocalizations l10n,
  DailyQuestion question,
  int index,
) {
  final own = question.options![index];
  if (question.id != '4') return own;
  return switch (index) {
    0 => l10n.coupleFeedQuestion4Option1,
    1 => l10n.coupleFeedQuestion4Option2,
    2 => l10n.coupleFeedQuestion4Option3,
    3 => l10n.coupleFeedQuestion4Option4,
    _ => own,
  };
}

/// An idea of the « activities for two » strip, told apart by its icon name.
String ideaTitle(AppLocalizations l10n, Map<String, dynamic> idea) =>
    switch (idea['icon']) {
      'utensils' => l10n.coupleFeedIdeaShabbatCookingTitle,
      'book' => l10n.coupleFeedIdeaTorahTitle,
      'heart' => l10n.coupleFeedIdeaDateNightTitle,
      'dumbbell' => l10n.coupleFeedIdeaSportTitle,
      'hand-heart' => l10n.coupleFeedIdeaChesedTitle,
      'plane' => l10n.coupleFeedCategoryTravel,
      _ => '${idea['title']}',
    };

String ideaCategory(AppLocalizations l10n, Map<String, dynamic> idea) =>
    switch (idea['icon']) {
      'utensils' => l10n.coupleFeedIdeaShabbatCookingCategory,
      'book' => l10n.coupleFeedCategorySpiritual,
      'heart' => l10n.coupleFeedIdeaDateNightCategory,
      'dumbbell' => l10n.coupleFeedCategoryWellness,
      'hand-heart' => l10n.coupleFeedIdeaChesedCategory,
      'plane' => l10n.coupleFeedIdeaTravelCategory,
      _ => '${idea['category']}',
    };
