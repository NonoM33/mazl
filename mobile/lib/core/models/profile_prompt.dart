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

  /// Default prompts list (used if API unavailable)
  static const List<Map<String, String>> defaultPrompts = [
    // Personnalité
    {'id': 'perfect_sunday', 'text': 'Mon dimanche parfait...', 'category': 'personality'},
    {'id': 'fun_fact', 'text': 'Un fait surprenant sur moi...', 'category': 'personality'},
    {'id': 'life_goal', 'text': 'Un de mes objectifs dans la vie...', 'category': 'personality'},
    {'id': 'pet_peeve', 'text': 'Ce qui m\'énerve le plus...', 'category': 'personality'},
    {'id': 'proud_of', 'text': 'Je suis fier(e) de...', 'category': 'personality'},
    {'id': 'looking_for', 'text': 'Je cherche quelqu\'un qui...', 'category': 'personality'},
    // Lifestyle
    {'id': 'ideal_vacation', 'text': 'Mes vacances idéales...', 'category': 'lifestyle'},
    {'id': 'favorite_food', 'text': 'Mon plat préféré...', 'category': 'lifestyle'},
    {'id': 'hidden_talent', 'text': 'Mon talent caché...', 'category': 'lifestyle'},
    {'id': 'binge_watching', 'text': 'En ce moment je regarde...', 'category': 'lifestyle'},
    // Judaïsme
    {'id': 'shabbat_ideal', 'text': 'Mon Shabbat idéal...', 'category': 'jewish'},
    {'id': 'family_tradition', 'text': 'Une tradition familiale que j\'adore...', 'category': 'jewish'},
    {'id': 'favorite_holiday', 'text': 'Ma fête juive préférée...', 'category': 'jewish'},
    {'id': 'friday_night', 'text': 'Le vendredi soir chez moi...', 'category': 'jewish'},
    {'id': 'israel_memory', 'text': 'Mon meilleur souvenir en Israël...', 'category': 'jewish'},
    {'id': 'jewish_value', 'text': 'Une valeur juive qui me guide...', 'category': 'jewish'},
    // Conversation starters
    {'id': 'debate_me', 'text': 'Débats moi sur...', 'category': 'conversation'},
    {'id': 'teach_me', 'text': 'Apprends-moi quelque chose sur...', 'category': 'conversation'},
    {'id': 'together_we_could', 'text': 'Ensemble on pourrait...', 'category': 'conversation'},
    {'id': 'first_date', 'text': 'Premier date idéal...', 'category': 'conversation'},
  ];
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
