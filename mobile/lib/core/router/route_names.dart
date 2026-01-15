/// Route names for the application
abstract class RouteNames {
  // Auth routes
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';

  // Main navigation routes
  static const discover = 'discover';
  static const matches = 'matches';
  static const chat = 'chat';
  static const chatDetail = 'chatDetail';
  static const videoCall = 'videoCall';
  static const events = 'events';
  static const eventDetail = 'eventDetail';
  static const profile = 'profile';

  // Profile sub-routes
  static const editProfile = 'editProfile';
  static const profileSetup = 'profileSetup';
  static const settings = 'settings';
  static const aiShadchan = 'aiShadchan';
  static const verification = 'verification';
  static const shabbatMode = 'shabbatMode';

  // Other
  static const profileView = 'profileView';
}

/// Route paths for the application
abstract class RoutePaths {
  // Auth routes
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  // Main navigation routes
  static const discover = '/discover';
  static const matches = '/matches';
  static const chat = '/chat';
  static const chatDetail = '/chat/:conversationId';
  static const videoCall = '/chat/:conversationId/video-call';
  static const events = '/events';
  static const eventDetail = '/events/:eventId';
  static const profile = '/profile';

  // Profile sub-routes
  static const editProfile = '/profile/edit';
  static const profileSetup = '/profile/setup';
  static const settings = '/profile/settings';
  static const aiShadchan = '/profile/ai-shadchan';
  static const verification = '/profile/verification';
  static const shabbatMode = '/profile/settings/shabbat';

  // Other
  static const profileView = '/discover/profile/:userId';
}
