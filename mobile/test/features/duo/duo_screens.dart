import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who is signed in when a screen is opened.
enum DuoSession {
  /// Nobody: the public routes (onboarding, login).
  signedOut,

  /// A member of the demo session, dating mode (the tabs Discover to Profile).
  dating,

  /// A member of the demo session who formed a couple (couple mode).
  couple,
}

/// One screen of the app, opened by its route through the real router.
class DuoScreen {
  const DuoScreen({
    required this.id,
    required this.feature,
    required this.file,
    required this.path,
    this.session = DuoSession.dating,
    this.extra,
    this.primary,
    this.open,
    this.providerOverrides,
    this.settleMillis = 3000,
  });

  /// The name in the known failures and in the report: the route as declared
  /// in the router (`/chat/:conversationId`), plus what was done to reach the
  /// screen when it is not a plain visit.
  final String id;

  /// `lib/presentation/features/<feature>`.
  final String feature;

  /// The screen's file, from `lib/presentation/features/<feature>/screens`.
  final String file;

  /// The location opened, with valid ids of the demo data.
  final String path;
  final DuoSession session;

  /// `GoRouter.extra` of the route.
  final Object? extra;

  /// The main action of the screen, when there is an obvious one (the full
  /// button, the field of a conversation). It must be entirely in view
  /// without scrolling.
  final Finder Function()? primary;

  /// What the member does on the opened screen before it is measured.
  final Future<void> Function(WidgetTester tester)? open;

  /// Providers replaced for this screen only (a campaign running, for
  /// example), on top of the ones every screen of the crawl gets.
  final List<Override> Function()? providerOverrides;

  /// How long the screen gets, in virtual time, to load before it is measured.
  final int settleMillis;
}
