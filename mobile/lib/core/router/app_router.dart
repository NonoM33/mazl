import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers/storefront_providers.dart';
import 'app_guard.dart';
import 'detail_screens.dart';
import '../layout/adaptive_detail.dart';
import 'root_navigator.dart';
import 'route_names.dart';
import 'route_transitions.dart';
import '../di/providers/service_providers.dart';
import '../../presentation/features/splash/splash_screen.dart';
import '../../presentation/features/duo_tutorial/screens/duo_tutorial_screen.dart';
import '../duo_tutorial/duo_tutorial_policy.dart';
import '../../presentation/features/onboarding/screens/onboarding_screen.dart';
import '../../presentation/features/auth/screens/login_screen.dart';
import '../../presentation/features/auth/screens/review_login_screen.dart';
import '../../presentation/features/auth/screens/route_error_screen.dart';
import '../../presentation/features/navigation/screens/main_navigation_screen.dart';
import '../../presentation/features/matching/screens/discover_screen.dart';
import '../../presentation/features/matching/screens/matches_screen.dart';
import '../../presentation/features/chat/screens/conversations_screen.dart';
import '../motion/mazl_motion.dart';
import '../../presentation/features/events/screens/events_list_screen.dart';
import '../../presentation/features/events/screens/event_detail_screen.dart';
import '../../presentation/features/profile/screens/profile_view_screen.dart';
import '../../presentation/features/profile/screens/edit_profile_screen.dart';
import '../../presentation/features/profile/screens/profile_setup_screen.dart';
import '../../presentation/features/settings/screens/settings_screen.dart';
import '../../presentation/features/settings/screens/shabbat_mode_screen.dart';
import '../../presentation/features/privacy/screens/analytics_settings_screen.dart';
import '../../presentation/features/privacy/screens/religious_data_settings_screen.dart';
import '../../presentation/features/web_sessions/screens/computers_screen.dart';
import '../../presentation/features/web_sessions/screens/web_scan_screen.dart';
import '../../presentation/features/verification/screens/verification_screen.dart';
import '../../presentation/features/premium/screens/plus_welcome_screen.dart';
import '../../presentation/features/verification/identity/identity_flow_screen.dart';
import '../../presentation/features/premium/screens/premium_screen.dart';
import '../../presentation/features/premium/screens/subscription_screen.dart';
import '../../presentation/features/couple/screens/couple_mode_setup_screen.dart';
import '../../presentation/features/couple/screens/mazel_tov_screen.dart';
import '../../presentation/features/couple/screens/couple_agenda_screen.dart';
import '../../presentation/features/couple/screens/couple_checkin_screen.dart';
import '../../presentation/features/couple/screens/couple_concierge_screen.dart';
import '../../presentation/features/couple/screens/couple_concierge_thread_screen.dart';
import '../../presentation/features/couple/screens/couple_outings_screen.dart';
import '../../presentation/features/couple/screens/couple_premium_screen.dart';
import '../../presentation/features/couple/screens/couple_question_history_screen.dart';
import '../../presentation/features/couple/screens/couple_question_screen.dart';
import '../../presentation/features/couple/screens/couple_today_screen.dart';
import '../../presentation/features/couple/screens/couple_activity_detail_screen.dart';
import '../../presentation/features/couple/screens/couple_event_detail_screen.dart';
import '../../presentation/features/couple/screens/couple_us_screen.dart';
import '../../presentation/features/couple/screens/saved_activities_screen.dart';
import '../../presentation/features/likes/screens/likes_screen.dart';
import '../../presentation/features/boost/screens/boost_screen.dart';
import '../../presentation/features/matching/screens/filters_screen.dart';
import '../../presentation/features/matching/screens/daily_picks_screen.dart';
import '../../presentation/features/navigation/screens/couple_navigation_screen.dart';

export 'root_navigator.dart' show rootNavigatorKey;

/// Short name for the routes below.
final GlobalKey<NavigatorState> _rootNavigatorKey = rootNavigatorKey;

/// Shell navigator keys for each tab
final GlobalKey<NavigatorState> _shellNavigatorKeyDiscover =
    GlobalKey<NavigatorState>(debugLabel: 'shellDiscover');
final GlobalKey<NavigatorState> _shellNavigatorKeyMatches =
    GlobalKey<NavigatorState>(debugLabel: 'shellMatches');
final GlobalKey<NavigatorState> _shellNavigatorKeyChat =
    GlobalKey<NavigatorState>(debugLabel: 'shellChat');
final GlobalKey<NavigatorState> _shellNavigatorKeyEvents =
    GlobalKey<NavigatorState>(debugLabel: 'shellEvents');
final GlobalKey<NavigatorState> _shellNavigatorKeyProfile =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

/// Shell navigator keys for the five tabs of the couple space
final GlobalKey<NavigatorState> _shellNavigatorKeyCoupleToday =
    GlobalKey<NavigatorState>(debugLabel: 'shellCoupleToday');
final GlobalKey<NavigatorState> _shellNavigatorKeyCoupleAgenda =
    GlobalKey<NavigatorState>(debugLabel: 'shellCoupleAgenda');
final GlobalKey<NavigatorState> _shellNavigatorKeyCoupleOutings =
    GlobalKey<NavigatorState>(debugLabel: 'shellCoupleOutings');
final GlobalKey<NavigatorState> _shellNavigatorKeyCoupleConcierge =
    GlobalKey<NavigatorState>(debugLabel: 'shellCoupleConcierge');
final GlobalKey<NavigatorState> _shellNavigatorKeyCoupleUs =
    GlobalKey<NavigatorState>(debugLabel: 'shellCoupleUs');

/// Provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  // The AuthService singleton is a ChangeNotifier: use it as the router's
  // refreshListenable so the redirect/guard is re-evaluated whenever the
  // authentication state changes (login / logout / init / user refresh).
  final authService = ref.watch(authServiceProvider.notifier);
  // Same for the couple state: the guard below re-runs when a couple forms or ends.
  final coupleService = ref.watch(coupleServiceProvider.notifier);
  // And for the profile completeness: the guard re-runs when the backend says
  // gender / looking-for are missing, or once the setup has given them.
  final profileCompleteness = ref.watch(profileCompletenessProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([
      authService,
      coupleService,
      profileCompleteness,
    ]),
    redirect: (context, state) => appRedirect(
      location: state.matchedLocation,
      isAuthenticated: ref.read(isAuthenticatedProvider),
      sessionEnded: authService.sessionEndReason != null,
      profileIncomplete: profileCompleteness.needsSetup,
      inCouple: coupleService.isCoupleModeEnabled,
    ),
    routes: [
      // Splash Screen
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // iPhone Duo tutorial: full screen on the root navigator, once at the
      // first launch on a foldable iPhone (`next` is where to go after it) and
      // again from the settings (no `next`: back to the settings).
      GoRoute(
        path: RoutePaths.duoTutorial,
        name: RouteNames.duoTutorial,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final next = safeDuoTutorialNext(state.uri.queryParameters['next']);
          return CustomTransitionPage(
            key: state.pageKey,
            child: DuoTutorialScreen(next: next),
            transitionsBuilder: fadeTransition,
          );
        },
      ),

      // Onboarding
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      // Login
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Identifier + password sign-in of the App Store review account: open
      // to a visitor who is not signed in, pushed over the login.
      GoRoute(
        path: RoutePaths.reviewLogin,
        name: RouteNames.reviewLogin,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ReviewLoginScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),

      // Profile Setup (after first login)
      GoRoute(
        path: RoutePaths.profileSetup,
        name: RouteNames.profileSetup,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      // Premium Screen
      GoRoute(
        path: RoutePaths.premium,
        name: RouteNames.premium,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: Consumer(
            builder: (context, ref, _) =>
                PremiumScreen(storefront: ref.watch(storefrontProvider)),
          ),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // mazl+ : bienvenue après l'achat
      GoRoute(
        path: RoutePaths.plusWelcome,
        name: RouteNames.plusWelcome,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlusWelcomeScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      // mazl+ : gestion de l'abonnement
      GoRoute(
        path: RoutePaths.subscription,
        name: RouteNames.subscription,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SubscriptionScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),

      // Level 2 verification (identity from the NFC chip)
      GoRoute(
        path: RoutePaths.verificationIdentity,
        name: RouteNames.verificationIdentity,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IdentityFlowScreen(),
      ),

      // Likes Screen
      GoRoute(
        path: RoutePaths.likes,
        name: RouteNames.likes,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LikesScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Boost Screen
      GoRoute(
        path: RoutePaths.boost,
        name: RouteNames.boost,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BoostScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Filters Screen
      GoRoute(
        path: RoutePaths.filters,
        name: RouteNames.filters,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FiltersScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Daily Picks Screen
      GoRoute(
        path: RoutePaths.dailyPicks,
        name: RouteNames.dailyPicks,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DailyPicksScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Couple Mode Routes (standalone - no navigation)
      GoRoute(
        path: RoutePaths.coupleSetup,
        name: RouteNames.coupleSetup,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoupleModeSetupScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.mazelTov,
        name: RouteNames.mazelTov,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MazelTovScreen(
              partnerName: extra?['partnerName'] ?? '',
              partnerPicture: extra?['partnerPicture'],
              myPicture: extra?['myPicture'],
            ),
            transitionsBuilder: fadeTransition,
          );
        },
      ),

      // Pages of the couple space opened over its tabs.
      GoRoute(
        path: RoutePaths.coupleQuestion,
        name: RouteNames.coupleQuestion,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoupleQuestionScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.coupleQuestions,
        name: RouteNames.coupleQuestions,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoupleQuestionHistoryScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.coupleCheckin,
        name: RouteNames.coupleCheckin,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoupleCheckinScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.couplePremium,
        name: RouteNames.couplePremium,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CouplePremiumScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.coupleSavedActivities,
        name: RouteNames.coupleSavedActivities,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SavedActivitiesScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.coupleActivityDetail,
        name: RouteNames.coupleActivityDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final activityId = state.pathParameters['activityId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CoupleActivityDetailScreen(activityId: activityId),
            transitionsBuilder: slideUpTransition,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.coupleEventDetail,
        name: RouteNames.coupleEventDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CoupleEventDetailScreen(eventId: eventId),
            transitionsBuilder: slideUpTransition,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.coupleUsSettings,
        name: RouteNames.coupleUsSettings,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: RoutePaths.coupleConciergeRequest,
        name: RouteNames.coupleConciergeRequest,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final requestId = int.tryParse(state.pathParameters['requestId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConciergeThreadScreen(requestId: requestId ?? 0),
            transitionsBuilder: slideLeftTransition,
          );
        },
      ),

      // The couple space: five tabs (today, agenda, outings, concierge, us).
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return CoupleNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCoupleToday,
            routes: [
              GoRoute(
                path: RoutePaths.coupleToday,
                name: RouteNames.coupleToday,
                builder: (context, state) => const CoupleTodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCoupleAgenda,
            routes: [
              GoRoute(
                path: RoutePaths.coupleAgenda,
                name: RouteNames.coupleAgenda,
                builder: (context, state) => const CoupleAgendaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCoupleOutings,
            routes: [
              GoRoute(
                path: RoutePaths.coupleOutings,
                name: RouteNames.coupleOutings,
                builder: (context, state) => const CoupleOutingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCoupleConcierge,
            routes: [
              GoRoute(
                path: RoutePaths.coupleConcierge,
                name: RouteNames.coupleConcierge,
                builder: (context, state) => const CoupleConciergeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCoupleUs,
            routes: [
              GoRoute(
                path: RoutePaths.coupleUs,
                name: RouteNames.coupleUs,
                builder: (context, state) => const CoupleUsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Main Navigation Shell with Bottom Navigation
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(
            navigationShell: navigationShell,
            buildDetail: detailScreenFor,
          );
        },
        branches: [
          // Discover Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDiscover,
            routes: [
              GoRoute(
                path: RoutePaths.discover,
                name: RouteNames.discover,
                builder: (context, state) => const DiscoverScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/:userId',
                    name: RouteNames.profileView,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final userId = state.pathParameters['userId']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ProfileViewScreen(userId: userId),
                        transitionsBuilder: heroTransition,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Matches Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyMatches,
            routes: [
              GoRoute(
                path: RoutePaths.matches,
                name: RouteNames.matches,
                builder: (context, state) => const MatchesScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/:userId',
                    name: RouteNames.matchProfile,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final target = MatchProfileDetail(
                        state.pathParameters['userId']!,
                      );
                      return AdaptiveDetailPage(
                        key: state.pageKey,
                        target: target,
                        child: detailScreenFor(context, target),
                        transitionsBuilder: heroMotion,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Chat Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyChat,
            routes: [
              GoRoute(
                path: RoutePaths.chat,
                name: RouteNames.chat,
                builder: (context, state) => const ConversationsScreen(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    name: RouteNames.chatDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final target = ChatDetail(
                        state.pathParameters['conversationId']!,
                      );
                      return AdaptiveDetailPage(
                        key: state.pageKey,
                        target: target,
                        child: detailScreenFor(context, target),
                        transitionsBuilder: slideLeftMotion,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Events Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyEvents,
            routes: [
              GoRoute(
                path: RoutePaths.events,
                name: RouteNames.events,
                builder: (context, state) => const EventsListScreen(),
                routes: [
                  GoRoute(
                    path: ':eventId',
                    name: RouteNames.eventDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final eventId = state.pathParameters['eventId']!;
                      final reduced = MazlMotion.reduced(context);
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: EventDetailScreen(eventId: eventId),
                        transitionDuration: reduced
                            ? MazlMotion.reducedFade
                            : MazlMotion.eventOpen,
                        reverseTransitionDuration: reduced
                            ? MazlMotion.reducedFade
                            : MazlMotion.eventClose,
                        transitionsBuilder: eventDetailTransition,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Profile Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyProfile,
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) =>
                    const ProfileViewScreen(isOwnProfile: true),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editProfile,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const EditProfileScreen(),
                      transitionsBuilder: slideLeftTransition,
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.settings,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const SettingsScreen(),
                      transitionsBuilder: slideLeftTransition,
                    ),
                    routes: [
                      GoRoute(
                        path: 'shabbat',
                        name: RouteNames.shabbatMode,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ShabbatModeScreen(),
                      ),
                      GoRoute(
                        path: 'religious-data',
                        name: RouteNames.religiousData,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const ReligiousDataSettingsScreen(),
                      ),
                      GoRoute(
                        path: 'analytics',
                        name: RouteNames.analyticsSettings,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const AnalyticsSettingsScreen(),
                      ),
                      GoRoute(
                        path: 'computers',
                        name: RouteNames.computers,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ComputersScreen(),
                        routes: [
                          GoRoute(
                            path: 'scan',
                            name: RouteNames.webScan,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: (context, state) => const WebScanScreen(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'verification',
                    name: RouteNames.verification,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const VerificationScreen(),
                      transitionsBuilder: slideUpTransition,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const RouteErrorScreen(),
  );
});
