import 'dart:math';

import 'api_service.dart';

/// Service to generate icebreaker suggestions for conversations
class IcebreakerService {
  static final IcebreakerService _instance = IcebreakerService._internal();
  factory IcebreakerService() => _instance;
  IcebreakerService._internal();

  final _random = Random();

  /// Generate icebreaker suggestions based on profile data
  List<Icebreaker> generateIcebreakers({
    required Profile otherProfile,
    Profile? myProfile,
    List<ProfilePrompt>? otherPrompts,
  }) {
    final icebreakers = <Icebreaker>[];

    // 1. Icebreakers from profile prompts
    if (otherPrompts != null && otherPrompts.isNotEmpty) {
      for (final prompt in otherPrompts.take(2)) {
        icebreakers.add(_generatePromptIcebreaker(prompt));
      }
    }

    // 2. Icebreakers from bio
    if (otherProfile.bio != null && otherProfile.bio!.isNotEmpty) {
      final bioIcebreaker = _generateBioIcebreaker(otherProfile.bio!);
      if (bioIcebreaker != null) {
        icebreakers.add(bioIcebreaker);
      }
    }

    // 3. Icebreakers from Jewish practice
    if (otherProfile.denomination != null) {
      icebreakers.add(_generateJewishIcebreaker(otherProfile));
    }

    // 4. Location-based icebreaker
    if (otherProfile.location != null) {
      icebreakers.add(_generateLocationIcebreaker(otherProfile.location!));
    }

    // 5. Add generic icebreakers if we don't have enough
    while (icebreakers.length < 3) {
      icebreakers.add(_getGenericIcebreaker());
    }

    // Shuffle and return top 5
    icebreakers.shuffle(_random);
    return icebreakers.take(5).toList();
  }

  Icebreaker _generatePromptIcebreaker(ProfilePrompt prompt) {
    final templates = [
      'J\'ai adoré ta réponse à "${prompt.promptText}". ${_getFollowUp(prompt.answer)}',
      'Ta réponse sur "${prompt.promptText}" m\'a fait sourire. Tu peux m\'en dire plus ?',
      'Je suis curieux(se) de savoir pourquoi tu as répondu "${_truncate(prompt.answer, 30)}" à la question sur ${_extractTopic(prompt.promptText)}',
    ];

    return Icebreaker(
      text: templates[_random.nextInt(templates.length)],
      type: IcebreakerType.prompt,
      relatedContent: prompt.answer,
    );
  }

  Icebreaker? _generateBioIcebreaker(String bio) {
    final lowercaseBio = bio.toLowerCase();

    // Look for interests/topics
    final topics = <String, List<String>>{
      'voyage': ['Tu as voyagé où récemment ? J\'adorerais entendre tes histoires.', 'Quelle est ta prochaine destination de rêve ?'],
      'musique': ['Quel genre de musique tu écoutes en ce moment ?', 'Tu as été à un bon concert récemment ?'],
      'cuisine': ['Tu cuisines quoi de bon en ce moment ?', 'C\'est quoi ton plat signature ?'],
      'sport': ['Tu pratiques quel sport ?', 'Tu préfères regarder ou pratiquer ?'],
      'lecture': ['Tu lis quoi en ce moment ?', 'C\'est quoi le dernier livre qui t\'a marqué ?'],
      'cinema': ['Tu as vu un bon film récemment ?', 'Tu préfères cinéma ou séries ?'],
      'randonnee': ['Tu connais de beaux sentiers dans le coin ?', 'C\'est quoi ta plus belle rando ?'],
      'photo': ['Tu prends des photos de quoi principalement ?', 'Tu utilises quoi comme appareil ?'],
    };

    for (final entry in topics.entries) {
      if (lowercaseBio.contains(entry.key)) {
        return Icebreaker(
          text: entry.value[_random.nextInt(entry.value.length)],
          type: IcebreakerType.bio,
          relatedContent: entry.key,
        );
      }
    }

    return null;
  }

  Icebreaker _generateJewishIcebreaker(Profile profile) {
    final templates = <String>[];

    switch (profile.denomination?.toLowerCase()) {
      case 'orthodox':
      case 'modern orthodox':
        templates.addAll([
          'Tu as une synagogue préférée dans le coin ?',
          'Comment tu passes généralement Shabbat ?',
          'Tu as un restaurant casher préféré ?',
        ]);
        break;
      case 'massorti':
      case 'traditionaliste':
        templates.addAll([
          'Quelles traditions juives sont les plus importantes pour toi ?',
          'Tu célèbres Shabbat comment généralement ?',
          'Tu as une fête juive préférée ?',
        ]);
        break;
      case 'laique':
        templates.addAll([
          'C\'est quoi ton rapport à la culture juive ?',
          'Tu as des traditions familiales que tu gardes ?',
          'Tu célèbres quelles fêtes ?',
        ]);
        break;
      default:
        templates.addAll([
          'C\'est quoi ta fête juive préférée ?',
          'Tu as des traditions familiales spéciales ?',
          'Tu as grandi dans une famille pratiquante ?',
        ]);
    }

    return Icebreaker(
      text: templates[_random.nextInt(templates.length)],
      type: IcebreakerType.jewish,
      relatedContent: profile.denomination,
    );
  }

  Icebreaker _generateLocationIcebreaker(String location) {
    final templates = [
      'Tu connais bien $location ? Tu me conseilles quoi ?',
      'C\'est quoi ton coin préféré à $location ?',
      'Tu es originaire de $location ou tu t\'y es installé(e) ?',
      'Il y a un bon restaurant que tu recommandes à $location ?',
    ];

    return Icebreaker(
      text: templates[_random.nextInt(templates.length)],
      type: IcebreakerType.location,
      relatedContent: location,
    );
  }

  Icebreaker _getGenericIcebreaker() {
    final templates = [
      'Si tu pouvais dîner avec n\'importe qui, vivant ou mort, ce serait qui ?',
      'C\'est quoi ta définition d\'une journée parfaite ?',
      'Tu as un talent caché que peu de gens connaissent ?',
      'C\'est quoi le truc le plus spontané que tu aies fait ?',
      'Tu préfères vacances à la mer ou à la montagne ?',
      'Si tu gagnais au loto demain, tu ferais quoi en premier ?',
      'C\'est quoi ton guilty pleasure ?',
      'Tu as un rêve que tu n\'as pas encore réalisé ?',
      'C\'est quoi le meilleur conseil qu\'on t\'ait donné ?',
      'Tu préfères petit-déjeuner ou dîner dehors ?',
    ];

    return Icebreaker(
      text: templates[_random.nextInt(templates.length)],
      type: IcebreakerType.generic,
      relatedContent: null,
    );
  }

  String _getFollowUp(String answer) {
    final followUps = [
      'Ça m\'intrigue.',
      'J\'aimerais en savoir plus.',
      'Tu me racontes ?',
      'Ça a l\'air intéressant.',
    ];
    return followUps[_random.nextInt(followUps.length)];
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _extractTopic(String question) {
    // Extract key topic from question
    final words = question.toLowerCase().split(' ');
    final stopWords = {'est', 'que', 'quoi', 'qui', 'tu', 'ton', 'ta', 'tes', 'le', 'la', 'les', 'un', 'une', 'des', 'ce', 'cette', 'pour', 'avec', 'dans', 'sur', 'par'};
    final keywords = words.where((w) => !stopWords.contains(w) && w.length > 3).take(2);
    return keywords.isEmpty ? 'ça' : keywords.join(' ');
  }
}

/// Icebreaker suggestion model
class Icebreaker {
  final String text;
  final IcebreakerType type;
  final String? relatedContent;

  Icebreaker({
    required this.text,
    required this.type,
    this.relatedContent,
  });
}

/// Types of icebreakers
enum IcebreakerType {
  prompt,   // Based on profile prompt
  bio,      // Based on bio content
  jewish,   // Based on Jewish practice
  location, // Based on location
  generic,  // Generic conversation starter
}
