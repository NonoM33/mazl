/// Service for Jewish calendar data
class JewishCalendarService {
  static final JewishCalendarService _instance = JewishCalendarService._internal();
  factory JewishCalendarService() => _instance;
  JewishCalendarService._internal();

  /// Get upcoming Jewish holidays
  List<JewishHoliday> getUpcomingHolidays() {
    final now = DateTime.now();
    return _holidays2025
        .where((h) => h.date.isAfter(now) || h.date.isAtSameMomentAs(now))
        .take(5)
        .toList();
  }

  /// Get this week's Shabbat info
  ShabbatInfo getThisWeekShabbat() {
    final now = DateTime.now();
    // Find next Friday
    var friday = now;
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }

    // Get the parasha based on date (simplified)
    final parasha = _getParasha(friday);

    return ShabbatInfo(
      parasha: parasha,
      candleLighting: _getCandleLightingTime(friday),
      havdala: _getHavdalaTime(friday.add(const Duration(days: 1))),
      date: friday,
    );
  }

  /// Get couple activities for an occasion
  List<CoupleActivity> getActivitiesForOccasion(String occasion) {
    switch (occasion) {
      case 'shabbat':
        return [
          CoupleActivity(
            title: 'Preparer le diner ensemble',
            description: 'Cuisinez la Halla et le repas de fete',
            icon: 'utensils',
            category: 'Preparation',
          ),
          CoupleActivity(
            title: 'Allumer les bougies',
            description: 'Moment de spiritualite partage',
            icon: 'flame',
            category: 'Spirituel',
          ),
          CoupleActivity(
            title: 'Promenade Shabbat',
            description: 'Ballade tranquille apres le repas',
            icon: 'footprints',
            category: 'Detente',
          ),
          CoupleActivity(
            title: 'Etude de la Parasha',
            description: 'Apprenez ensemble la portion de la semaine',
            icon: 'book',
            category: 'Spirituel',
          ),
        ];
      case 'pessah':
        return [
          CoupleActivity(
            title: 'Preparer le Seder',
            description: 'Organisez la table ensemble',
            icon: 'table',
            category: 'Preparation',
          ),
          CoupleActivity(
            title: 'Faire le menage de Pessah',
            description: 'Nettoyage de printemps en equipe',
            icon: 'sparkles',
            category: 'Preparation',
          ),
        ];
      default:
        return [];
    }
  }

  String _getParasha(DateTime friday) {
    // Simplified parasha calculation
    final month = friday.month;
    final day = friday.day;

    if (month == 1) {
      if (day <= 11) return 'Shemot';
      if (day <= 18) return 'Vaera';
      if (day <= 25) return 'Bo';
      return 'Beshalach';
    }
    if (month == 2) {
      if (day <= 8) return 'Yitro';
      if (day <= 15) return 'Mishpatim';
      if (day <= 22) return 'Terouma';
      return 'Tetzaveh';
    }
    // ... simplified for demo
    return 'Bereshit';
  }

  String _getCandleLightingTime(DateTime friday) {
    // Simplified - in production use Hebcal API
    final month = friday.month;
    if (month >= 11 || month <= 2) return '16:45';
    if (month >= 3 && month <= 4) return '18:30';
    if (month >= 5 && month <= 8) return '20:30';
    return '18:00';
  }

  String _getHavdalaTime(DateTime saturday) {
    // Simplified - add ~1h15 to candle lighting
    final month = saturday.month;
    if (month >= 11 || month <= 2) return '18:00';
    if (month >= 3 && month <= 4) return '19:45';
    if (month >= 5 && month <= 8) return '21:45';
    return '19:15';
  }

  // 2025 Jewish holidays (simplified)
  static final List<JewishHoliday> _holidays2025 = [
    JewishHoliday(
      name: 'Tou Bichvat',
      hebrewName: 'ט״ו בשבט',
      date: DateTime(2025, 2, 13),
      description: 'Nouvel an des arbres',
      type: HolidayType.minor,
    ),
    JewishHoliday(
      name: 'Pourim',
      hebrewName: 'פורים',
      date: DateTime(2025, 3, 14),
      description: 'Fete des sorts',
      type: HolidayType.major,
      coupleIdeas: ['Deguisement en couple', 'Mishloach Manot ensemble'],
    ),
    JewishHoliday(
      name: 'Pessah',
      hebrewName: 'פסח',
      date: DateTime(2025, 4, 13),
      endDate: DateTime(2025, 4, 20),
      description: 'Fete de la liberte',
      type: HolidayType.major,
      coupleIdeas: ['Seder romantique', 'Voyage en Israel'],
    ),
    JewishHoliday(
      name: 'Yom HaShoah',
      hebrewName: 'יום השואה',
      date: DateTime(2025, 4, 24),
      description: 'Jour du souvenir de la Shoah',
      type: HolidayType.memorial,
    ),
    JewishHoliday(
      name: 'Yom HaAtsmaout',
      hebrewName: 'יום העצמאות',
      date: DateTime(2025, 5, 1),
      description: 'Jour de l\'independance d\'Israel',
      type: HolidayType.israeli,
      coupleIdeas: ['BBQ israelien', 'Concert/soiree'],
    ),
    JewishHoliday(
      name: 'Lag BaOmer',
      hebrewName: 'ל״ג בעומר',
      date: DateTime(2025, 5, 16),
      description: '33eme jour du Omer',
      type: HolidayType.minor,
      coupleIdeas: ['Feu de camp', 'Pique-nique'],
    ),
    JewishHoliday(
      name: 'Shavouot',
      hebrewName: 'שבועות',
      date: DateTime(2025, 6, 2),
      endDate: DateTime(2025, 6, 3),
      description: 'Don de la Torah',
      type: HolidayType.major,
      coupleIdeas: ['Cheesecake maison', 'Nuit d\'etude'],
    ),
    JewishHoliday(
      name: 'Rosh Hashana',
      hebrewName: 'ראש השנה',
      date: DateTime(2025, 9, 23),
      endDate: DateTime(2025, 9, 24),
      description: 'Nouvel an juif - 5786',
      type: HolidayType.major,
      coupleIdeas: ['Diner festif', 'Tashlich ensemble'],
    ),
    JewishHoliday(
      name: 'Yom Kippour',
      hebrewName: 'יום כיפור',
      date: DateTime(2025, 10, 2),
      description: 'Jour du Grand Pardon',
      type: HolidayType.major,
      coupleIdeas: ['Se demander pardon mutuellement'],
    ),
    JewishHoliday(
      name: 'Souccot',
      hebrewName: 'סוכות',
      date: DateTime(2025, 10, 7),
      endDate: DateTime(2025, 10, 13),
      description: 'Fete des cabanes',
      type: HolidayType.major,
      coupleIdeas: ['Construire la Soucca ensemble', 'Inviter des amis'],
    ),
    JewishHoliday(
      name: 'Simhat Torah',
      hebrewName: 'שמחת תורה',
      date: DateTime(2025, 10, 15),
      description: 'Joie de la Torah',
      type: HolidayType.major,
      coupleIdeas: ['Danser avec la Torah'],
    ),
    JewishHoliday(
      name: 'Hanoucca',
      hebrewName: 'חנוכה',
      date: DateTime(2025, 12, 15),
      endDate: DateTime(2025, 12, 22),
      description: 'Fete des lumieres',
      type: HolidayType.major,
      coupleIdeas: ['Allumer les bougies ensemble', 'Soufganiot maison'],
    ),
  ];
}

/// Model for a Jewish holiday
class JewishHoliday {
  final String name;
  final String hebrewName;
  final DateTime date;
  final DateTime? endDate;
  final String description;
  final HolidayType type;
  final List<String>? coupleIdeas;

  JewishHoliday({
    required this.name,
    required this.hebrewName,
    required this.date,
    this.endDate,
    required this.description,
    required this.type,
    this.coupleIdeas,
  });

  int get daysUntil => date.difference(DateTime.now()).inDays;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool get isOngoing {
    if (endDate == null) return isToday;
    final now = DateTime.now();
    return now.isAfter(date.subtract(const Duration(days: 1))) &&
           now.isBefore(endDate!.add(const Duration(days: 1)));
  }
}

/// Holiday type enum
enum HolidayType {
  major,
  minor,
  memorial,
  israeli,
}

extension HolidayTypeExtension on HolidayType {
  String get emoji {
    switch (this) {
      case HolidayType.major:
        return '';
      case HolidayType.minor:
        return '';
      case HolidayType.memorial:
        return '';
      case HolidayType.israeli:
        return '';
    }
  }
}

/// Model for Shabbat info
class ShabbatInfo {
  final String parasha;
  final String candleLighting;
  final String havdala;
  final DateTime date;

  ShabbatInfo({
    required this.parasha,
    required this.candleLighting,
    required this.havdala,
    required this.date,
  });
}

/// Model for couple activity
class CoupleActivity {
  final String title;
  final String description;
  final String icon;
  final String category;

  CoupleActivity({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });
}
