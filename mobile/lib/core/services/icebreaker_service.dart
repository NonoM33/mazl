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
    final phrase = const [
      IcebreakerPhrase.promptLoved,
      IcebreakerPhrase.promptSmiled,
      IcebreakerPhrase.promptCurious,
    ][_random.nextInt(3)];

    return Icebreaker(
      phrase: phrase,
      type: IcebreakerType.prompt,
      relatedContent: prompt.answer,
      promptText: prompt.promptText,
      answer: _truncate(prompt.answer, 30),
      topic: _extractTopic(prompt.promptText),
      followUp: _getFollowUp(),
    );
  }

  Icebreaker? _generateBioIcebreaker(String bio) {
    final lowercaseBio = bio.toLowerCase();

    // Look for interests/topics
    const topics = <String, List<IcebreakerPhrase>>{
      'voyage': [IcebreakerPhrase.bioTravelRecent, IcebreakerPhrase.bioTravelDream],
      'musique': [IcebreakerPhrase.bioMusicGenre, IcebreakerPhrase.bioMusicConcert],
      'cuisine': [IcebreakerPhrase.bioCookingNow, IcebreakerPhrase.bioCookingSignature],
      'sport': [IcebreakerPhrase.bioSportWhich, IcebreakerPhrase.bioSportWatchOrPlay],
      'lecture': [IcebreakerPhrase.bioReadingNow, IcebreakerPhrase.bioReadingLastBook],
      'cinema': [IcebreakerPhrase.bioCinemaRecent, IcebreakerPhrase.bioCinemaOrSeries],
      'randonnee': [IcebreakerPhrase.bioHikingTrails, IcebreakerPhrase.bioHikingBest],
      'photo': [IcebreakerPhrase.bioPhotoSubjects, IcebreakerPhrase.bioPhotoCamera],
    };

    for (final entry in topics.entries) {
      if (lowercaseBio.contains(entry.key)) {
        return Icebreaker(
          phrase: entry.value[_random.nextInt(entry.value.length)],
          type: IcebreakerType.bio,
          relatedContent: entry.key,
        );
      }
    }

    return null;
  }

  Icebreaker _generateJewishIcebreaker(Profile profile) {
    final phrases = switch (profile.denomination?.toLowerCase()) {
      'orthodox' || 'modern orthodox' => const [
        IcebreakerPhrase.orthodoxSynagogue,
        IcebreakerPhrase.orthodoxShabbat,
        IcebreakerPhrase.orthodoxKosherRestaurant,
      ],
      'massorti' || 'traditionaliste' => const [
        IcebreakerPhrase.traditionalTraditions,
        IcebreakerPhrase.traditionalShabbat,
        IcebreakerPhrase.traditionalHoliday,
      ],
      'laique' => const [
        IcebreakerPhrase.secularCulture,
        IcebreakerPhrase.secularFamilyTraditions,
        IcebreakerPhrase.secularHolidays,
      ],
      _ => const [
        IcebreakerPhrase.defaultHoliday,
        IcebreakerPhrase.defaultFamilyTraditions,
        IcebreakerPhrase.defaultPracticingFamily,
      ],
    };

    return Icebreaker(
      phrase: phrases[_random.nextInt(phrases.length)],
      type: IcebreakerType.jewish,
      relatedContent: profile.denomination,
    );
  }

  Icebreaker _generateLocationIcebreaker(String location) {
    const phrases = [
      IcebreakerPhrase.locationKnowWell,
      IcebreakerPhrase.locationFavoriteSpot,
      IcebreakerPhrase.locationOriginallyFrom,
      IcebreakerPhrase.locationRestaurant,
    ];

    return Icebreaker(
      phrase: phrases[_random.nextInt(phrases.length)],
      type: IcebreakerType.location,
      relatedContent: location,
      location: location,
    );
  }

  Icebreaker _getGenericIcebreaker() {
    const phrases = [
      IcebreakerPhrase.genericDinnerGuest,
      IcebreakerPhrase.genericPerfectDay,
      IcebreakerPhrase.genericHiddenTalent,
      IcebreakerPhrase.genericSpontaneous,
      IcebreakerPhrase.genericSeaOrMountain,
      IcebreakerPhrase.genericLottery,
      IcebreakerPhrase.genericGuiltyPleasure,
      IcebreakerPhrase.genericDream,
      IcebreakerPhrase.genericBestAdvice,
      IcebreakerPhrase.genericBreakfastOrDinner,
    ];

    return Icebreaker(
      phrase: phrases[_random.nextInt(phrases.length)],
      type: IcebreakerType.generic,
    );
  }

  IcebreakerPhrase _getFollowUp() {
    const followUps = [
      IcebreakerPhrase.followUpIntrigued,
      IcebreakerPhrase.followUpKnowMore,
      IcebreakerPhrase.followUpTellMe,
      IcebreakerPhrase.followUpInteresting,
    ];
    return followUps[_random.nextInt(followUps.length)];
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// The two most telling words of a profile question, or null when there are
  /// none. Questions are matched against French stop words: it is a heuristic
  /// on the text the server serves, not a text shown as it is.
  String? _extractTopic(String question) {
    // Extract key topic from question
    final words = question.toLowerCase().split(' ');
    final stopWords = {'est', 'que', 'quoi', 'qui', 'tu', 'ton', 'ta', 'tes', 'le', 'la', 'les', 'un', 'une', 'des', 'ce', 'cette', 'pour', 'avec', 'dans', 'sur', 'par'};
    final keywords = words.where((w) => !stopWords.contains(w) && w.length > 3).take(2);
    return keywords.isEmpty ? null : keywords.join(' ');
  }
}

/// The first-message drafts, by identifier: the core never writes the
/// sentence, the screen translates it (`icebreakerText` in
/// `features/chat/l10n/`). They are written in the member's name for another
/// member, so every language speaks the familiar register.
enum IcebreakerPhrase {
  // About a profile prompt (uses promptText, answer, topic and followUp).
  promptLoved,
  promptSmiled,
  promptCurious,
  followUpIntrigued,
  followUpKnowMore,
  followUpTellMe,
  followUpInteresting,
  // About the bio.
  bioTravelRecent,
  bioTravelDream,
  bioMusicGenre,
  bioMusicConcert,
  bioCookingNow,
  bioCookingSignature,
  bioSportWhich,
  bioSportWatchOrPlay,
  bioReadingNow,
  bioReadingLastBook,
  bioCinemaRecent,
  bioCinemaOrSeries,
  bioHikingTrails,
  bioHikingBest,
  bioPhotoSubjects,
  bioPhotoCamera,
  // About Jewish practice.
  orthodoxSynagogue,
  orthodoxShabbat,
  orthodoxKosherRestaurant,
  traditionalTraditions,
  traditionalShabbat,
  traditionalHoliday,
  secularCulture,
  secularFamilyTraditions,
  secularHolidays,
  defaultHoliday,
  defaultFamilyTraditions,
  defaultPracticingFamily,
  // About the place (uses location).
  locationKnowWell,
  locationFavoriteSpot,
  locationOriginallyFrom,
  locationRestaurant,
  // Generic.
  genericDinnerGuest,
  genericPerfectDay,
  genericHiddenTalent,
  genericSpontaneous,
  genericSeaOrMountain,
  genericLottery,
  genericGuiltyPleasure,
  genericDream,
  genericBestAdvice,
  genericBreakfastOrDinner,
}

/// Icebreaker suggestion: which phrase, and the words it needs.
class Icebreaker {
  final IcebreakerPhrase phrase;
  final IcebreakerType type;
  final String? relatedContent;

  /// The place, for the location phrases.
  final String? location;

  /// The question and the (shortened) answer of the profile prompt.
  final String? promptText;
  final String? answer;

  /// Two key words of the question; null when there are none.
  final String? topic;

  /// The closing sentence of [IcebreakerPhrase.promptLoved].
  final IcebreakerPhrase? followUp;

  Icebreaker({
    required this.phrase,
    required this.type,
    this.relatedContent,
    this.location,
    this.promptText,
    this.answer,
    this.topic,
    this.followUp,
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
