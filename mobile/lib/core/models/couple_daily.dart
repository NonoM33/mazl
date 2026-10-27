/// Models of the daily couple space (docs/couple/ESPACE-COUPLE.md): today,
/// outings, rituals, the question of the day, the monthly check-in and the
/// concierge.
///
/// Decoding is strict about what the screens cannot do without (an id, a
/// title, a status): a missing or mistyped one throws a [FormatException],
/// which the API client reports as a `malformed` failure. It is lenient only
/// about the spelling of a key the contract names twice (camelCase in the
/// answers, snake_case in the table columns) and about optional fields.
library;

import 'couple_space.dart' show parseLooseDate, parseLooseInt;

/// The object an answer carries: its `data` envelope, else the answer itself.
Map<String, dynamic> couplePayload(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map<String, dynamic> ? data : response;
}

Object? _first(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json[key] != null) return json[key];
  }
  return null;
}

int _requiredInt(Map<String, dynamic> json, List<String> keys) {
  final value = parseLooseInt(_first(json, keys));
  if (value == null) throw FormatException('number:${keys.first}');
  return value;
}

String _requiredText(Map<String, dynamic> json, List<String> keys) {
  final value = _first(json, keys);
  if (value is! String || value.isEmpty) {
    throw FormatException('text:${keys.first}');
  }
  return value;
}

String? _optionalText(Map<String, dynamic> json, List<String> keys) {
  final value = _first(json, keys);
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

DateTime? _optionalDate(Map<String, dynamic> json, List<String> keys) =>
    parseLooseDate(_first(json, keys));

DateTime _requiredDate(Map<String, dynamic> json, List<String> keys) {
  final value = _optionalDate(json, keys);
  if (value == null) throw FormatException('date:${keys.first}');
  return value;
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('object:$key');
  }
  return value;
}

List<T> _requiredList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = json[key];
  if (raw is! List) throw FormatException('list:$key');
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>)
        fromJson(item)
      else
        throw FormatException('item:$key'),
  ];
}

// ---------------------------------------------------------------- premium

/// What the couple's MAZL Couple subscription gives (`GET /api/couple`,
/// `premium`). One member pays, both profit.
class CouplePremium {
  const CouplePremium({this.active = false, this.paidBy, this.renewsAt});

  /// Nothing is known or nothing is paid: the limited version of the space.
  static const inactive = CouplePremium();

  final bool active;

  /// `me` or `partner`, `null` when nobody pays.
  final CouplePayer? paidBy;
  final DateTime? renewsAt;

  /// Lenient on purpose: a server that does not send the field yet means "not
  /// subscribed", never a failure of the whole couple screen.
  factory CouplePremium.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return inactive;
    return CouplePremium(
      active: json['active'] == true,
      paidBy: switch (json['paidBy']) {
        'me' => CouplePayer.me,
        'partner' => CouplePayer.partner,
        _ => null,
      },
      renewsAt: parseLooseDate(json['renewsAt']),
    );
  }
}

enum CouplePayer { me, partner }

// ------------------------------------------------------------------ today

enum CoupleMoodChoice {
  great('great'),
  good('good'),
  meh('meh'),
  talk('talk');

  const CoupleMoodChoice(this.wire);

  final String wire;

  static CoupleMoodChoice? fromWire(Object? raw) {
    for (final mood in values) {
      if (mood.wire == raw) return mood;
    }
    return null;
  }
}

class CoupleTodayQuestion {
  const CoupleTodayQuestion({
    required this.id,
    required this.text,
    required this.myAnswered,
    required this.partnerAnswered,
  });

  final int id;
  final String text;
  final bool myAnswered;
  final bool partnerAnswered;

  factory CoupleTodayQuestion.fromJson(Map<String, dynamic> json) =>
      CoupleTodayQuestion(
        id: _requiredInt(json, ['id']),
        text: _requiredText(json, ['text']),
        myAnswered: json['myAnswered'] == true,
        partnerAnswered: json['partnerAnswered'] == true,
      );
}

enum CoupleUpcomingKind { date, ritual, event }

class CoupleUpcoming {
  const CoupleUpcoming({
    required this.kind,
    required this.title,
    required this.at,
    this.subtitle,
    this.refId,
  });

  final CoupleUpcomingKind kind;
  final String title;
  final DateTime at;
  final String? subtitle;
  final int? refId;

  factory CoupleUpcoming.fromJson(Map<String, dynamic> json) {
    final kind = CoupleUpcomingKind.values.where((k) => k.name == json['kind']);
    if (kind.isEmpty) throw const FormatException('kind:unknown');
    return CoupleUpcoming(
      kind: kind.first,
      title: _requiredText(json, ['title']),
      at: _requiredDate(json, ['at']),
      subtitle: _optionalText(json, ['subtitle']),
      refId: parseLooseInt(json['refId']),
    );
  }
}

/// An outing proposed to the couple: an activity or an event of MAZL couples.
class Outing {
  const Outing({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.city,
    this.startsAt,
    this.priceCents,
    this.kosher = false,
    this.saved = false,
  });

  final int id;
  final OutingKind kind;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? city;
  final DateTime? startsAt;
  final int? priceCents;
  final bool kosher;
  final bool saved;

  bool get isEvent => kind == OutingKind.event;

  Outing copyWith({bool? saved}) => Outing(
    id: id,
    kind: kind,
    title: title,
    subtitle: subtitle,
    imageUrl: imageUrl,
    city: city,
    startsAt: startsAt,
    priceCents: priceCents,
    kosher: kosher,
    saved: saved ?? this.saved,
  );

  factory Outing.fromJson(Map<String, dynamic> json) {
    final kind = OutingKind.values.where((k) => k.name == json['kind']);
    if (kind.isEmpty) throw const FormatException('kind:unknown');
    return Outing(
      id: _requiredInt(json, ['id']),
      kind: kind.first,
      title: _requiredText(json, ['title']),
      subtitle: _optionalText(json, ['subtitle']),
      imageUrl: _optionalText(json, ['imageUrl', 'image_url']),
      city: _optionalText(json, ['city']),
      startsAt: _optionalDate(json, ['startsAt', 'starts_at']),
      priceCents: parseLooseInt(_first(json, ['priceCents', 'price_cents'])),
      kosher: json['kosher'] == true,
      saved: json['saved'] == true,
    );
  }
}

enum OutingKind { activity, event }

/// The filters of `GET /api/couple/outings?filter=`.
enum OutingFilter {
  tonight('tonight'),
  week('week'),
  kosher('kosher'),
  cheap('cheap'),
  mazl('mazl');

  const OutingFilter(this.wire);

  final String wire;
}

class OutingsPage {
  const OutingsPage({this.featured, this.items = const []});

  static const empty = OutingsPage();

  final Outing? featured;
  final List<Outing> items;

  factory OutingsPage.fromJson(Map<String, dynamic> json) {
    final featured = json['featured'];
    return OutingsPage(
      featured: featured is Map<String, dynamic>
          ? Outing.fromJson(featured)
          : null,
      items: _requiredList(json, 'items', Outing.fromJson),
    );
  }
}

class CoupleToday {
  const CoupleToday({
    required this.days,
    required this.partnerId,
    required this.partnerName,
    this.partnerPicture,
    this.question,
    this.upcoming = const [],
    this.outing,
    this.myMood,
    this.partnerMood,
    this.checkinDue = false,
    this.checkinPeriod,
    this.premium = CouplePremium.inactive,
  });

  final int days;
  final int partnerId;
  final String partnerName;
  final String? partnerPicture;
  final CoupleTodayQuestion? question;
  final List<CoupleUpcoming> upcoming;
  final Outing? outing;
  final CoupleMoodChoice? myMood;
  final CoupleMoodChoice? partnerMood;
  final bool checkinDue;
  final String? checkinPeriod;
  final CouplePremium premium;

  factory CoupleToday.fromJson(Map<String, dynamic> json) {
    final partner = _requiredObject(json, 'partner');
    final question = json['question'];
    final outing = json['outing'];
    final mood = json['mood'];
    final checkin = json['checkin'];
    return CoupleToday(
      days: _requiredInt(json, ['days']),
      partnerId: _requiredInt(partner, ['id']),
      partnerName: _requiredText(partner, ['name']),
      partnerPicture: _optionalText(partner, ['picture']),
      question: question is Map<String, dynamic>
          ? CoupleTodayQuestion.fromJson(question)
          : null,
      upcoming: _requiredList(json, 'upcoming', CoupleUpcoming.fromJson),
      outing: outing is Map<String, dynamic> ? Outing.fromJson(outing) : null,
      myMood: mood is Map<String, dynamic>
          ? CoupleMoodChoice.fromWire(mood['mine'])
          : null,
      partnerMood: mood is Map<String, dynamic>
          ? CoupleMoodChoice.fromWire(mood['partner'])
          : null,
      checkinDue: checkin is Map<String, dynamic> && checkin['due'] == true,
      checkinPeriod: checkin is Map<String, dynamic>
          ? _optionalText(checkin, ['period'])
          : null,
      premium: CouplePremium.fromJson(json['premium']),
    );
  }
}

// ---------------------------------------------------------------- rituals

enum CoupleRitualKind { shabbat, weekly, custom }

class CoupleRitual {
  const CoupleRitual({
    required this.id,
    required this.kind,
    required this.title,
    required this.enabled,
    this.weekday,
    this.time,
    this.remindMinutes = 0,
  });

  final int id;
  final CoupleRitualKind kind;
  final String title;
  final bool enabled;

  /// 0 (Sunday) to 6, `null` for a ritual that is not weekly.
  final int? weekday;

  /// `HH:MM`, `null` when the ritual has no fixed time (Shabbat follows the
  /// candle lighting).
  final String? time;
  final int remindMinutes;

  CoupleRitual copyWith({bool? enabled}) => CoupleRitual(
    id: id,
    kind: kind,
    title: title,
    enabled: enabled ?? this.enabled,
    weekday: weekday,
    time: time,
    remindMinutes: remindMinutes,
  );

  factory CoupleRitual.fromJson(Map<String, dynamic> json) {
    final kind = CoupleRitualKind.values.where((k) => k.name == json['kind']);
    if (kind.isEmpty) throw const FormatException('kind:unknown');
    return CoupleRitual(
      id: _requiredInt(json, ['id']),
      kind: kind.first,
      title: _requiredText(json, ['title']),
      enabled: json['enabled'] == true,
      weekday: parseLooseInt(json['weekday']),
      time: _optionalText(json, ['time']),
      remindMinutes:
          parseLooseInt(_first(json, ['remindMinutes', 'remind_minutes'])) ?? 0,
    );
  }
}

// --------------------------------------------------------------- question

/// The question of the day for this couple. [partnerAnswer] is `null` until
/// the caller has answered: the server keeps it back, and so does the screen.
class CoupleQuestion {
  const CoupleQuestion({
    required this.id,
    required this.text,
    this.myAnswer,
    this.partnerAnswer,
  });

  final int id;
  final String text;
  final String? myAnswer;
  final String? partnerAnswer;

  bool get answered => myAnswer != null;

  factory CoupleQuestion.fromJson(Map<String, dynamic> json) => CoupleQuestion(
    id: _requiredInt(json, ['id']),
    text: _requiredText(json, ['text']),
    myAnswer: _optionalText(json, ['myAnswer', 'my_answer']),
    partnerAnswer: _optionalText(json, ['partnerAnswer', 'partner_answer']),
  );
}

/// One line of the history: the question and both answers (only the
/// questions the caller answered are listed).
class CoupleQuestionEntry {
  const CoupleQuestionEntry({
    required this.id,
    required this.text,
    required this.myAnswer,
    this.partnerAnswer,
    this.askedOn,
  });

  final int id;
  final String text;
  final String myAnswer;
  final String? partnerAnswer;
  final DateTime? askedOn;

  factory CoupleQuestionEntry.fromJson(Map<String, dynamic> json) =>
      CoupleQuestionEntry(
        id: _requiredInt(json, ['id']),
        text: _requiredText(json, ['text']),
        myAnswer: _requiredText(json, ['myAnswer', 'my_answer']),
        partnerAnswer: _optionalText(json, ['partnerAnswer', 'partner_answer']),
        askedOn: _optionalDate(json, ['askedOn', 'asked_on', 'date']),
      );
}

// ---------------------------------------------------------------- checkin

enum CheckinTheme { talk, time, close }

class CheckinScores {
  const CheckinScores({
    required this.talk,
    required this.time,
    required this.close,
  });

  final int talk;
  final int time;
  final int close;

  int scoreOf(CheckinTheme theme) => switch (theme) {
    CheckinTheme.talk => talk,
    CheckinTheme.time => time,
    CheckinTheme.close => close,
  };

  Map<String, dynamic> toJson() => {'talk': talk, 'time': time, 'close': close};

  factory CheckinScores.fromJson(Map<String, dynamic> json) {
    int score(String key) {
      final value = _requiredInt(json, [key]);
      if (value < 1 || value > 5) throw FormatException('range:$key');
      return value;
    }

    return CheckinScores(
      talk: score('talk'),
      time: score('time'),
      close: score('close'),
    );
  }
}

enum CheckinTrend { up, down, same }

/// What the couple sees once both answered: never the other's notes.
class CheckinSummary {
  const CheckinSummary({
    required this.aligned,
    required this.lowest,
    this.trend,
  });

  /// How many of the three themes both notes agree on (within one point).
  final int aligned;
  final CheckinTheme lowest;
  final CheckinTrend? trend;

  factory CheckinSummary.fromJson(Map<String, dynamic> json) {
    final aligned = _requiredInt(json, ['aligned']);
    if (aligned < 0 || aligned > 3) {
      throw const FormatException('range:aligned');
    }
    final lowest = CheckinTheme.values.where((t) => t.name == json['lowest']);
    if (lowest.isEmpty) throw const FormatException('lowest:unknown');
    final trend = CheckinTrend.values.where((t) => t.name == json['trend']);
    return CheckinSummary(
      aligned: aligned,
      lowest: lowest.first,
      trend: trend.isEmpty ? null : trend.first,
    );
  }
}

class CoupleCheckin {
  const CoupleCheckin({
    required this.period,
    this.mine,
    this.partnerDone = false,
    this.summary,
  });

  /// `2026-11`.
  final String period;
  final CheckinScores? mine;
  final bool partnerDone;
  final CheckinSummary? summary;

  bool get answered => mine != null;

  factory CoupleCheckin.fromJson(Map<String, dynamic> json) {
    final mine = json['mine'];
    final summary = json['summary'];
    return CoupleCheckin(
      period: _requiredText(json, ['period']),
      mine: mine is Map<String, dynamic> ? CheckinScores.fromJson(mine) : null,
      partnerDone: json['partnerDone'] == true,
      summary: summary is Map<String, dynamic>
          ? CheckinSummary.fromJson(summary)
          : null,
    );
  }
}

// -------------------------------------------------------------- concierge

enum ConciergeStatus { fresh, proposed, chosen, booked, closed, cancelled }

ConciergeStatus _statusOf(Object? raw) => switch (raw) {
  'new' => ConciergeStatus.fresh,
  'proposed' => ConciergeStatus.proposed,
  'chosen' => ConciergeStatus.chosen,
  'booked' => ConciergeStatus.booked,
  'closed' => ConciergeStatus.closed,
  'cancelled' => ConciergeStatus.cancelled,
  _ => throw const FormatException('status:unknown'),
};

/// What a request is about, for the quick asks.
enum ConciergeKind { table, surprise, gift, weekend, other }

/// One line of the list of requests.
class ConciergeSummary {
  const ConciergeSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.step,
    this.wantedAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final ConciergeStatus status;

  /// 1 request received, 2 idea chosen, 3 booked by the team.
  final int step;
  final DateTime? wantedAt;
  final DateTime? updatedAt;

  bool get isOpen =>
      status != ConciergeStatus.closed && status != ConciergeStatus.cancelled;

  factory ConciergeSummary.fromJson(Map<String, dynamic> json) {
    final step = _requiredInt(json, ['step']);
    if (step < 1 || step > 3) throw const FormatException('range:step');
    return ConciergeSummary(
      id: _requiredInt(json, ['id']),
      title: _requiredText(json, ['title']),
      status: _statusOf(json['status']),
      step: step,
      wantedAt: _optionalDate(json, ['wantedAt', 'wanted_at']),
      updatedAt: _optionalDate(json, ['updatedAt', 'updated_at']),
    );
  }
}

/// An idea the assistant proposes. It never books anything and its price is
/// a hint, not a quote.
class ConciergeOption {
  const ConciergeOption({
    required this.title,
    required this.details,
    this.priceHint,
  });

  final String title;
  final String details;
  final String? priceHint;

  factory ConciergeOption.fromJson(Map<String, dynamic> json) =>
      ConciergeOption(
        title: _requiredText(json, ['title']),
        details: _optionalText(json, ['details']) ?? '',
        priceHint: _optionalText(json, ['priceHint', 'price_hint']),
      );
}

enum ConciergeRole { member, assistant, staff }

class ConciergeMessage {
  const ConciergeMessage({
    required this.id,
    required this.role,
    required this.text,
    this.createdAt,
    this.mine = false,
  });

  final int id;
  final ConciergeRole role;
  final String text;
  final DateTime? createdAt;

  /// Whether the caller wrote it (a member message of the other member is
  /// shown on the other side).
  final bool mine;

  factory ConciergeMessage.fromJson(
    Map<String, dynamic> json, {
    int? callerId,
  }) {
    final role = ConciergeRole.values.where((r) => r.name == json['role']);
    if (role.isEmpty) throw const FormatException('role:unknown');
    final author = parseLooseInt(_first(json, ['authorId', 'author_id']));
    return ConciergeMessage(
      id: _requiredInt(json, ['id']),
      role: role.first,
      text: _requiredText(json, ['text']),
      createdAt: _optionalDate(json, ['createdAt', 'created_at']),
      mine:
          role.first == ConciergeRole.member &&
          (callerId == null || author == null || author == callerId),
    );
  }
}

class ConciergeRequest {
  const ConciergeRequest({
    required this.id,
    required this.title,
    required this.status,
    this.brief,
    this.wantedAt,
    this.city,
    this.options = const [],
    this.chosenIndex,
    this.updatedAt,
  });

  final int id;
  final String title;
  final ConciergeStatus status;
  final String? brief;
  final DateTime? wantedAt;
  final String? city;
  final List<ConciergeOption> options;
  final int? chosenIndex;
  final DateTime? updatedAt;

  bool get canChoose =>
      status == ConciergeStatus.proposed && options.isNotEmpty;

  factory ConciergeRequest.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return ConciergeRequest(
      id: _requiredInt(json, ['id']),
      title: _requiredText(json, ['title']),
      status: _statusOf(json['status']),
      brief: _optionalText(json, ['brief']),
      wantedAt: _optionalDate(json, ['wantedAt', 'wanted_at']),
      city: _optionalText(json, ['city']),
      options: rawOptions == null
          ? const []
          : _requiredList(json, 'options', ConciergeOption.fromJson),
      chosenIndex: parseLooseInt(_first(json, ['chosenIndex', 'chosen_index'])),
      updatedAt: _optionalDate(json, ['updatedAt', 'updated_at']),
    );
  }
}

/// A request and its conversation (`GET /api/couple/concierge/:id`, and the
/// answer of every write on it).
class ConciergeThread {
  const ConciergeThread({required this.request, required this.messages});

  final ConciergeRequest request;
  final List<ConciergeMessage> messages;

  factory ConciergeThread.fromJson(Map<String, dynamic> json, {int? callerId}) {
    final raw = json['messages'];
    if (raw is! List) throw const FormatException('list:messages');
    return ConciergeThread(
      request: ConciergeRequest.fromJson(_requiredObject(json, 'request')),
      messages: [
        for (final item in raw)
          if (item is Map<String, dynamic>)
            ConciergeMessage.fromJson(item, callerId: callerId)
          else
            throw const FormatException('item:messages'),
      ],
    );
  }
}
