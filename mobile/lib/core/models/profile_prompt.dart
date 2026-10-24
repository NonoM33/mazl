import '_json_parsing.dart';

/// Prompt template model
class PromptTemplate {
  final String id;
  final String text;
  final String? category;

  PromptTemplate({
    required this.id,
    required this.text,
    this.category,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String?,
    );
  }

  /// Default prompts list (used if API unavailable). A question is read in
  /// the member's language through its id (see [PromptQuestion]): the `text`
  /// is only the fallback of an id the app does not know, so here it is the
  /// id itself, never a sentence in one language.
  static List<Map<String, String>> get defaultPrompts => [
    for (final question in PromptQuestion.values)
      {'id': question.id, 'text': question.id, 'category': question.category.id},
  ];
}

/// Les familles de questions, dans l'ordre d'affichage.
enum PromptCategory {
  personality('personality'),
  lifestyle('lifestyle'),
  jewish('jewish'),
  conversation('conversation');

  const PromptCategory(this.id);

  final String id;

  static PromptCategory? fromId(String? id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// Les questions du catalogue, par identifiant stable.
enum PromptQuestion {
  perfectSunday('perfect_sunday', PromptCategory.personality),
  funFact('fun_fact', PromptCategory.personality),
  lifeGoal('life_goal', PromptCategory.personality),
  petPeeve('pet_peeve', PromptCategory.personality),
  proudOf('proud_of', PromptCategory.personality),
  lookingFor('looking_for', PromptCategory.personality),
  idealVacation('ideal_vacation', PromptCategory.lifestyle),
  favoriteFood('favorite_food', PromptCategory.lifestyle),
  hiddenTalent('hidden_talent', PromptCategory.lifestyle),
  bingeWatching('binge_watching', PromptCategory.lifestyle),
  shabbatIdeal('shabbat_ideal', PromptCategory.jewish),
  familyTradition('family_tradition', PromptCategory.jewish),
  favoriteHoliday('favorite_holiday', PromptCategory.jewish),
  fridayNight('friday_night', PromptCategory.jewish),
  israelMemory('israel_memory', PromptCategory.jewish),
  jewishValue('jewish_value', PromptCategory.jewish),
  debateMe('debate_me', PromptCategory.conversation),
  teachMe('teach_me', PromptCategory.conversation),
  togetherWeCould('together_we_could', PromptCategory.conversation),
  firstDate('first_date', PromptCategory.conversation);

  const PromptQuestion(this.id, this.category);

  final String id;
  final PromptCategory category;

  /// `null` pour un identifiant que cette version de l'app ne connaît pas.
  static PromptQuestion? fromId(String? id) {
    for (final question in values) {
      if (question.id == id) return question;
    }
    return null;
  }
}

/// Profile prompt model
class ProfilePrompt {
  final int id;
  final String promptId;
  final String promptText;
  final String answer;
  final int position;

  ProfilePrompt({
    required this.id,
    required this.promptId,
    required this.promptText,
    required this.answer,
    required this.position,
  });

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) {
    return ProfilePrompt(
      id: parseIntSafe(json['id']) ?? 0,
      promptId: json['prompt_id'] as String,
      promptText: json['prompt_text'] as String? ?? '',
      answer: json['answer'] as String,
      position: parseIntSafe(json['position']) ?? 1,
    );
  }
}
