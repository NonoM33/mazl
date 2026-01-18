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

  // Couple mode
  static const coupleSetup = 'coupleSetup';
  static const coupleActivities = 'coupleActivities';
  static const coupleActivityDetail = 'coupleActivityDetail';
  static const coupleSavedActivities = 'coupleSavedActivities';
  static const coupleCalendar = 'coupleCalendar';
  static const coupleEvents = 'coupleEvents';
  static const coupleEventDetail = 'coupleEventDetail';
  static const coupleSpace = 'coupleSpace';
  static const coupleSettings = 'coupleSettings';
  static const jewishCalendar = 'jewishCalendar';
  static const mazelTov = 'mazelTov';

  // Other
  static const profileView = 'profileView';
  static const matchProfile = 'matchProfile';
  static const premium = 'premium';
  static const likes = 'likes';
  static const boost = 'boost';
  static const visitors = 'visitors';
  static const successStories = 'successStories';
  static const filters = 'filters';
  static const dailyPicks = 'dailyPicks';
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

  // Couple mode
  static const coupleSetup = '/couple/setup';
  static const coupleActivities = '/couple/activities';
  static const coupleSavedActivities = '/couple/activities/saved';
  static const coupleCalendar = '/couple/calendar';
  static const coupleEvents = '/couple/events';
  static const coupleSpace = '/couple/space';
  static const jewishCalendar = '/couple/calendar';
  static const mazelTov = '/couple/mazel-tov';

  /// Helper to get couple activity detail path
  static String coupleActivityPath(int activityId) => '/couple/activities/$activityId';

  /// Helper to get couple event detail path
  static String coupleEventPath(int eventId) => '/couple/events/$eventId';

  // Other
  static const profileView = '/discover/profile/:userId';
  static const matchProfile = '/matches/profile/:userId';
  static const premium = '/premium';
  static const likes = '/likes';
  static const boost = '/boost';
  static const visitors = '/visitors';
  static const successStories = '/success-stories';
  static const filters = '/filters';
  static const dailyPicks = '/daily-picks';

  /// Helper to get match profile path
  static String matchProfilePath(String userId) => '/matches/profile/$userId';

  /// Helper to get profile view path
  static String profileViewPath(String userId) => '/discover/profile/$userId';
}
