import 'demo_routes.dart';
import 'demo_store.dart';

/// The privacy consents and the analytics relay in demo mode: same shapes and
/// refusals as the server (`src/features/privacy/`, `src/features/analytics/`).
/// The relay keeps the events on the device: nothing leaves.
abstract final class DemoPrivacyRoutes {
  static const _wordings = {
    'religious_data': (
      version: '2026-10-24',
      text:
          "J'accepte que MAZL traite les informations sur ma pratique "
          'religieuse que je choisis de renseigner (courant, cashrout, '
          'Shabbat, intention) pour me proposer des profils compatibles et '
          'les afficher sur mon profil. Ce consentement est facultatif et je '
          'peux le retirer à tout moment dans les réglages ; les informations '
          'sont alors effacées.',
    ),
    'analytics': (
      version: '2026-10-26',
      text:
          "J'accepte que MAZL mesure mon utilisation de l'application pour "
          "l'améliorer : écrans consultés, étapes de l'inscription, swipes, "
          'matchs, messages envoyés, achats et vérifications, sans jamais leur '
          'contenu. Ces mesures sont rattachées à un identifiant pseudonyme, '
          'ne contiennent ni mes messages, ni mes informations religieuses, ni '
          'ma position, et restent sur les serveurs de MAZL, sans publicité ni '
          'partage. Ce consentement est facultatif et je peux le retirer à '
          'tout moment dans les réglages.',
    ),
  };

  static Map<String, dynamic> _view(String purpose) {
    final wording = _wordings[purpose]!;
    final stored = DemoStore.consent(purpose);
    return {
      'granted': stored?.granted,
      'version': stored?.version,
      'decided_at': stored?.decidedAt.toUtc().toIso8601String(),
      'current_version': wording.version,
      'text': wording.text,
    };
  }

  static DemoReply _decide(DemoRequest request, RegExpMatch match) {
    final purpose = match.group(1)!;
    final wording = _wordings[purpose];
    if (wording == null) {
      return const DemoReply({
        'success': false,
        'error': 'unknown_purpose',
      }, status: 404);
    }
    final granted = request.body['granted'];
    final version = request.body['version'];
    if (granted is! bool || version is! String) {
      return const DemoReply({
        'success': false,
        'error': 'invalid_body',
      }, status: 400);
    }
    if (version != wording.version) {
      return DemoReply({
        'success': false,
        'error': 'consent_version_outdated',
        'current_version': wording.version,
      }, status: 409);
    }
    final stored = DemoStore.decideConsent(purpose, granted, version);
    return DemoReply({
      'success': true,
      'consent': {
        'granted': stored.granted,
        'version': stored.version,
        'decided_at': stored.decidedAt.toUtc().toIso8601String(),
      },
    });
  }

  static final List<DemoRoute> routes = [
    DemoRoute(
      'GET',
      '/api/privacy/consents',
      (r, m) => DemoReply({
        'success': true,
        'consents': {
          'religious_data': _view('religious_data'),
          'analytics': _view('analytics'),
        },
      }),
    ),
    DemoRoute('PUT', '/api/privacy/consents/([a-z_]+)', _decide),
    DemoRoute('POST', '/api/analytics/events', (r, m) {
      final events = r.body['events'];
      return DemoReply({
        'success': true,
        'accepted': events is List ? events.length : 0,
      }, status: 202);
    }),
  ];
}
