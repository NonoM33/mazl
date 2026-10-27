/// Route names for the application
abstract class RouteNames {
  // Auth routes
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const reviewLogin = 'reviewLogin';
  static const duoTutorial = 'duoTutorial';

  // Main navigation routes
  static const discover = 'discover';
  static const matches = 'matches';
  static const chat = 'chat';
  static const chatDetail = 'chatDetail';
  static const events = 'events';
  static const eventDetail = 'eventDetail';
  static const profile = 'profile';

  // Profile sub-routes
  static const editProfile = 'editProfile';
  static const profileSetup = 'profileSetup';
  static const settings = 'settings';
  static const verification = 'verification';
  static const verificationIdentity = 'verificationIdentity';
  static const shabbatMode = 'shabbatMode';
  static const computers = 'computers';
  static const webScan = 'webScan';
  static const religiousData = 'religiousData';
  static const analyticsSettings = 'analyticsSettings';

  // Couple mode
  static const coupleSetup = 'coupleSetup';
  static const coupleToday = 'coupleToday';
  static const coupleAgenda = 'coupleAgenda';
  static const coupleOutings = 'coupleOutings';
  static const coupleConcierge = 'coupleConcierge';
  static const coupleConciergeRequest = 'coupleConciergeRequest';
  static const coupleUs = 'coupleUs';
  static const coupleUsSettings = 'coupleUsSettings';
  static const coupleQuestion = 'coupleQuestion';
  static const coupleQuestions = 'coupleQuestions';
  static const coupleCheckin = 'coupleCheckin';
  static const couplePremium = 'couplePremium';
  static const coupleActivityDetail = 'coupleActivityDetail';
  static const coupleSavedActivities = 'coupleSavedActivities';
  static const coupleEventDetail = 'coupleEventDetail';
  static const mazelTov = 'mazelTov';

  // Other
  static const profileView = 'profileView';
  static const matchProfile = 'matchProfile';
  static const premium = 'premium';
  static const plusWelcome = 'plusWelcome';
  static const subscription = 'subscription';
  static const likes = 'likes';
  static const boost = 'boost';
  static const filters = 'filters';
  static const dailyPicks = 'dailyPicks';
  static const passport = 'passport';
}

/// Route paths for the application
abstract class RoutePaths {
  // Auth routes
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  /// Identifier + password sign-in of the App Store review account.
  static const reviewLogin = '/login/review';

  /// Le tutoriel de l'iPhone Duo (la route elle-même est dans duo_tutorial_policy.dart).
  static const duoTutorial = '/duo-tutorial';

  // Main navigation routes
  static const discover = '/discover';
  static const matches = '/matches';
  static const chat = '/chat';
  static const chatDetail = '/chat/:conversationId';
  static const events = '/events';
  static const eventDetail = '/events/:eventId';
  static const profile = '/profile';

  // Profile sub-routes
  static const editProfile = '/profile/edit';
  static const profileSetup = '/profile/setup';
  static const settings = '/profile/settings';
  static const verification = '/profile/verification';
  static const verificationIdentity = '/verification/identity';
  static const shabbatMode = '/profile/settings/shabbat';
  static const computers = '/profile/settings/computers';
  static const webScan = '/profile/settings/computers/scan';
  static const religiousData = '/profile/settings/religious-data';
  static const analyticsSettings = '/profile/settings/analytics';

  // Couple mode: the five tabs of the couple space (docs/couple/ESPACE-COUPLE.md §0.3)
  static const coupleSetup = '/couple/setup';
  static const coupleToday = '/couple/today';
  static const coupleAgenda = '/couple/agenda';
  static const coupleOutings = '/couple/outings';
  static const coupleConcierge = '/couple/concierge';
  static const coupleUs = '/couple/us';

  /// A concierge request and its conversation.
  static const coupleConciergeRequest = '/couple/concierge/:requestId';
  static const coupleUsSettings = '/couple/us/settings';

  /// The question of the day, its history, the monthly check-in.
  static const coupleQuestion = '/couple/question';
  static const coupleQuestions = '/couple/questions';
  static const coupleCheckin = '/couple/checkin';

  /// MAZL Couple, the subscription of the couple.
  static const couplePremium = '/couple/premium';

  /// The outings opened from the Outings tab.
  static const coupleSavedActivities = '/couple/activities/saved';
  static const coupleActivityDetail = '/couple/activities/:activityId';
  static const coupleEventDetail = '/couple/events/:eventId';
  static const mazelTov = '/couple/mazel-tov';

  /// The places of the couple space before the five tabs. They redirect to
  /// where their content lives now (see `legacyCoupleRedirects`).
  static const legacyCoupleActivities = '/couple/activities';
  static const legacyCoupleCalendar = '/couple/calendar';
  static const legacyCoupleEvents = '/couple/events';
  static const legacyCoupleSpace = '/couple/space';
  static const legacyCoupleSpaceSettings = '/couple/space/settings';

  static String conciergeRequestPath(int requestId) =>
      '/couple/concierge/$requestId';

  /// Helper to get couple activity detail path
  static String coupleActivityPath(int activityId) =>
      '/couple/activities/$activityId';

  /// Helper to get couple event detail path
  static String coupleEventPath(int eventId) => '/couple/events/$eventId';

  // Other
  static const profileView = '/discover/profile/:userId';
  static const matchProfile = '/matches/profile/:userId';
  static const premium = '/premium';
  static const plusWelcome = '/premium/welcome';
  static const subscription = '/subscription';
  static const likes = '/likes';
  static const boost = '/boost';
  static const filters = '/filters';
  static const dailyPicks = '/daily-picks';
  static const passport = '/passport';

  /// Helper to get match profile path
  static String matchProfilePath(String userId) => '/matches/profile/$userId';

  /// Helper to get profile view path
  static String profileViewPath(String userId) => '/discover/profile/$userId';
}
