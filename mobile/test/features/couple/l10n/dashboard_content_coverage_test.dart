import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/presentation/features/couple/l10n/couple_feed_service_content.dart';

import '../../../helpers/l10n_helpers.dart';

/// [CoupleService] still carries the dashboard's fixed content in French. The
/// screen translates every item on its stable identifier, so that French is
/// only a fallback. Each item is rebuilt here with a sentinel instead of its
/// French text: if the sentinel reaches the screen, the item has no
/// translation.
const _sentinel = '§fallback§';

void main() {
  final service = CoupleService();
  final milestones = [
    for (final m in service.getMilestones())
      CoupleMilestone(
        id: m.id,
        title: _sentinel,
        description: _sentinel,
        emoji: m.emoji,
        isAchieved: m.isAchieved,
      ),
  ];
  final questions = [
    for (final q in service.getDailyQuestions())
      DailyQuestion(
        id: q.id,
        question: _sentinel,
        category: _sentinel,
        options: q.options?.map((_) => _sentinel).toList(),
      ),
  ];
  final ideas = [
    for (final idea in service.getCoupleActivities())
      {...idea, 'title': _sentinel, 'category': _sentinel},
  ];

  for (final language in AppLanguage.values) {
    final l10n = lookupAppLocalizations(language.locale);

    test(
      '${language.autonym} : chaque étape, question et idée a sa traduction',
      () {
        final texts = <String>[
          for (final m in milestones) ...[
            milestoneTitle(l10n, m),
            milestoneLine(l10n, m),
          ],
          for (final q in questions) ...[
            questionText(l10n, q),
            questionCategory(l10n, q),
            for (var i = 0; i < (q.options?.length ?? 0); i++)
              questionOption(l10n, q, i),
          ],
          for (final idea in ideas) ...[
            ideaTitle(l10n, idea),
            ideaCategory(l10n, idea),
          ],
        ];
        expect(texts, isNotEmpty);
        expect(texts, isNot(contains(_sentinel)));
      },
    );
  }
}
