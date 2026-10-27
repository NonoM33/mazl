import 'package:flutter/material.dart';
import 'package:mazl/core/di/providers/storefront_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/chat/screens/chat_conversation_screen.dart';

import '../../presentation/storefront/storefront_fixtures.dart';
import 'duo_screens.dart';

/// The first full button of the screen.
Finder _filledButton() =>
    find.byWidgetPredicate((w) => w is ElevatedButton || w is FilledButton);

/// The purchase button of the mazl+ page, not the one of its campaign.
Finder _buyButton() => find.byWidgetPredicate(
  (w) => w is ElevatedButton && w.key != const ValueKey('campaign-cta'),
);

/// The button labelled [text]: its Material button, else the nearest ink.
Finder _action(String text) {
  final button = find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  if (button.evaluate().isNotEmpty) return button;
  return find.ancestor(of: find.text(text), matching: find.byType(InkWell));
}

/// The message field of a conversation.
Finder _composer() => find.descendant(
  of: find.byType(ChatConversationScreen),
  matching: find.byType(EditableText),
);

/// Opens the first row of a list by its text (the demo members have fixed
/// names: Noémie is the match 301 and the conversation 101).
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pump();
  await tester.tap(find.text(text).first);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The tappable 56 pt photo of a row of Matches, when one is on screen.
RenderBox? _rowPhoto() {
  for (final element in find.byType(GestureDetector).evaluate()) {
    final box = element.renderObject! as RenderBox;
    if ((element.widget as GestureDetector).onTap != null &&
        box.size == const Size.square(56)) {
      return box;
    }
  }
  return null;
}

/// Opens the profile behind the photo of the first row of Matches, scrolling
/// the page to the rows when the posture is too short to show them.
Future<void> _tapFirstPhoto(WidgetTester tester) async {
  for (var i = 0; i < 8 && _rowPhoto() == null; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 100));
  }
  final photo = _rowPhoto()!;
  await tester.tapAt(photo.localToGlobal(photo.size.center(Offset.zero)));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Every route of `lib/core/router/app_router.dart`, with the ids of the demo
/// data (`lib/core/dev`), plus the two-level screens opened from their list.
final List<DuoScreen> duoScreens = [
  // auth
  const DuoScreen(
    id: '/',
    feature: 'auth',
    file: 'auth/screens/splash_screen.dart',
    path: '/',
    settleMillis: 1000,
  ),
  DuoScreen(
    id: '/onboarding',
    feature: 'onboarding',
    file: 'onboarding/screens/onboarding_screen.dart',
    path: '/onboarding',
    session: DuoSession.signedOut,
    primary: () => _action('Continuer'),
  ),
  DuoScreen(
    id: '/login',
    feature: 'auth',
    file: 'auth/screens/login_screen.dart',
    path: '/login',
    session: DuoSession.signedOut,
    primary: () => _action('Continuer avec Google'),
  ),
  DuoScreen(
    id: '/login/review',
    feature: 'auth',
    file: 'auth/screens/review_login_screen.dart',
    path: '/login/review',
    session: DuoSession.signedOut,
    primary: () => _action('Se connecter'),
  ),
  // matching
  const DuoScreen(
    id: '/discover',
    feature: 'matching',
    file: 'matching/screens/discover_screen.dart',
    path: '/discover',
  ),
  const DuoScreen(
    id: '/discover/profile/:userId',
    feature: 'profile',
    file: 'profile/screens/profile_view_screen.dart',
    path: '/discover/profile/201',
  ),
  const DuoScreen(
    id: '/matches',
    feature: 'matching',
    file: 'matching/screens/matches_screen.dart',
    path: '/matches',
  ),
  const DuoScreen(
    id: '/matches/profile/:userId',
    feature: 'profile',
    file: 'profile/screens/profile_view_screen.dart',
    path: '/matches/profile/301',
  ),
  DuoScreen(
    id: '/matches > open a match',
    feature: 'matching',
    file: 'matching/screens/matches_screen.dart',
    path: '/matches',
    open: (tester) => _tapText(tester, 'Noémie'),
    primary: _composer,
  ),
  DuoScreen(
    id: '/matches > open a profile',
    feature: 'profile',
    file: 'profile/screens/profile_view_screen.dart',
    path: '/matches',
    open: _tapFirstPhoto,
  ),
  const DuoScreen(
    id: '/likes',
    feature: 'likes',
    file: 'likes/screens/likes_screen.dart',
    path: '/likes',
  ),
  const DuoScreen(
    id: '/filters',
    feature: 'matching',
    file: 'matching/screens/filters_screen.dart',
    path: '/filters',
  ),
  DuoScreen(
    id: '/filters > after a change',
    feature: 'matching',
    file: 'matching/screens/filters_screen.dart',
    path: '/filters',
    open: (tester) => _tapText(tester, 'Massorti'),
    primary: () => _action('Appliquer les filtres'),
  ),
  const DuoScreen(
    id: '/daily-picks',
    feature: 'matching',
    file: 'matching/screens/daily_picks_screen.dart',
    path: '/daily-picks',
  ),
  DuoScreen(
    id: '/boost',
    feature: 'boost',
    file: 'boost/screens/boost_screen.dart',
    path: '/boost',
    primary: () => _action('Activer le Boost'),
  ),
  // chat
  const DuoScreen(
    id: '/chat',
    feature: 'chat',
    file: 'chat/screens/conversations_screen.dart',
    path: '/chat',
  ),
  DuoScreen(
    id: '/chat/:conversationId',
    feature: 'chat',
    file: 'chat/screens/chat_screen.dart',
    path: '/chat/101',
    primary: _composer,
  ),
  DuoScreen(
    id: '/chat > open a conversation',
    feature: 'chat',
    file: 'chat/screens/conversations_screen.dart',
    path: '/chat',
    open: (tester) => _tapText(tester, 'Noémie'),
    primary: _composer,
  ),
  // events
  const DuoScreen(
    id: '/events',
    feature: 'events',
    file: 'events/screens/events_list_screen.dart',
    path: '/events',
  ),
  DuoScreen(
    id: '/events/:eventId',
    feature: 'events',
    file: 'events/screens/event_detail_screen.dart',
    path: '/events/1',
    primary: _filledButton,
  ),
  // profile
  const DuoScreen(
    id: '/profile',
    feature: 'profile',
    file: 'profile/screens/profile_view_screen.dart',
    path: '/profile',
  ),
  const DuoScreen(
    id: '/profile/edit',
    feature: 'profile',
    file: 'profile/screens/edit_profile_screen.dart',
    path: '/profile/edit',
  ),
  DuoScreen(
    id: '/profile/setup',
    feature: 'profile',
    file: 'profile/screens/profile_setup_screen.dart',
    path: '/profile/setup',
    primary: () => _action('Suivant'),
  ),
  DuoScreen(
    id: '/profile/verification',
    feature: 'verification',
    file: 'verification/screens/verification_screen.dart',
    path: '/profile/verification',
    primary: _filledButton,
  ),
  DuoScreen(
    id: '/verification/identity',
    feature: 'verification',
    file: 'verification/identity/identity_flow_screen.dart',
    path: '/verification/identity',
    primary: _filledButton,
  ),
  // settings
  const DuoScreen(
    id: '/profile/settings',
    feature: 'settings',
    file: 'settings/screens/settings_screen.dart',
    path: '/profile/settings',
  ),
  DuoScreen(
    id: '/profile/settings > with a campaign (christmas)',
    feature: 'settings',
    file: 'settings/screens/settings_screen.dart',
    path: '/profile/settings',
    providerOverrides: () => [
      storefrontProvider.overrideWithValue(storefrontWithCampaign('christmas')),
    ],
  ),
  const DuoScreen(
    id: '/profile/settings/shabbat',
    feature: 'settings',
    file: 'settings/screens/shabbat_mode_screen.dart',
    path: '/profile/settings/shabbat',
  ),
  const DuoScreen(
    id: '/duo-tutorial',
    feature: 'duo_tutorial',
    file: 'duo_tutorial/screens/duo_tutorial_screen.dart',
    path: '/duo-tutorial',
  ),
  const DuoScreen(
    id: '/profile/settings/religious-data',
    feature: 'privacy',
    file: 'privacy/screens/religious_data_settings_screen.dart',
    path: '/profile/settings/religious-data',
  ),
  const DuoScreen(
    id: '/profile/settings/analytics',
    feature: 'privacy',
    file: 'privacy/screens/analytics_settings_screen.dart',
    path: '/profile/settings/analytics',
  ),
  DuoScreen(
    id: '/profile/settings/computers',
    feature: 'web_sessions',
    file: 'web_sessions/screens/computers_screen.dart',
    path: '/profile/settings/computers',
    primary: () => _action('Connecter un ordinateur'),
  ),
  const DuoScreen(
    id: '/profile/settings/computers/scan',
    feature: 'web_sessions',
    file: 'web_sessions/screens/web_scan_screen.dart',
    path: '/profile/settings/computers/scan',
  ),
  // premium
  DuoScreen(
    id: '/premium',
    feature: 'premium',
    file: 'premium/screens/premium_screen.dart',
    path: '/premium',
    primary: _filledButton,
  ),
  // The mazl+ page with a campaign: a light accent and the ink of black Friday.
  for (final theme in ['valentine', 'black_friday'])
    DuoScreen(
      id: '/premium > with a campaign ($theme)',
      feature: 'premium',
      file: 'premium/screens/premium_screen.dart',
      path: '/premium',
      providerOverrides: () => [
        storefrontProvider.overrideWithValue(storefrontWithCampaign(theme)),
      ],
      primary: _buyButton,
    ),
  const DuoScreen(
    id: '/premium/welcome',
    feature: 'premium',
    file: 'premium/screens/plus_welcome_screen.dart',
    path: '/premium/welcome',
  ),
  DuoScreen(
    id: '/subscription',
    feature: 'premium',
    file: 'premium/screens/subscription_screen.dart',
    path: '/subscription',
    primary: () => _action('Découvrir mazl+'),
  ),
  // couple
  DuoScreen(
    id: '/couple/setup',
    feature: 'couple',
    file: 'couple/screens/couple_mode_setup_screen.dart',
    path: '/couple/setup',
    primary: () => _action('Envoyer la demande'),
  ),
  DuoScreen(
    id: '/couple/mazel-tov',
    feature: 'couple',
    file: 'couple/screens/mazel_tov_screen.dart',
    path: '/couple/mazel-tov',
    session: DuoSession.couple,
    extra: {'partnerName': 'Noémie'},
    primary: () => _action('Commencer notre aventure'),
  ),
  // The five tabs of the couple space and the pages opened over them.
  DuoScreen(
    id: '/couple/today',
    feature: 'couple',
    file: 'couple/screens/couple_today_screen.dart',
    path: '/couple/today',
    session: DuoSession.couple,
    primary: () => _action('Répondre'),
  ),
  DuoScreen(
    id: '/couple/agenda',
    feature: 'couple',
    file: 'couple/screens/couple_agenda_screen.dart',
    path: '/couple/agenda',
    session: DuoSession.couple,
    primary: () => _action('Ajouter un moment'),
  ),
  const DuoScreen(
    id: '/couple/outings',
    feature: 'couple',
    file: 'couple/screens/couple_outings_screen.dart',
    path: '/couple/outings',
    session: DuoSession.couple,
  ),
  DuoScreen(
    id: '/couple/concierge',
    feature: 'couple',
    file: 'couple/screens/couple_concierge_screen.dart',
    path: '/couple/concierge',
    session: DuoSession.couple,
    primary: () => _action('Réserver une table'),
  ),
  DuoScreen(
    id: '/couple/concierge/:requestId',
    feature: 'couple',
    file: 'couple/screens/couple_concierge_thread_screen.dart',
    path: '/couple/concierge/9002',
    session: DuoSession.couple,
    primary: () => find.byType(EditableText),
  ),
  const DuoScreen(
    id: '/couple/us',
    feature: 'couple',
    file: 'couple/screens/couple_us_screen.dart',
    path: '/couple/us',
    session: DuoSession.couple,
  ),
  const DuoScreen(
    id: '/couple/us/settings',
    feature: 'settings',
    file: 'settings/screens/settings_screen.dart',
    path: '/couple/us/settings',
    session: DuoSession.couple,
  ),
  const DuoScreen(
    id: '/couple/question',
    feature: 'couple',
    file: 'couple/screens/couple_question_screen.dart',
    path: '/couple/question',
    session: DuoSession.couple,
  ),
  const DuoScreen(
    id: '/couple/questions',
    feature: 'couple',
    file: 'couple/screens/couple_question_history_screen.dart',
    path: '/couple/questions',
    session: DuoSession.couple,
  ),
  const DuoScreen(
    id: '/couple/checkin',
    feature: 'couple',
    file: 'couple/screens/couple_checkin_screen.dart',
    path: '/couple/checkin',
    session: DuoSession.couple,
  ),
  const DuoScreen(
    id: '/couple/premium',
    feature: 'couple',
    file: 'couple/screens/couple_premium_screen.dart',
    path: '/couple/premium',
    session: DuoSession.couple,
  ),
  DuoScreen(
    id: '/couple/activities/saved',
    feature: 'couple',
    file: 'couple/screens/saved_activities_screen.dart',
    path: '/couple/activities/saved',
    session: DuoSession.couple,
    primary: () => _action('Découvrir des activités'),
  ),
  DuoScreen(
    id: '/couple/activities/:activityId',
    feature: 'couple',
    file: 'couple/screens/couple_activity_detail_screen.dart',
    path: '/couple/activities/1',
    session: DuoSession.couple,
    primary: () => _action('Réserver'),
  ),
  DuoScreen(
    id: '/couple/events/:eventId',
    feature: 'couple',
    file: 'couple/screens/couple_event_detail_screen.dart',
    path: '/couple/events/1',
    session: DuoSession.couple,
    primary: () => _action("S'inscrire"),
  ),
];
