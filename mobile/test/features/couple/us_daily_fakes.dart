import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_us_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

/// Server shapes of the daily routes, written from
/// docs/couple/ESPACE-COUPLE.md §5 and §6 (not from the Dart decoders).

/// `GET /api/couple/:id/question`. `partnerAnswer` is null until the caller
/// answered (§0.4): a test that sets it with a null `myAnswer` plays a
/// server that breaks the privacy rule.
Map<String, dynamic> questionReply({
  int id = 8,
  String text = 'Quel est votre plus beau souvenir ensemble ?',
  String? myAnswer,
  String? partnerAnswer,
}) => ok({
  'question': {
    'id': id,
    'text': text,
    'myAnswer': myAnswer,
    'partnerAnswer': partnerAnswer,
  },
});

/// `GET /api/couple/checkin` and `POST /api/couple/checkin`.
Map<String, dynamic> checkinReply({
  String period = '2026-11',
  Map<String, int>? mine,
  bool partnerDone = false,
  Map<String, dynamic>? summary,
}) => ok({
  'data': {
    'period': period,
    'mine': mine,
    'partnerDone': partnerDone,
    'summary': summary,
  },
});

/// `GET /api/couple/today`, reduced to what the screen reads.
Map<String, dynamic> todayReply({
  bool partnerAnswered = false,
  bool myAnswered = false,
}) => ok({
  'data': {
    'days': 214,
    'partner': {'id': 45, 'name': 'Myriam', 'picture': null},
    'question': {
      'id': 8,
      'text': 'Quel est votre plus beau souvenir ensemble ?',
      'myAnswered': myAnswered,
      'partnerAnswered': partnerAnswered,
    },
    'upcoming': [],
    'outing': null,
    'mood': {'mine': null, 'partner': null},
    'checkin': {'due': true, 'period': '2026-11'},
    'premium': {'active': false, 'paidBy': null, 'renewsAt': null},
  },
});

/// A server older than the contract: the check-in route answers 404 (the
/// question one too when a couple id is known).
extension UsDailyAbsent on FakeCoupleTransport {
  void dailyRoutesAbsent({int? coupleId}) {
    reply('GET /api/couple/checkin', error('Not Found'));
    if (coupleId != null) {
      reply('GET /api/couple/$coupleId/question', error('Not Found'));
    }
  }
}

/// « Nous deux » over one fake server: the shared space and the daily routes
/// both read from [transport], so nothing reaches the network.
CoupleUsScreen usScreen(
  FakeCoupleTransport transport, {
  CoupleService? couple,
}) => CoupleUsScreen(
  apiService: CoupleApiService(transport: transport),
  dailyApi: CoupleDailyApi(transport: transport, callerId: () => 12),
  couple: couple,
);
