import '../router/route_names.dart';

/// Where a tapped push notification leads, from its `data`
/// (docs/launch/V1-CONTRAT.md §1), or null when it leads nowhere.
///
/// | type              | opens                                              |
/// |-------------------|----------------------------------------------------|
/// | `new_match`       | `/chat/<conversation_id>`, else `/matches`         |
/// | `new_message`     | `/chat/<conversation_id>`, else `/chat`            |
/// | `couple_request`  | `/couple/today`                                    |
/// | `couple_accepted` | `/couple/today`                                    |
/// | `couple_reminder` | `/couple/agenda`                                   |
/// | `couple_question` | `/couple/us`                                       |
/// | `couple_concierge`| `/couple/concierge`                                |
/// | `new_like`        | `/likes`                                           |
/// | `super_like`      | `/likes`                                           |
/// | `boost_ended`     | `/boost`                                           |
/// | any, with `screen: "boost"` | `/boost` (a scheduled Boost started)     |
/// | `event_available` | `/events/<event_id>`, else `/events`               |
/// | `event_opened`    | `/events/<event_id>`, else `/events`               |
///
/// Older or unknown types (`event_reminder`, `admin_test`…) lead nowhere. An identifier is
/// only ever read as a positive whole number and rebuilt into the path, never
/// copied from the payload as it came.
String? pushDestination(Map<String, dynamic> data) {
  final type = data['type'];
  if (type is! String) return _screenDestination(data);
  final conversation = _positiveInt(data['conversation_id']);
  switch (type) {
    case 'new_match':
      return conversation == null
          ? RoutePaths.matches
          : _conversationPath(conversation);
    case 'new_message':
      return conversation == null
          ? RoutePaths.chat
          : _conversationPath(conversation);
    case 'couple_request' || 'couple_accepted' || 'couple_mood':
      return RoutePaths.coupleToday;
    case 'couple_reminder':
      return RoutePaths.coupleAgenda;
    case 'couple_question':
      return RoutePaths.coupleUs;
    case 'couple_concierge':
      return RoutePaths.coupleConcierge;
    case 'new_like' || 'super_like':
      return RoutePaths.likes;
    case 'boost_ended':
      return RoutePaths.boost;
    case 'event_available' || 'event_opened':
      final event = _positiveInt(data['event_id']);
      return event == null ? RoutePaths.events : '${RoutePaths.events}/$event';
    default:
      return _screenDestination(data);
  }
}

/// A scheduled Boost that started: `data.screen` names the page. Only this
/// known value is read; the route is rebuilt, never copied.
String? _screenDestination(Map<String, dynamic> data) =>
    data['screen'] == 'boost' ? RoutePaths.boost : null;

String _conversationPath(int id) => '${RoutePaths.chat}/$id';

/// A whole number above zero, whether it arrived as a number or as digits.
int? _positiveInt(Object? value) {
  final int? number = switch (value) {
    int() => value,
    double() when value == value.truncateToDouble() && value.isFinite =>
      value.toInt(),
    String() when RegExp(r'^[0-9]+$').hasMatch(value) => int.tryParse(value),
    _ => null,
  };
  return number != null && number > 0 ? number : null;
}
